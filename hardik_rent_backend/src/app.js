require('dotenv').config();
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const compression = require('compression');
const { verifyToken } = require('./middleware/auth');

const app = express();

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
app.listen(PORT, () => {
    console.log(`Hardik Rent Backend running on port ${PORT}`);
});

module.exports = app;
