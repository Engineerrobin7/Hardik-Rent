if (process.env.NODE_ENV !== 'production') {
    require('dotenv').config();
}
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const compression = require('compression');
const { verifyToken } = require('./middleware/auth');
const admin = require('firebase-admin'); // Add firebase-admin

const app = express();

// Set strict routing to false to handle trailing slashes
app.set('strict routing', false);

// 1. Initial Logging Middleware (Catch everything)
app.use((req, res, next) => {
    console.log(`📡 [${new Date().toISOString()}] Incoming: ${req.method} ${req.url}`);

    // Help users who forget the /api prefix
    const commonPrefixes = ['/auth', '/properties', '/analytics', '/payments', '/agreements', '/maintenance'];
    const hasPrefix = commonPrefixes.some(p => req.url.startsWith(p));
    if (hasPrefix && !req.url.startsWith('/api')) {
        console.warn(`⚠️  Suggestion: Missing '/api' prefix for ${req.url}. Redirecting/Correcting...`);
        // We won't auto-redirect to avoid POST issues, but we can send a 404 with a hint
        return res.status(404).json({
            error: 'Missing /api prefix',
            message: `Did you mean https://${req.get('host')}/api${req.url}?`,
            suggestion: 'All API routes are prefixed with /api/v1 (or just /api based on current config)'
        });
    }
    next();
});

// Initialize Firebase Admin SDK
let firebaseApp;
try {
    firebaseApp = admin.app();
} catch (e) {
    // Default app not initialized, so initialize it
}

if (!firebaseApp) {
    if (process.env.FIREBASE_SERVICE_ACCOUNT_KEY) {
        if (process.env.FIREBASE_SERVICE_ACCOUNT_KEY === 'your_firebase_service_account_json_here') {
            console.error('FIREBASE_SERVICE_ACCOUNT_KEY contains placeholder value. Please replace with actual Firebase service account JSON.');
            process.exit(1); // Exit if Firebase is not configured correctly
        }
        try {
            const serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT_KEY);
            admin.initializeApp({
                credential: admin.credential.cert(serviceAccount)
            });
            console.log('Firebase Admin SDK initialized successfully from environment variable.');
        } catch (error) {
            console.error('Failed to parse FIREBASE_SERVICE_ACCOUNT_KEY or initialize Firebase:', error);
            process.exit(1); // Exit if Firebase cannot be initialized
        }
    } else {
        console.error('FIREBASE_SERVICE_ACCOUNT_KEY environment variable is not set. Firebase Admin SDK not initialized.');
        process.exit(1); // Exit if Firebase is not configured
    }
} else {
    console.log('Firebase Admin SDK already initialized.'); // Log if already initialized
}

// Middleware
app.use(cors());
app.use(helmet());
app.use(morgan('dev'));
app.use(compression());
app.use(express.json());

const path = require('path');

// Root route
app.get('/', (req, res) => {
    res.json({ message: 'Hardik Rent API is running!', status: 'OK' });
});

// API Tester Page
app.get('/test', (req, res) => {
    res.sendFile(path.join(__dirname, 'test_dashboard.html'));
});

// API Base route
app.get('/api', (req, res) => {
    res.json({ message: 'Hardik Rent API Base', status: 'OK' });
});

// Debug route to list all registered paths
app.get('/api/debug-routes', (req, res) => {
    const routes = [];
    app._router.stack.forEach((middleware) => {
        if (middleware.route) { // routes registered directly on the app
            routes.push(`${Object.keys(middleware.route.methods).join(', ').toUpperCase()} ${middleware.route.path}`);
        } else if (middleware.name === 'router') { // routes added as router middleware
            middleware.handle.stack.forEach((handler) => {
                const route = handler.route;
                if (route) {
                    const path = middleware.regexp.source.replace('\\/?', '').replace('^', '').replace('(?=\\/|$)', '') + route.path;
                    routes.push(`${Object.keys(route.methods).join(', ').toUpperCase()} ${path}`);
                }
            });
        }
    });
    res.json({ routes });
});

// Routes
const propertyRoutes = require('./routes/propertyRoutes');
const maintenanceRoutes = require('./routes/maintenanceRoutes');
const authRoutes = require('./routes/authRoutes');
const analyticsRoutes = require('./routes/analyticsRoutes');
const paymentRoutes = require('./routes/paymentRoutes');
const agreementRoutes = require('./routes/agreementRoutes');
const rentRoutes = require('./routes/rentRoutes');
const electricityRoutes = require('./routes/electricityRoutes');
const extendedRoutes = require('./routes/extendedRoutes');

app.use('/api/properties', verifyToken, propertyRoutes);
app.use('/api/maintenance', verifyToken, maintenanceRoutes);
app.use('/api/auth', authRoutes);
app.use('/api/analytics', verifyToken, analyticsRoutes);
app.use('/api/payments', verifyToken, paymentRoutes);
app.use('/api/agreements', verifyToken, agreementRoutes);
app.use('/api/rent', verifyToken, rentRoutes);
app.use('/api/electricity', verifyToken, electricityRoutes);
app.use('/api/v2', verifyToken, extendedRoutes);

// Health check
app.get('/health', (req, res) => {
    res.status(200).send('OK');
});

// 404 Handler - Catch all other routes
app.use((req, res) => {
    console.log(`404 Not Found: ${req.method} ${req.path}`);
    res.status(404).json({
        error: 'Route not found',
        path: req.path,
        method: req.method,
        suggestion: 'Ensure you are using the /api prefix for API routes'
    });
});

// Error handling
app.use((err, req, res, next) => {
    console.error(err.stack);
    res.status(500).json({ error: 'Something went wrong!' });
});

const PORT = process.env.PORT || 3000;
const server = app.listen(PORT, () => {
    console.log(`Hardik Rent Backend running on port ${PORT}`);
});

server.on('error', (e) => {
    if (e.code === 'EADDRINUSE') {
        console.error('Address in use, retrying...');
        setTimeout(() => {
            server.close();
            server.listen(PORT);
        }, 1000);
    } else {
        console.error('Server Error:', e);
    }
});

module.exports = app;
