from flask import Flask, request
import os
import logging
from pythonjsonlogger import jsonlogger
from prometheus_flask_exporter import PrometheusMetrics

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
    logger.info(
        "Request processed",
        extra={
            "method": request.method,           # HTTP Method (GET, POST)
            "path": request.path,               # The URL path (e.g., / or /error)
            "status": response.status_code,     # The HTTP Status (200, 404, 500)
            "hostname": os.uname()[1],          # The Pod Name (Identity of the container)
            "ip": request.remote_addr           # The IP address of the caller
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
    app.run(debug=True, host='0.0.0.0', port=int(os.environ.get('PORT', 8080)))
