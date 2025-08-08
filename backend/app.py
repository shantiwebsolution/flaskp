import logging
from flask import Flask, request, jsonify

app = Flask(__name__)

@app.route('/')
def hello():
    return {'message': 'Hello, Flask!', 'status': 'success'}

@app.route('/be/')
def hello_be():
    return {'message': 'Hello, Flask from /be!', 'status': 'success'}

@app.route('/health')
def health_check():
    return {'status': 'healthy', 'service': 'Flask Backend'}

@app.route('/be/health')
def health_check_be():
    return {'status': 'healthy', 'service': 'Flask Backend /be'}

@app.route('/sum', methods=['POST'])
@app.route('/be/sum', methods=['POST'])
def calculate_sum():
    try:
        # Get 'a' and 'b' from form data
        data = request.get_json()  # requires Content-Type: application/json
        a = data.get("a") if data else None
        b = data.get("b") if data else None
        print(f"Received values: a={a}, b={b}")
        # Validate that both values are provided
        if a is None or b is None:
            return jsonify({
                'error': 'Both parameters a and b are required..',
                'status': 'error'
            }), 400
        
        # Convert to numbers and calculate sum
        try:
            num_a = float(a)
            num_b = float(b)
            result = num_a + num_b
            
            return jsonify({
                'a': num_a,
                'b': num_b,
                'sum': result,
                'status': 'success'
            })
        except ValueError:
            return jsonify({
                'error': 'Both a and b must be valid numbers',
                'status': 'error'
            }), 400
            
    except Exception as e:
        return jsonify({
            'error': f'An error occurred: {str(e)}',
            'status': 'error'
        }), 500

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=5000)
