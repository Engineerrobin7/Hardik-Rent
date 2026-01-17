const admin = require('firebase-admin');
const mysql = require('mysql2/promise');
require('dotenv').config();

// Initialize Firebase Admin
const serviceAccount = require('./serviceAccountKey.json');
admin.initializeApp({
    credential: admin.credential.cert(serviceAccount)
});

async function createDemoAccounts() {
    console.log('🚀 Creating demo accounts...\n');

    // MySQL connection
    const db = await mysql.createConnection({
        host: process.env.DB_HOST || 'localhost',
        user: process.env.DB_USER || 'root',
        password: process.env.DB_PASSWORD,
        database: process.env.DB_NAME || 'hardik_rent'
    });

    const demoAccounts = [
        {
            email: 'owner@hardik.com',
            password: 'password',
            displayName: 'Demo Owner',
            role: 'owner',
            phone: '+919876543210'
        },
        {
            email: 'tenant@hardik.com',
            password: 'password',
            displayName: 'Demo Tenant',
            role: 'tenant',
            phone: '+919876543211'
        }
    ];

    for (const account of demoAccounts) {
        try {
            console.log(`Creating ${account.role}: ${account.email}`);

            // Check if user already exists in Firebase
            let userRecord;
            try {
                userRecord = await admin.auth().getUserByEmail(account.email);
                console.log(`  ✓ Firebase user already exists (UID: ${userRecord.uid})`);
            } catch (error) {
                if (error.code === 'auth/user-not-found') {
                    // Create new Firebase user
                    userRecord = await admin.auth().createUser({
                        email: account.email,
                        password: account.password,
                        displayName: account.displayName,
                        phoneNumber: account.phone
                    });
                    console.log(`  ✓ Created Firebase user (UID: ${userRecord.uid})`);
                } else {
                    throw error;
                }
            }

            // Set custom claims for role
            await admin.auth().setCustomUserClaims(userRecord.uid, { role: account.role });
            console.log(`  ✓ Set role: ${account.role}`);

            // Check if user exists in MySQL
            const [rows] = await db.execute('SELECT id FROM users WHERE id = ?', [userRecord.uid]);

            if (rows.length === 0) {
                // Insert into MySQL
                await db.execute(
                    'INSERT INTO users (id, email, name, role, phone) VALUES (?, ?, ?, ?, ?)',
                    [userRecord.uid, account.email, account.displayName, account.role, account.phone]
                );
                console.log(`  ✓ Created MySQL record`);
            } else {
                console.log(`  ✓ MySQL record already exists`);
            }

            console.log(`✅ ${account.role} account ready!\n`);
        } catch (error) {
            console.error(`❌ Error creating ${account.role}:`, error.message);
            console.log('');
        }
    }

    await db.end();
    console.log('🎉 Demo accounts setup complete!');
    console.log('\n📝 Login Credentials:');
    console.log('Owner:  owner@hardik.com  / password');
    console.log('Tenant: tenant@hardik.com / password');

    process.exit(0);
}

createDemoAccounts().catch(error => {
    console.error('Fatal error:', error);
    process.exit(1);
});
