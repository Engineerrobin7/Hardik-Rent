const promisePool = require('./hardik_rent_backend/src/config/db');

async function testConnection() {
    try {
        const [rows] = await promisePool.query('SELECT 1 + 1 AS result');
        console.log('✅ MySQL Connection Successful:', rows[0].result === 2);

        const [tables] = await promisePool.query('SHOW TABLES');
        console.log('Tables found:', tables.map(t => Object.values(t)[0]));
    } catch (err) {
        console.error('❌ MySQL Connection Failed:', err.message);
    } finally {
        process.exit();
    }
}

testConnection();
