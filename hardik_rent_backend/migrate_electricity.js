const db = require('./src/config/db');

async function migrate() {
    try {
        console.log('Adding is_electricity_active column to units table...');

        // Check if column exists
        const [columns] = await db.execute("SHOW COLUMNS FROM units LIKE 'is_electricity_active'");

        if (columns.length === 0) {
            await db.execute("ALTER TABLE units ADD COLUMN is_electricity_active BOOLEAN DEFAULT TRUE");
            console.log('Column added successfully.');
        } else {
            console.log('Column already exists.');
        }

    } catch (error) {
        console.error('Migration failed:', error);
    } finally {
        process.exit(0);
    }
}

migrate();
