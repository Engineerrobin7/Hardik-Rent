# Backend Deployment Guide

This guide will walk you through deploying your Node.js backend to the cloud. Since you are using Firebase, you don't need to deploy a separate database.

## 1. Deploying Your Node.js Backend

We recommend using a Platform-as-a-Service (PaaS) to deploy your backend. It simplifies the process significantly.

**Recommended Providers:**

*   [**Render**](https://render.com/): Offers a free tier for Node.js services and is very easy to use.
*   [**Railway**](https://railway.app/): Another excellent choice that makes deployment simple.
*   [**Heroku**](https://www.heroku.com/): A classic platform, though its free offerings are more limited now.
*   [**Google Cloud Run**](https://cloud.google.com/run): A great option if you are already in the Google Cloud ecosystem.

**Steps (using Render as an example):**

1.  **Sign up** for Render and connect your GitHub/GitLab account.
2.  **Create a new "Web Service".**
3.  **Select your project's repository.**
4.  **Configure the service:**
    *   **Name:** Give your service a name (e.g., `hardik-rent-backend`).
    *   **Region:** Choose a region close to you or your users.
    *   **Branch:** `main` or `master`.
    *   **Runtime:** `Node`.
    *   **Build Command:** `npm install`.
    *   **Start Command:** `npm start`.
5.  **Add Environment Variables:** This is the most important step. Click on the "Environment" tab and add the following key-value pairs:
    *   `FIREBASE_PROJECT_ID`: Your Firebase project ID.
    *   `JWT_SECRET`: A long, random, and secret string for signing JWTs.

6.  **Handling `serviceAccountKey.json`:**
    *   **Option 1 (Recommended): Use a secret file.** Render allows you to upload secret files.
        1.  Go to the "Environment" tab of your service.
        2.  Scroll down to "Secret Files".
        3.  Click "Add Secret File".
        4.  For the **Filename**, enter `serviceAccountKey.json`.
        5.  For the **Contents**, paste the entire content of your local `serviceAccountKey.json` file.
        6.  Add an environment variable `FIREBASE_SERVICE_ACCOUNT_PATH` with the value `/etc/secrets/serviceAccountKey.json` (Render's default path for secret files).
    *   **Option 2 (Not Recommended):** If you can't use a secret file, you can store the `serviceAccountKey.json` content as a multi-line environment variable (e.g., `FIREBASE_CREDENTIALS`), and then modify `firebaseAdmin.js` to parse this variable.

7.  **Deploy:** Click "Create Web Service". Render will now build and deploy your application.

## 2. Post-Deployment

Once your backend is deployed, Render will provide you with a public URL, like `https://hardik-rent-backend.onrender.com`.

**This is your `BASE_URL` for the Flutter app.** When you build your APK, you will use this URL.