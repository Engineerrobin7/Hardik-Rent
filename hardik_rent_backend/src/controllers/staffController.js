const { auth, db } = require('../config/firebaseAdmin');
const { v4: uuidv4 } = require('uuid');

exports.addStaff = async (req, res) => {
    try {
        const { name, email, phone, role, propertyIds } = req.body;
        const ownerId = req.user.uid;

        // Role should be limited, e.g., 'manager', 'security', 'maintenance_staff'
        const allowedRoles = ['manager', 'security', 'maintenance_staff'];
        if (!allowedRoles.includes(role)) {
            return res.status(400).json({ error: 'Invalid staff role' });
        }

        // Create user in Firebase Auth
        let userRecord;
        try {
            userRecord = await auth.createUser({
                email,
                phoneNumber: phone,
                displayName: name,
                password: Math.random().toString(36).slice(-10) // Temp password
            });
        } catch (e) {
            // If already exists, we might just update their role, but for staff, usually unique
            return res.status(400).json({ error: 'User already exists or email invalid' });
        }

        // Set Custom Claims
        await auth.setCustomUserClaims(userRecord.uid, {
            role: 'staff',
            staffType: role,
            ownerId: ownerId
        });

        const staffData = {
            uid: userRecord.uid,
            name,
            email,
            phone,
            role, // staff role specific
            ownerId,
            propertyIds: propertyIds || [], // Array of properties they can see
            status: 'active',
            createdAt: new Date().toISOString()
        };

        await db.collection('staff').doc(userRecord.uid).set(staffData);

        res.status(201).json({ message: 'Staff added successfully', uid: userRecord.uid });
    } catch (error) {
        console.error('Add Staff Error:', error);
        res.status(500).json({ error: error.message });
    }
};

exports.getOwnerStaff = async (req, res) => {
    try {
        const ownerId = req.user.uid;
        const snapshot = await db.collection('staff').where('ownerId', '==', ownerId).get();
        const staffList = snapshot.docs.map(doc => doc.data());
        res.status(200).json(staffList);
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
};
