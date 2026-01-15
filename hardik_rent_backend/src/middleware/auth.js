const { auth, admin } = require('../config/firebaseAdmin');

const verifyToken = async (req, res, next) => {
    // DEVELOPMENT BYPASS: If Firebase is not initialized OR header X-Test-Mode is set
    if (admin.apps.length === 0 || req.headers['x-test-mode'] === 'true') {
        console.warn('⚠️  Auth Bypass: Using mock user for development');
        req.user = {
            uid: req.headers['x-test-uid'] || 'test-owner-id',
            email: 'test@example.com',
            role: 'owner'
        };
        return next();
    }

    const authHeader = req.headers.authorization;

    if (!authHeader || !authHeader.startsWith('Bearer ')) {
        return res.status(401).json({ error: 'Unauthorized: No token provided' });
    }

    const idToken = authHeader.split('Bearer ')[1];

    try {
        const decodedToken = await auth.verifyIdToken(idToken);
        req.user = decodedToken;
        next();
    } catch (error) {
        console.error('Error verifying Firebase token:', error);
        return res.status(401).json({ error: 'Unauthorized: Invalid token' });
    }
};

module.exports = { verifyToken };
