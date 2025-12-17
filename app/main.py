from doctest import debug
from flask import Flask
import os

app = Flask(__name__)

@app.route('/')
def hello_word():
    hostname = os.uname()[1]
    return f'Hello, World! I am running on host: {hostname}\n'


if __name__ == "__main__":
    app.run(debug=True, host='0.0.0.0', port = int(os.environ.get('PORT', 8080)))