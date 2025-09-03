#!/bin/bash

# Deploy Firestore rules and indexes
# This script requires Firebase CLI to be installed and authenticated

echo "🔥 Deploying Firestore configuration..."

# Check if Firebase CLI is installed
if ! command -v firebase &> /dev/null; then
    echo "❌ Firebase CLI is not installed. Please install it first:"
    echo "npm install -g firebase-tools"
    exit 1
fi

# Check if user is logged in
if ! firebase projects:list &> /dev/null; then
    echo "❌ Not logged in to Firebase. Please run:"
    echo "firebase login"
    exit 1
fi

# Deploy Firestore rules
echo "📋 Deploying Firestore security rules..."
firebase deploy --only firestore:rules

if [ $? -eq 0 ]; then
    echo "✅ Firestore rules deployed successfully"
else
    echo "❌ Failed to deploy Firestore rules"
    exit 1
fi

# Deploy Firestore indexes
echo "📊 Deploying Firestore indexes..."
firebase deploy --only firestore:indexes

if [ $? -eq 0 ]; then
    echo "✅ Firestore indexes deployed successfully"
else
    echo "❌ Failed to deploy Firestore indexes"
    exit 1
fi

echo "🎉 Firestore configuration deployed successfully!"
echo ""
echo "📝 Next steps:"
echo "1. Verify rules in Firebase Console: https://console.firebase.google.com/project/settle-up-jf/firestore/rules"
echo "2. Check indexes status: https://console.firebase.google.com/project/settle-up-jf/firestore/indexes"
echo "3. Test the rules with your Flutter app"