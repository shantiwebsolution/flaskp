from flask import Flask, render_template, request, redirect, url_for, flash
import requests
import os

app = Flask(__name__)
app.secret_key = 'your-secret-key-here'  

# Backend API URL - adjust if backend runs on different host/port
BACKEND_URL = os.getenv('BACKEND_URL', 'http://localhost:5000')

@app.route('/')
def index():
    """Display the form to input values a and b"""
    return render_template('index.html')

@app.route('/calculate', methods=['POST'])
def calculate():
    """Handle form submission and call backend API"""
    try:
        # Get form data
        a = request.form.get('a')
        b = request.form.get('b')
        
        # Validate input
        if not a or not b:
            flash('Both values a and b are required!', 'error')
            return redirect(url_for('index'))
        
        # Prepare data for backend API
        form_data = {
            'a': a,
            'b': b
        }
        
        # Call backend API
        response = requests.post(f'{BACKEND_URL}/sum', data=form_data)
        
        if response.status_code == 200:
            result_data = response.json()
            return render_template('result.html', result=result_data)
        else:
            error_data = response.json()
            flash(f"Error: {error_data.get('error', 'Unknown error occurred')}", 'error')
            return redirect(url_for('index'))
            
    except requests.exceptions.ConnectionError:
        flash('Error: Backend server is notrunning.', 'error')
        return redirect(url_for('index'))
    except Exception as e:
        flash(f'An unexpected error occurred: {str(e)}', 'error')
        return redirect(url_for('index'))

@app.route('/health')
def health_check():
    """Health check endpoint"""
    return {'status': 'healthy', 'service': 'Flask Frontend'}

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=3000)
