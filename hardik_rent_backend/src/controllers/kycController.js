const { db } = require('../config/firebaseAdmin');
const https = require('https');

// To use "Real" API, sign up at sandbox.co.in
const SANDBOX_KEY = process.env.SANDBOX_API_KEY || 'YOUR_REAL_KYC_API_KEY';

/**
 * Initiates Aadhaar OTP request via Sandbox API
 */
exports.initiateAadhaarOtp = async (req, res) => {
    try {
        const { aadhaarNumber } = req.body;
        if (!aadhaarNumber || aadhaarNumber.length !== 12) {
            return res.status(400).json({ error: 'Valid 12-digit Aadhaar number is required' });
        }

        const options = {
            hostname: 'api.sandbox.co.in',
            path: '/kyc/aadhaar/okyc/otp/request',
            method: 'POST',
            headers: {
                'Authorization': SANDBOX_KEY,
                'x-api-key': SANDBOX_KEY,
                'x-api-version': '1.0',
                'Content-Type': 'application/json'
            }
        };

        const apiReq = https.request(options, (apiRes) => {
            let data = '';
            apiRes.on('data', (chunk) => data += chunk);
            apiRes.on('end', () => {
                const response = JSON.parse(data);
                if (apiRes.statusCode === 200) {
                    res.status(200).json({ 
                        message: 'OTP sent to mobile linked with Aadhaar',
                        ref_id: response.data.ref_id // Tracking ID for OTP verification step
                    });
                } else {
                    res.status(apiRes.statusCode).json(response);
                }
            });
        });

        apiReq.on('error', (e) => {
            res.status(500).json({ error: 'Sandbox API Connection Error' });
        });

        apiReq.write(JSON.stringify({ aadhaar_number: aadhaarNumber }));
        apiReq.end();

    } catch (error) {
        res.status(500).json({ error: error.message });
    }
};

/**
 * Verifies Aadhaar OTP via Sandbox API
 */
exports.verifyAadhaarOtp = async (req, res) => {
    try {
        const { otp, ref_id, tenantUid } = req.body;

        const options = {
            hostname: 'api.sandbox.co.in',
            path: '/kyc/aadhaar/okyc/otp/verify',
            method: 'POST',
            headers: {
                'Authorization': SANDBOX_KEY,
                'x-api-key': SANDBOX_KEY,
                'x-api-version': '1.0',
                'Content-Type': 'application/json'
            }
        };

        const apiReq = https.request(options, (apiRes) => {
            let data = '';
            apiRes.on('data', (chunk) => data += chunk);
            apiRes.on('end', async () => {
                const response = JSON.parse(data);
                if (apiRes.statusCode === 200) {
                    // Update user record in Firestore as Verified
                    if (tenantUid) {
                        await db.collection('users').doc(tenantUid).update({
                            'kycStatus': 'verified',
                            'aadhaarVerified': true,
                            'aadhaarDetails': response.data // Contains name, dob, address etc from Aadhaar
                        });
                    }
                    res.status(200).json({ message: 'Aadhaar Verified Successfully', data: response.data });
                } else {
                    res.status(apiRes.statusCode).json(response);
                }
            });
        });

        apiReq.write(JSON.stringify({ otp, ref_id }));
        apiReq.end();

    } catch (error) {
        res.status(500).json({ error: error.message });
    }
};

exports.submitKyc = async (req, res) => {
    try {
        const { aadhaarNumber, panNumber, documentUrls } = req.body;
        const uid = req.user.uid;

        const kycData = {
            aadhaarNumber,
            panNumber,
            documentUrls: documentUrls || [],
            status: 'pending', 
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
