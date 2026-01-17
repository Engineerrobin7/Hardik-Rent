const { auth } = require('../config/firebaseAdmin');

exports.registerUser = async (req, res) => {
    try {
        const { email, password, role, displayName, phoneNumber } = req.body;

        // Create Firebase Auth user
        const userRecord = await auth.createUser({
            email,
            password,
            displayName,
            phoneNumber
        });

        // Set custom claims for role-based access
        await auth.setCustomUserClaims(userRecord.uid, { role });

        // Create user record in Firestore (optional, if backend needs to manage profiles)
        // For now, assume Flutter app will create user profile in Firestore after auth.

        res.status(201).json({
            message: 'User registered successfully via Firebase Auth',
            uid: userRecord.uid
        });
    } catch (error) {
        console.error('Registration Error:', error);
        res.status(500).json({ error: error.message });
    }
};

