const { db } = require('../config/firebaseAdmin');
const { v4: uuidv4 } = require('uuid');

exports.addExpense = async (req, res) => {
    try {
        const { title, amount, category, propertyId, unitId, date, description } = req.body;
        const ownerId = req.user.uid;

        if (!title || !amount || !category || !propertyId) {
            return res.status(400).json({ error: 'Missing required fields: title, amount, category, propertyId' });
        }

        const expenseId = uuidv4();
        const expenseData = {
            id: expenseId,
            ownerId,
            propertyId,
            unitId: unitId || null, // Optional if it's property-wide
            title,
            amount: Number(amount),
            category, // e.g., 'Repairs', 'Tax', 'Salary', 'Utility'
            date: date || new Date().toISOString(),
            description: description || '',
            createdAt: new Date().toISOString()
        };

        await db.collection('expenses').doc(expenseId).set(expenseData);

        res.status(201).json({ message: 'Expense recorded successfully', expenseId });
    } catch (error) {
        console.error('Add Expense Error:', error);
        res.status(500).json({ error: error.message });
    }
};

exports.getOwnerExpenses = async (req, res) => {
    try {
        const ownerId = req.user.uid;
        const { propertyId, category, startDate, endDate } = req.query;

        let query = db.collection('expenses').where('ownerId', '==', ownerId);

        if (propertyId) query = query.where('propertyId', '==', propertyId);
        if (category) query = query.where('category', '==', category);

        const snapshot = await query.orderBy('date', 'desc').get();
        let expenses = snapshot.docs.map(doc => doc.data());

        // Simple manual filter for dates since Firestore query construction can be tricky with multiple where/orderBy
        if (startDate) {
            expenses = expenses.filter(e => e.date >= startDate);
        }
        if (endDate) {
            expenses = expenses.filter(e => e.date <= endDate);
        }

        res.status(200).json(expenses);
    } catch (error) {
        console.error('Get Expenses Error:', error);
        res.status(500).json({ error: error.message });
    }
};

exports.deleteExpense = async (req, res) => {
    try {
        const { id } = req.params;
        const ownerId = req.user.uid;

        const docRef = db.collection('expenses').doc(id);
        const doc = await docRef.get();

        if (!doc.exists) return res.status(404).json({ error: 'Expense not found' });
        if (doc.data().ownerId !== ownerId) return res.status(403).json({ error: 'Unauthorized' });

        await docRef.delete();
        res.status(200).json({ message: 'Expense deleted successfully' });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
};
