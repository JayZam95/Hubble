# Hubble Firebase Infrastructure Deployment Guide

Follow this walkthrough to deploy Firestore security rules, indexes, and Cloud Functions directly to your live Firebase console.

---

## 📋 Prerequisites
1. Ensure **Node.js (v18 or higher)** is installed on your system. Verify by running:
   ```bash
   node -v
   npm -v
   ```
2. Verify you have the **Firebase CLI** installed globally. If not, run:
   ```bash
   npm install -g firebase-tools
   ```

---

## 🚀 Step-by-Step Deployment Pipeline

### Step 1: Authenticate with Firebase
Open your terminal inside the project root (`c:\Users\OAK-Fi\StudioProjects\Hubble`) and log into your Google account associated with the Firebase console:
```bash
firebase login
```

---

### Step 2: Link to Your Firebase Project
Inspect the active Firebase project list and select your target console:
```bash
firebase projects:list
```
Add your project to the workspace settings:
```bash
firebase use --add
```
*(Select your active project from the list and assign it an alias like `default`).*

---

### Step 3: Deploy Security Rules & Composite Indexes
We have configured local security policies in [firestore.rules](file:///c:/Users/OAK-Fi/StudioProjects/Hubble/firestore.rules) and query indexes in [firestore.indexes.json](file:///c:/Users/OAK-Fi/StudioProjects/Hubble/firestore.indexes.json). Push them live in one command:
```bash
firebase deploy --only firestore:rules,firestore:indexes
```
- **Firestore Rules**: Protects user profiles, bookings, chat rooms, and reviews from unauthorized reads or writes.
- **Firestore Indexes**: Enables high-performance compound queries (e.g. sorting active providers by category and rating, or sorting active messages in real-time chat feeds).

---

### Step 4: Deploy Cloud Functions for Push Notifications
Our Node.js triggers in `/functions` automate FCM pushes for chat messages and booking status shifts.
1. Enter the functions directory:
   ```bash
   cd functions
   ```
2. Install npm dependencies:
   ```bash
   npm install
   ```
3. Deploy functions live:
   ```bash
   firebase deploy --only functions
   ```
Once uploaded, your functions are immediately active and listening to Firestore document shifts!

---

## 🛠️ Local Verification & Emulator Suite
To test Cloud Functions and Rules locally before pushing them live, launch the Firebase Emulator Suite:
```bash
firebase emulators:start
```
Your local emulator dashboard will be available at `http://localhost:4000`.
