# 📱 Building Hubble iOS Application on GitHub Actions

This guide explains how to build, package, and deploy the **Hubble iOS App** using **GitHub Actions CI/CD**.

---

## 🚀 Quick Start: How to Trigger iOS Build on GitHub

1. **Commit & Push your code to GitHub**:
   ```bash
   git add .
   git commit -m "Configure iOS build workflow"
   git push origin main
   ```

2. **Manual Trigger via GitHub Interface**:
   - Go to your repository on **GitHub.com**.
   - Click on the **Actions** tab.
   - Select **Build iOS Application (IPA)** under *Workflows*.
   - Click **Run workflow** -> Select `main` branch -> Click **Run workflow**.

---

## 🛠️ Workflow Steps Performed automatically on GitHub

The GitHub Actions runner (`macos-latest`) performs the following steps:
1. **SDK Setup**: Sets up Flutter Stable SDK & CocoaPods.
2. **Pod Installation**: Runs `pod install` for iOS native dependencies (`Stripe`, `Google Maps`, `Flutter Map`).
3. **Automated Verification**: Executes `flutter test` (107/107 tests verified).
4. **iOS Release Compilation**: Compiles Xcode release framework with `flutter build ios --release --no-codesign`.
5. **IPA Packaging**: Packages `Runner.app` into an installable `Hubble-iOS-Release.ipa`.
6. **Artifact Output**: Uploads `Hubble-iOS-Release-IPA` to GitHub Actions downloadable artifacts.

---

## 📥 How to Download & Install the iOS `.ipa` File

1. After the workflow completes on GitHub Actions, scroll down to the **Artifacts** section at the bottom of the run summary page.
2. Click **Hubble-iOS-Release-IPA** to download the `.zip` containing `Hubble-iOS-Release.ipa`.
3. **Installation Options**:
   - **Option A (AltStore / Sideloadly)**: Drag `Hubble-iOS-Release.ipa` into AltStore or Sideloadly on your Mac/Windows PC to install directly onto your connected iPhone.
   - **Option B (Xcode / Apple Developer TestFlight)**: Sign the app with your Apple Developer Team ID in Xcode or Apple App Store Connect.

---

## 🔐 App Store / TestFlight Signing Setup (Optional)

If you have an **Apple Developer Account** and want GitHub Actions to automatically upload to **TestFlight**:
Add the following Secrets under `GitHub Repository Settings -> Secrets and variables -> Actions`:
- `APP_STORE_CONNECT_API_KEY`
- `APPLE_CERTIFICATE_BASE64`
- `PROVISIONING_PROFILE_BASE64`
