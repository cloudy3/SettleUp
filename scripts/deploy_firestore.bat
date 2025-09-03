@echo off
REM Deploy Firestore rules and indexes
REM This script requires Firebase CLI to be installed and authenticated

echo 🔥 Deploying Firestore configuration...

REM Check if Firebase CLI is installed
firebase --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Firebase CLI is not installed. Please install it first:
    echo npm install -g firebase-tools
    exit /b 1
)

REM Check if user is logged in
firebase projects:list >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Not logged in to Firebase. Please run:
    echo firebase login
    exit /b 1
)

REM Deploy Firestore rules
echo 📋 Deploying Firestore security rules...
firebase deploy --only firestore:rules

if %errorlevel% equ 0 (
    echo ✅ Firestore rules deployed successfully
) else (
    echo ❌ Failed to deploy Firestore rules
    exit /b 1
)

REM Deploy Firestore indexes
echo 📊 Deploying Firestore indexes...
firebase deploy --only firestore:indexes

if %errorlevel% equ 0 (
    echo ✅ Firestore indexes deployed successfully
) else (
    echo ❌ Failed to deploy Firestore indexes
    exit /b 1
)

echo 🎉 Firestore configuration deployed successfully!
echo.
echo 📝 Next steps:
echo 1. Verify rules in Firebase Console: https://console.firebase.google.com/project/settle-up-jf/firestore/rules
echo 2. Check indexes status: https://console.firebase.google.com/project/settle-up-jf/firestore/indexes
echo 3. Test the rules with your Flutter app