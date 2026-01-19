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

// Initialize Firebase Admin SDK
if (process.env.FIREBASE_SERVICE_ACCOUNT_KEY) {
    try {
        const serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT_KEY);
        admin.initializeApp({
            credential: admin.credential.cert(serviceAccount)
        });
        console.log('Firebase Admin SDK initialized successfully from environment variable.');
    } catch (error) {
        console.error('Failed to parse FIREBASE_SERVICE_ACCOUNT_KEY:', error);
        process.exit(1); // Exit if Firebase cannot be initialized
    }
} else {
    console.error('FIREBASE_SERVICE_ACCOUNT_KEY environment variable is not set. Firebase Admin SDK not initialized.');
    process.exit(1); // Exit if Firebase is not configured
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

// Routes
const propertyRoutes = require('./routes/propertyRoutes');
const maintenanceRoutes = require('./routes/maintenanceRoutes');
const authRoutes = require('./routes/authRoutes');
const analyticsRoutes = require('./routes/analyticsRoutes');
const paymentRoutes = require('./routes/paymentRoutes');
const agreementRoutes = require('./routes/agreementRoutes');

app.use('/api/properties', verifyToken, propertyRoutes);
app.use('/api/maintenance', verifyToken, maintenanceRoutes);
app.use('/api/auth', authRoutes);
app.use('/api/analytics', verifyToken, analyticsRoutes);
app.use('/api/payments', verifyToken, paymentRoutes);
app.use('/api/agreements', verifyToken, agreementRoutes);

// Health check
app.get('/health', (req, res) => {
    res.status(200).send('OK');
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
