from flask import Flask, request

app = Flask(__name__)

@app.route('/', defaults={'path': ''}, methods=['GET', 'POST', 'PUT', 'DELETE'])
@app.route('/<path:path>', methods=['GET', 'POST', 'PUT', 'DELETE'])
def catch_all(path):
    print(f"Received request: {request.method} {request.path}")
    print(f"Request headers: {request.headers}")
    print(f"Request body: {request.data.decode('utf-8')}")
    return "hello, im python"

if __name__ == '__main__':
    app.run(host='localhost', port=5000)
