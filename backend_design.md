# HardikRent Backend & Database Design Specification

## 1. Architecture Overview
- **Platform**: Firebase (Google Cloud Platform)
- **Database**: Cloud Firestore (NoSQL, Real-time)
- **Authentication**: Firebase Authentication (Phone/Email)
- **File Storage**: Firebase Storage (Images, PDFs)
- **Serverless Logic**: Cloud Functions (Node.js) used for automated tasks like rent generation and penalties.

---

## 2. Firestore Database Schema

### `users` (Collection)
Stores all user profiles (Super Admin, Property Owners, Tenants).
```json
{
  "uid": "string (Auth ID)",
  "role": "string (owner | tenant | admin)",
  "name": "string",
  "email": "string",
  "phoneNumber": "string",
  "profileImage": "url",
  "fcmToken": "string (for push notifications)",
  "createdAt": "timestamp",
  
  // Tenant Specific Fields (only if role == tenant)
  "currentFlatId": "string (ref)",
  "permanentAddress": "string",
  "emergencyContact": "string",
  "idProofUrl": "url",
  "agreementUrl": "url",
  "securityDeposit": "number",
  "isActive": "boolean" // false if vacated
}
```

### `properties` (Collection)
Represents a Building or Apartment Complex.
```json
{
  "id": "auto-id",
  "ownerId": "string (ref to users)",
  "name": "string (e.g., Shanti Niwas)",
  "address": "string",
  "totalFlats": "number",
  
  // Configuration
  "rentDueDay": "number (default: 5)",
  "gracePeriodDays": "number (default: 3)",
  "penaltyPerDay": "number (default: 100.0)",
  "isMeteredElectricity": "boolean"
}
```

### `flats` (Collection)
Individual units within a property. Only one active tenant per flat.
```json
{
  "id": "auto-id",
  "propertyId": "string (ref to properties)",
  "flatNumber": "string (e.g., 101, A-2)",
  "floor": "number",
  "monthlyRent": "number",
  
  // State
  "isOccupied": "boolean",
  "currentTenantId": "string (ref to users) | null",
  "meterReadingLast": "number (initial/last month reading)"
}
```

### `rent_records` (Collection)
Generated monthly for each active tenant.
```json
{
  "id": "auto-id",
  "flatId": "string",
  "tenantId": "string",
  "propertyId": "string", // Denormalized for easy querying
  "month": "string (e.g., Dec-2025)",
  "year": "number",
  "monthIndex": "number (1-12)",
  
  // Dates
  "generatedDate": "timestamp",
  "dueDate": "timestamp",
  "clearedDate": "timestamp | null",
  
  // Financial Breakdown
  "baseRent": "number",
  "electricity": {
    "prevReading": "number",
    "currReading": "number",
    "unitRate": "number",
    "amount": "number"
  },
  "miscellaneousCharges": "number",
  "penaltyApplied": "number", // Auto-updated
  
  // Totals
  "totalDue": "number", // sum of above
  "amountPaid": "number",
  "balanceAmount": "number",
  
  // Status
  "status": "string (pending | paid | partial | overdue)",
  "flag": "string (green | yellow | red)"
}
```

### `payments` (Collection)
Ledger of all incoming transactions.
```json
{
  "id": "auto-id",
  "rentRecordId": "string",
  "tenantId": "string",
  "amount": "number",
  "method": "string (upi | cash | bank_transfer)",
  "transactionId": "string (optional)",
  "screenshotUrl": "url (optional)",
  "status": "string (pending | approved | rejected)",
  "timestamp": "timestamp",
  "approvedBy": "string (ownerId)"
}
```

---

## 3. Storage Structure (buckets)
- `/id_proofs/{userId}/{filename}`
- `/agreements/{userId}/{filename}`
- `/payment_proofs/{month}/{paymentId}.jpg`
- `/profiles/{userId}.jpg`

---

## 4. Backend Logic (Cloud Functions Needed)

1.  **`generateMonthlyRent` (Scheduled - 1st of Month)**
    -   Iterates through all active tenants.
    -   Creates a new `rent_record`.
    -   Sets Flag = `YELLOW`.
    -   Sends "Rent Generated" notification.

2.  **`updatePenalties` (Scheduled - Daily)**
    -   Checks all `pending` or `overdue` rent records.
    -   If `currentDate > dueDate + gracePeriod`:
        -   Applies `penaltyPerDay` to `penaltyApplied` field.
        -   Sets Flag = `RED`.
        -   Sends "Penalty Applied" notification.

3.  **`onPaymentApproved` (Trigger - Firestore Update)**
    -   When `payments/{id}.status` changes to `approved`:
        -   Updates `rent_records.amountPaid`.
        -   If `amountPaid >= totalDue`, sets Status = `paid`, Flag = `GREEN`.

---

## 5. Security Rules (Basic)
- **Public**: Login/Register.
- **Owner**: Read/Write own properties, flats, tenants, and their records.
- **Tenant**: Read own profile and own rent records/payments. Write/Create payment submissions.
