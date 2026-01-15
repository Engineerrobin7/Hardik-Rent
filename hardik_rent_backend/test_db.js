const pool = require('./src/config/db');

async function testConnection() {
    try {
        const [rows] = await pool.query('SELECT 1 + 1 AS result');
        console.log('✅ MySQL Connection Successful:', rows[0].result === 2);

        const [tables] = await pool.query('SHOW TABLES');
        console.log('Tables found:', tables.map(t => Object.values(t)[0]));
    } catch (err) {
        console.error('❌ MySQL Connection Failed:', err.message);
        console.error('Full Error:', err);
    } finally {
        process.exit();
    }
}

testConnection();
