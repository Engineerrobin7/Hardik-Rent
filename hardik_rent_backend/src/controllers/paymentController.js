const Razorpay = require('razorpay');
const crypto = require('crypto');


// Initialize Razorpay
const razorpay = new Razorpay({
    key_id: process.env.RAZORPAY_KEY_ID || 'rzp_test_placeholder',
    key_secret: process.env.RAZORPAY_KEY_SECRET || 'placeholder_secret'
});

exports.createOrder = async (req, res) => {
    try {
        const { amount, currency = 'INR', receipt, unitId } = req.body;
        const tenantId = req.user.uid;

        const options = {
            amount: amount * 100, // Amount in paise
            currency,
            receipt,
            payment_capture: 1
        };

        const order = await razorpay.orders.create(options);

        // Flutter app will handle storing the pending payment in Firestore.

        res.status(200).json(order);
    } catch (error) {
        console.error('Razorpay Order Error:', error);
        res.status(500).json({ error: error.message });
    }
};

exports.verifyPayment = async (req, res) => {
    try {
        const { razorpay_order_id, razorpay_payment_id, razorpay_signature } = req.body;

        const generated_signature = crypto
            .createHmac('sha256', process.env.RAZORPAY_KEY_SECRET || 'placeholder_secret')
            .update(razorpay_order_id + "|" + razorpay_payment_id)
            .digest('hex');

        if (generated_signature === razorpay_signature) {
            // Flutter app will handle updating the payment status in Firestore.

            res.status(200).json({ status: 'success', message: 'Payment verified successfully' });
        } else {
            res.status(400).json({ status: 'failure', message: 'Invalid signature' });
        }
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
};
