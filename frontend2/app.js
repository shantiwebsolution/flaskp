const express = require('express');
const bodyParser = require('body-parser');
const path = require('path');
const axios = require('axios'); // For making HTTP requests

const app = express();
const PORT = process.env.PORT || 3000;
const BACKEND_URL = process.env.BACKEND_URL || 'http://localhost:5000';

// Set EJS as the templating engine
app.set('view engine', 'ejs');
app.set('views', path.join(__dirname, 'views'));

// Middleware to parse form data
app.use(bodyParser.urlencoded({ extended: true }));
app.use(bodyParser.json());

// Middleware for flash messages (simple implementation)
app.use((req, res, next) => {
    res.locals.messages = req.session && req.session.messages ? req.session.messages : [];
    if (req.session) {
        req.session.messages = []; // Clear messages after displaying
    }
    next();
});

// Basic session setup for flash messages (in a real app, use 'express-session')
// For this example, we'll simulate it with a simple object attached to res.locals
// In a production environment, you would use 'express-session' middleware
// and configure it properly.
app.use((req, res, next) => {
    if (!req.session) {
        req.session = {};
    }
    next();
});


// Route for the index page
app.get('/', (req, res) => {
    res.render('index', { messages: res.locals.messages });
});

// Route to handle calculation
app.post('/calculate', async (req, res) => {
    const { a, b } = req.body;

    // Validate input
    if (!a || !b) {
        if (!req.session.messages) req.session.messages = [];
        req.session.messages.push({ type: 'error', text: 'Both values a and b are required!' });
        return res.redirect('/');
    }

    try {
        console.log(`Sending request to backend to sum ${a} and ${b}`);
        const response = await axios.post(`${BACKEND_URL}/sum`, {
            a: parseFloat(a),
            b: parseFloat(b)
        });

        const resultData = response.data;
        console.log('Received result from backend:', resultData);
        res.render('result', { result: resultData });
    } catch (error) {
        let errorMessage = 'An unexpected error occurred.';
        if (error.response && error.response.data && error.response.data.error) {
            errorMessage = `Error: ${error.response.data.error}`;
        } else if (error.message) {
            errorMessage = `An unexpected error occurred: ${error.message}`;
        }
        console.log('Error occurred while communicating with backend:', errorMessage);
        if (!req.session.messages) req.session.messages = [];
        req.session.messages.push({ type: 'error', text: errorMessage });
        res.redirect('/');
    }
});

// Health check endpoint
app.get('/health', (req, res) => {
    res.json({ status: 'healthy', service: 'Node.js Frontend' });
});

// Start the server
app.listen(PORT, () => {
    console.log(`Node.js Frontend running on http://localhost:${PORT}`);
});
