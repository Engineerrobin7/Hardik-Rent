const admin = require('firebase-admin');
const path = require('path');
const fs = require('fs');
require('dotenv').config();

let serviceAccount = null;

if (process.env.FIREBASE_SERVICE_ACCOUNT_PATH) {
    try {
        const absolutePath = path.resolve(process.cwd(), process.env.FIREBASE_SERVICE_ACCOUNT_PATH);
        if (fs.existsSync(absolutePath)) {
            serviceAccount = require(absolutePath);
        } else {
            console.warn('⚠️  serviceAccountKey.json not found at:', absolutePath);
        }
    } catch (e) {
        console.warn('❌ Could not load service account:', e.message);
    }
}

const projectId = process.env.FIREBASE_PROJECT_ID;

if (projectId === 'your-project-id') {
    console.error('❌ ERROR: You are still using "your-project-id" in .env. Please replace it with your actual Firebase Project ID.');
}

if (serviceAccount || (projectId && projectId !== 'your-project-id')) {
    try {
        if (!admin.apps.length) {
            admin.initializeApp({
                credential: serviceAccount ? admin.credential.cert(serviceAccount) : admin.credential.applicationDefault(),
                databaseURL: projectId ? `https://${projectId}.firebaseio.com` : undefined,
                storageBucket: projectId ? `${projectId}.appspot.com` : undefined
            });
            console.log('✅ Firebase Admin Initialized');
        }
    } catch (err) {
        console.error('❌ Firebase Admin Init Error:', err.message);
    }
} else {
    console.error('❌ Firebase Admin NOT initialized. Please configure .env correctly.');
}

// Safely get Firebase services to prevent crashing if not initialized
let db, auth, storage, messaging;

if (admin.apps.length > 0) {
    db = admin.firestore();
    auth = admin.auth();
    storage = admin.storage();
    messaging = admin.messaging();
} else {
    // Return dummy objects that log a warning when called, instead of crashing the server
    const dummy = (name) => ({
        collection: () => ({ doc: () => ({ set: () => { console.error(`❌ Cannot use ${name}: Firebase not initialized`); return Promise.reject(new Error('Firebase not initialized')); } }) }),
        verifyIdToken: () => { console.error(`❌ Cannot use AUTH: Firebase not initialized`); return Promise.reject(new Error('Firebase not initialized')); },
        send: () => { console.error(`❌ Cannot use MESSAGING: Firebase not initialized`); return Promise.reject(new Error('Firebase not initialized')); }
    });
    db = dummy('Firestore');
    auth = dummy('Auth');
    storage = dummy('Storage');
    messaging = dummy('Messaging');
}

module.exports = { admin, db, auth, storage, messaging };
