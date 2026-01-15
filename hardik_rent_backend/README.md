# Hardik Rent Backend (Firebase Integrated)

This is the Node.js backend for the Hardik Rent application, designed to work seamlessly with Firebase Firestore, Auth, and Messaging.

## 🚀 Features
- **Firebase Admin SDK**: Direct secure access to your Firebase project.
- **REST APIs**: Structured endpoints for Properties, Maintenance, and Auth.
- **FCM Notifications**: Automated push notifications for maintenance updates.
- **Role-Based Access**: Secure custom claims for 'Owner' and 'Tenant' roles.
- **Atomic Transactions**: Reliable payment recording and analytics updates.

## 🛠️ Setup Instructions

1. **Install Dependencies**:
   ```bash
   npm install
   ```

2. **Firebase Service Account**:
   - Go to [Firebase Console](https://console.firebase.google.com/).
   - Project Settings > Service Accounts.
   - Click **Generate New Private Key**.
   - Save the JSON file as `serviceAccountKey.json` in the root of this backend folder.

3. **Environment Variables**:
   - Edit `.env` and set your `FIREBASE_PROJECT_ID`.

4. **Run the Server**:
   ```bash
   npm start
   ```

## 📂 API Endpoints

### Auth
- `POST /api/auth/register`: Create a new user with a specific role ('owner' or 'tenant').
- `POST /api/auth/fcm-token`: Update the FCM token for push notifications.

### Properties (Visual Booking)
- `GET /api/properties`: Get all properties for the logged-in owner.
- `POST /api/properties`: Create a new property with floor layout.
- `PATCH /api/properties/unit-status`: Update unit occupancy (Flight-style grid update).

### Maintenance
- `POST /api/maintenance/tickets`: Create a new maintenance request (Tenant).
- `PATCH /api/maintenance/tickets/status`: Update status (Owner) - triggers FCM to tenant.

## 🔒 Security
All routes (except registration) are protected by the `verifyToken` middleware, which validates the Firebase ID token sent from the Flutter app.
