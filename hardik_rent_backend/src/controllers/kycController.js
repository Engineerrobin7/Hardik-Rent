const { db } = require('../config/firebaseAdmin');

exports.submitKyc = async (req, res) => {
    try {
        const { aadhaarNumber, panNumber, documentUrls } = req.body;
        const uid = req.user.uid;

        const kycData = {
            aadhaarNumber,
            panNumber,
            documentUrls: documentUrls || [],
            status: 'pending', // pending, verified, rejected
            submittedAt: new Date().toISOString()
        };

        await db.collection('users').doc(uid).update({
            kyc: kycData,
            updatedAt: new Date().toISOString()
        });

        res.status(200).json({ message: 'KYC documents submitted for verification' });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
};

exports.verifyKyc = async (req, res) => {
    try {
        const { tenantUid, status, adminNotes } = req.body;
        const adminId = req.user.uid;

        // Verify that req.user has admin/owner rights (simplified check)
        const adminDoc = await db.collection('users').doc(adminId).get();
        if (adminDoc.data().role !== 'owner') {
            return res.status(403).json({ error: 'Only owners can verify KYC' });
        }

        await db.collection('users').doc(tenantUid).update({
            'kyc.status': status,
            'kyc.verifiedAt': new Date().toISOString(),
            'kyc.adminNotes': adminNotes || '',
            'kyc.verifiedBy': adminId
        });

        res.status(200).json({ message: `KYC status updated to ${status}` });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
};
