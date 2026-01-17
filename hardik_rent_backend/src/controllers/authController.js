const { auth } = require('../config/firebaseAdmin');
const db = require('../config/db');

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

        // Create user record in MySQL
        const query = `
            INSERT INTO users (id, email, name, role, phone) 
            VALUES (?, ?, ?, ?, ?)
        `;
        await db.execute(query, [userRecord.uid, email, displayName, role, phoneNumber]);

        res.status(201).json({
            message: 'User registered successfully and stored in MySQL',
            uid: userRecord.uid
        });
    } catch (error) {
        console.error('Registration Error:', error);
        res.status(500).json({ error: error.message });
    }
};

exports.updateFcmToken = async (req, res) => {
    try {
        const { fcmToken } = req.body;
        const uid = req.user.uid;

        const query = 'UPDATE users SET fcm_token = ? WHERE id = ?';
        await db.execute(query, [fcmToken, uid]);

        res.status(200).json({ message: 'FCM token updated in MySQL' });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
};

exports.syncUser = async (req, res) => {
    try {
        const { email, name, role, phone } = req.body;
        const uid = req.user.uid;

        // Check if user exists
        const [rows] = await db.execute('SELECT id FROM users WHERE id = ?', [uid]);

        if (rows.length === 0) {
            // Insert new user if not exists
            const query = 'INSERT INTO users (id, email, name, role, phone) VALUES (?, ?, ?, ?, ?)';
            await db.execute(query, [uid, email, name, role, phone]);
            res.status(201).json({ message: 'User synced to MySQL' });
        } else {
            // Update existing user info
            const query = 'UPDATE users SET email = ?, name = ?, phone = ? WHERE id = ?';
            await db.execute(query, [email, name, phone, uid]);
            res.status(200).json({ message: 'User info updated in MySQL' });
        }
    } catch (error) {
        console.error('Sync Error:', error);
        res.status(500).json({ error: error.message });
    }
};
exports.getUser = async (req, res) => {
    try {
        const uid = req.user.uid;
        const [rows] = await db.execute('SELECT * FROM users WHERE id = ?', [uid]);

        if (rows.length === 0) {
            return res.status(404).json({ error: 'User not found in MySQL' });
        }

        res.status(200).json(rows[0]);
    } catch (error) {
        console.error('Get User Error:', error);
        res.status(500).json({ error: error.message });
    }
};

// Create Tenant User (for owner to add tenants)
exports.createTenant = async (req, res) => {
    try {
        const { name, email, phone, role } = req.body;
        const { v4: uuidv4 } = require('uuid');
        const userId = uuidv4();

        await db.execute(
            'INSERT INTO users (id, name, email, phone, role) VALUES (?, ?, ?, ?, ?) ON DUPLICATE KEY UPDATE name = VALUES(name), phone = VALUES(phone)',
            [userId, name, email, phone || null, role || 'tenant']
        );

        res.status(201).json({ id: userId, message: 'Tenant created successfully' });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
};
