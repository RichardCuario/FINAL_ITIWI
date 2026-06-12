#!/bin/bash

# Firebase Cloud Functions Deployment Script
# Run this from the firebase_functions directory

echo "🚀 Starting Firebase Cloud Functions Deployment..."
echo ""

# Step 1: Install dependencies
echo "📦 Installing npm dependencies..."
npm install

if [ $? -ne 0 ]; then
  echo "❌ Failed to install dependencies"
  exit 1
fi

echo "✅ Dependencies installed"
echo ""

# Step 2: Set Firebase configuration
echo "⚙️  Setting Firebase configuration..."

firebase functions:config:set supabase.url="https://jbhlbukxankrtcwhqoll.supabase.co"
firebase functions:config:set supabase.key="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImpiaGxidWt4YW5rcnRjd2hxb2xsIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3NDQ3MDE4OCwiZXhwIjoyMDkwMDQ2MTg4fQ.IzVTOEgPim0sNNZMzLtvLjJlf5HHZxVXYg9OCRnuEyI"

echo "✅ Firebase configuration set"
echo ""

# Step 3: Deploy functions
echo "🔄 Deploying Cloud Functions..."
firebase deploy --only functions

if [ $? -eq 0 ]; then
  echo ""
  echo "✅ Deployment successful!"
  echo ""
  echo "📋 Functions deployed:"
  echo "  - syncUserOnSignUp (triggered on user registration)"
  echo "  - updateUserLoginTime (callable from app)"
  echo ""
  echo "Next steps:"
  echo "1. Test by creating a new user in Firebase Auth"
  echo "2. Check Supabase users table to verify sync"
  echo "3. Refresh admin dashboard to see user count"
else
  echo "❌ Deployment failed"
  exit 1
fi
