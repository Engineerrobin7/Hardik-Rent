const { auth, db } = require('../config/firebaseAdmin');

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

        // Initial user document in Firestore
        await db.collection('users').doc(userRecord.uid).set({
            uid: userRecord.uid,
            email,
            displayName,
            phoneNumber,
            role,
            createdAt: new Date().toISOString(),
            updatedAt: new Date().toISOString()
        });

        res.status(201).json({
            message: 'User registered successfully via Firebase Auth',
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

        if (!fcmToken) {
            return res.status(400).json({ error: 'FCM token is required' });
        }

        await db.collection('users').doc(uid).update({
            fcmToken: fcmToken,
            updatedAt: new Date().toISOString()
        });

        res.status(200).json({ message: 'FCM token updated successfully' });
    } catch (error) {
        console.error('Update FCM Token Error:', error);
        res.status(500).json({ error: error.message });
    }
};

exports.syncUser = async (req, res) => {
    try {
        const { displayName, email, phoneNumber, photoURL } = req.body;
        const uid = req.user.uid;

        const userRef = db.collection('users').doc(uid);
        const doc = await userRef.get();

        const userData = {
            uid,
            displayName: displayName || req.user.name || '',
            email: email || req.user.email || '',
            phoneNumber: phoneNumber || req.user.phone_number || '',
            photoURL: photoURL || req.user.picture || '',
            updatedAt: new Date().toISOString()
        };

        if (!doc.exists) {
            userData.createdAt = new Date().toISOString();
            userData.role = req.user.role || 'tenant'; // Default role
            await userRef.set(userData);
        } else {
            await userRef.update(userData);
        }

        res.status(200).json({ message: 'User synced successfully', user: userData });
    } catch (error) {
        console.error('Sync User Error:', error);
        res.status(500).json({ error: error.message });
    }
};

exports.getUser = async (req, res) => {
    try {
        const uid = req.user.uid;
        const userDoc = await db.collection('users').doc(uid).get();

        if (!userDoc.exists) {
            return res.status(404).json({ error: 'User not found' });
        }

        res.status(200).json(userDoc.data());
    } catch (error) {
        console.error('Get User Error:', error);
        res.status(500).json({ error: error.message });
    }
};

exports.createTenant = async (req, res) => {
    try {
        const { email, displayName, phoneNumber, propertyId, unitId } = req.body;
        const ownerId = req.user.uid;

        // Check if user already exists
        let userRecord;
        try {
            userRecord = await auth.getUserByEmail(email);
        } catch (error) {
            if (error.code === 'auth/user-not-found') {
                // Create user if not exists
                userRecord = await auth.createUser({
                    email,
                    displayName,
                    phoneNumber,
                    password: Math.random().toString(36).slice(-8) // Random temp password
                });
                await auth.setCustomUserClaims(userRecord.uid, { role: 'tenant' });
            } else {
                throw error;
            }
        }

        const tenantData = {
            uid: userRecord.uid,
            email,
            displayName,
            phoneNumber,
            role: 'tenant',
            ownerId,
            propertyId,
            unitId,
            status: 'active',
            createdAt: new Date().toISOString(),
            updatedAt: new Date().toISOString()
        };

        await db.collection('users').doc(userRecord.uid).set(tenantData, { merge: true });

        // Update unit status if provided
        if (propertyId && unitId) {
            await db.collection('properties').doc(propertyId)
                .collection('units').doc(unitId)
                .update({
                    status: 'occupied',
                    tenantId: userRecord.uid,
                    updatedAt: new Date().toISOString()
                });
        }

        res.status(201).json({
            message: 'Tenant created/assigned successfully',
            uid: userRecord.uid
        });
    } catch (error) {
        console.error('Create Tenant Error:', error);
        res.status(500).json({ error: error.message });
    }
};

