# Building the Android App (APK) for Your Client

This guide explains how to build a release version of your Android app that connects to your live backend.

## Prerequisites

1.  **Deployed Backend:** You must have successfully deployed your backend and have your public-facing `BASE_URL`.
2.  **Razorpay Live Key:** You must have your live (production) Razorpay key.
3.  **Flutter Environment:** Ensure your Flutter development environment is set up correctly.

## Building the APK

1.  **Open your terminal or command prompt.**
2.  **Navigate to the root directory of your Flutter project** (the `Hardik Rent` folder).
3.  **Run the following command:**

    ```sh
    flutter build apk --release --dart-define=BASE_URL=https://your-backend-url.com/api --dart-define=RAZORPAY_KEY=your_live_razorpay_key
    ```

    **IMPORTANT:** You need to replace the placeholder values:

    *   `https://your-backend-url.com/api`: Replace this with the actual URL of your deployed backend (e.g., the URL from Render).
    *   `your_live_razorpay_key`: Replace this with your live Razorpay key (e.g., `rzp_live_xxxxxxxxxxxxxx`).

    **Example:**

    ```sh
    flutter build apk --release --dart-define=BASE_URL=https://hardik-rent-backend.onrender.com/api --dart-define=RAZORPAY_KEY=rzp_live_1234567890ABCD
    ```

4.  **Wait for the build to complete.** Flutter will create the release APK file.

## Finding the APK File

After the build is successful, the APK file will be located in the following directory:

`build/app/outputs/flutter-apk/app-release.apk`

You can also find the path in the output of the build command.

## Sharing with Your Client

You can now take the `app-release.apk` file and share it with your client. They can install it on their Android device.

**Note on Android App Bundles (.aab):**

For publishing on the Google Play Store, it is recommended to build an Android App Bundle (`.aab`) instead of an APK. The command is very similar:

```sh
flutter build appbundle --release --dart-define=BASE_URL=https://your-backend-url.com/api --dart-define=RAZORPAY_KEY=your_live_razorpay_key
```

The output file will be in `build/app/outputs/bundle/release/app-release.aab`.
