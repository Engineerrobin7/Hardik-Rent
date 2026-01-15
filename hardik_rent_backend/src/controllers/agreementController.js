const db = require('../config/db');
const { v4: uuidv4 } = require('uuid');

exports.uploadAgreement = async (req, res) => {
    try {
        const { unitId, tenantId, pdfUrl, startDate, endDate } = req.body;
        const ownerId = req.user.uid;
        const id = uuidv4();

        const query = `
            INSERT INTO agreements (id, unit_id, tenant_id, owner_id, pdf_url, start_date, end_date)
            VALUES (?, ?, ?, ?, ?, ?, ?)
        `;

        await db.execute(query, [id, unitId, tenantId, ownerId, pdfUrl, startDate, endDate]);

        res.status(201).json({ id, message: 'Agreement uploaded successfully' });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
};

exports.getAgreementsByUnit = async (req, res) => {
    try {
        const { unitId } = req.params;
        const [agreements] = await db.query('SELECT * FROM agreements WHERE unit_id = ?', [unitId]);
        res.status(200).json(agreements);
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
};

exports.getTenantAgreements = async (req, res) => {
    try {
        const tenantId = req.user.uid;
        const [agreements] = await db.query(`
            SELECT a.*, p.name as propertyName, u.unit_number 
            FROM agreements a
            JOIN units u ON a.unit_id = u.id
            JOIN properties p ON u.property_id = p.id
            WHERE a.tenant_id = ?
        `, [tenantId]);
        res.status(200).json(agreements);
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
};
