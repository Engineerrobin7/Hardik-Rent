# MySQL Setup for Hardik Rent

## 1. Database Setup
1. Open your MySQL terminal or PHPMYADMIN.
2. Run the commands inside `database.sql` found in the `backend` folder.

## 2. Environment Variables
Update your `.env` file in the `backend` folder with these credentials:
```env
DB_HOST=localhost
DB_USER=root
DB_PASSWORD=your_password
DB_NAME=hardik_rent
PORT=3000
FIREBASE_PROJECT_ID=your-project-id
RAZORPAY_KEY_ID=your_key_id
RAZORPAY_KEY_SECRET=your_key_secret
```

## 4. Razorpay Setup
1. Create a free account on [Razorpay Dashboard](https://dashboard.razorpay.com/).
2. Go to **Settings > API Keys** and generate a Test Key.
3. Update the `Key ID` in `lib/services/payment_service.dart` and the Backend `.env`.

## 5. Running the Backend
```bash
cd hardik_rent_backend
npm install
npm start
```

## 4. Frontend Note
The app now uses `ApiService` for properties and analytics. Ensure your backend is running on `http://localhost:3000`.
