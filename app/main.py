from flask import Flask, request
import os
import logging
from pythonjsonlogger import jsonlogger
from prometheus_flask_exporter import PrometheusMetrics
from opentelemetry import trace
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor
from opentelemetry.exporter.otlp.proto.grpc.trace_exporter import OTLPSpanExporter
from opentelemetry.instrumentation.flask import FlaskInstrumentor
from opentelemetry.sdk.resources import Resource


'''
==========================================
OpenTelemetry Configuration
==========================================
1. Resource: We define the identity of this service.
   Tempo will show this name ("python-app") in the UI.
'''
resource = Resource(attributes={
    "service.name": "python-app",
    "service.version": "1.0.0"
})

'''
2. Tracer Provider:
   This is the engine that generates traces. We initialize it with our Resource identity.
'''
trace.set_tracer_provider(TracerProvider(resource=resource))

'''
3. OTLP Exporter:
   This defines WHERE to send the traces.
   We use an environment variable 'OTEL_EXPORTER_OTLP_ENDPOINT' so we can configure it in Kubernetes.
   Default is 'http://tempo:4317' (The K8s Service address).
   insecure=True is used because we are inside the cluster (no SSL/TLS needed).
'''
otlp_endpoint = os.environ.get("OTEL_EXPORTER_OTLP_ENDPOINT", "http://tempo:4317")
otlp_exporter = OTLPSpanExporter(endpoint=otlp_endpoint, insecure=True)

'''
4. Span Processor:
   We use a 'BatchSpanProcessor'.
   Instead of sending a network request for every single span (slow),
   it collects them in memory and sends them in batches (fast).
'''
span_processor = BatchSpanProcessor(otlp_exporter)
trace.get_tracer_provider().add_span_processor(span_processor)



'''
# ==========================================
# 1. Flask Initialization
# ==========================================
# Flask is a lightweight web framework for Python.
# It acts as the "Server" that listens for HTTP requests (GET, POST)
# and routes them to specific Python functions.
#
# 'app' is the central object that represents our web application.
'''
app = Flask(__name__)


'''
==========================================
Auto-Instrumentation
==========================================
This magic line wraps our Flask application.
It automatically intercepts every incoming HTTP request and creates a Span.
It records:
- HTTP Method (GET/POST)
- Status Code (200/500)
- URL Path
- Duration (Latency)
'''
FlaskInstrumentor().instrument_app(app)

'''
==========================================
2. Structured Logging Setup (The "Eyes")
==========================================
Problem: Standard logs are just text strings.
         "2023-01-01 INFO: Something happened"
         Machines cannot easily query "Show me all logs where status=500".

Solution: We use JSON logging.
          {"time": "2023-01-01", "level": "INFO", "msg": "Something happened"}
          This allows Google Cloud Logging to index every field.
'''
logHandler = logging.StreamHandler() # Output logs to Standard Output (Console), which K8s captures.
formatter = jsonlogger.JsonFormatter('%(asctime)s %(levelname)s %(message)s')
logHandler.setFormatter(formatter)

logger = logging.getLogger()
logger.addHandler(logHandler)
logger.setLevel(logging.INFO)

'''
==========================================
3. Prometheus Metrics Setup (The "Vitals")
==========================================
We initialize the PrometheusMetrics extension.
This library "instruments" our Flask app by wrapping it.

It automatically does two things:
1. Creates a '/metrics' route that Prometheus scrapes.
2. Measures:
   - How many requests we get (Counter).
   - How long each request takes (Histogram).
'''
metrics = PrometheusMetrics(app)

'''
Static Info Metric:
-------------------
We manually create a metric to hold "Metadata" about the running app.

Code:
    metrics.info('app_info', 'Application info', version='1.0.0')

Prometheus Output:
    # HELP flask_app_info Application info
    # TYPE flask_app_info gauge
    flask_app_info{version="1.0.0"} 1.0

Why?
    This allows us to group other metrics by version.
    Query: "Show me error rate WHERE version='1.0.0'"
'''
metrics.info('app_info', 'Application info', version='1.0.0')

'''
==========================================
4. Middleware (Automatic Logging)
==========================================
Instead of manually adding `logger.info()` inside every single route,
we use a "Hook" (Decorator) that runs automatically for every request.
'''

@app.after_request
def log_request(response):
    '''
    This function runs AFTER the route handler returns, but BEFORE the response is sent.
    It allows us to capture the *final* Status Code.
    
    Args:
        response: The final response object created by the route function.
    '''
    # Skip logging for the metrics endpoint to reduce noise (we don't need to log every scrape)
    if request.path == '/metrics':
        return response

    # We log the event with extra "Metadata" fields.
    # These become top-level keys in the JSON log.
    '''
    Trace Correlation:
    We get the current Trace ID from OpenTelemetry.
    If a trace is active, we get a 32-character hex string.
    If not, trace_id is 0.
    '''
    current_span = trace.get_current_span()
    trace_id = current_span.get_span_context().trace_id
    # Convert trace_id to hex string, or None if invalid (0)
    trace_id_hex = format(trace_id, '032x') if trace_id != 0 else None

    logger.info(
        "Request processed",
        extra={
            "method": request.method,
            "path": request.path,
            "status": response.status_code,
            "hostname": os.uname()[1],
            "ip": request.remote_addr,
            "trace_id": trace_id_hex  # Add Trace ID to logs!
        }
    )
    return response

'''
==========================================
5. Routes (Endpoints)
==========================================
A "Route" maps a URL (like /error) to a Python function.
When a user hits the URL, Flask runs the function and returns the result.
'''

@app.route('/')
def hello_world():
    '''
    Path: /
    Method: GET
    Purpose: Health check and basic identification.
    '''
    hostname = os.uname()[1]
    return f'Hello, World! I am running on host: {hostname}\n'

@app.route('/error')
def trigger_error():
    '''
    Path: /error
    Method: GET
    Purpose: Simulates a crash or failure.
    
    We return a 500 Status Code intentionally.
    This helps us verify that our Monitoring System (Prometheus + Alertmanager)
    is correctly detecting failures.
    '''
    # We can still add specific ERROR logs if we need more context than the automatic logger provides
    logger.error("Specific error logic triggered", extra={"custom_field": "something_bad"})
    return "This is a test error", 500

if __name__ == "__main__":
    # app.run starts the internal Flask web server.
    # We listen on 0.0.0.0 to accept connections from outside the container.
    # CRITICAL: debug=False for production! debug=True breaks Prometheus metrics.
    app.run(debug=False, host='0.0.0.0', port=int(os.environ.get('PORT', 8080)))