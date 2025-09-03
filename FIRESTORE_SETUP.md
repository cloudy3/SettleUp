# Firestore Setup Guide

This guide explains how to set up and deploy the Firestore database configuration for the expense sharing system.

## Files Overview

- `firestore.rules` - Security rules that control access to Firestore data
- `firestore.indexes.json` - Database indexes for efficient querying
- `firestore_schema.md` - Complete documentation of database schema
- `firebase.json` - Firebase project configuration
- `scripts/deploy_firestore.bat` - Windows deployment script
- `scripts/deploy_firestore.sh` - Unix/Linux deployment script

## Prerequisites

1. **Firebase CLI**: Install the Firebase CLI tools

   ```bash
   npm install -g firebase-tools
   ```

2. **Authentication**: Log in to Firebase

   ```bash
   firebase login
   ```

3. **Project Selection**: Ensure you're working with the correct project
   ```bash
   firebase use settle-up-jf
   ```

## Deployment

### Option 1: Using the Deployment Script (Recommended)

**Windows:**

```cmd
scripts\deploy_firestore.bat
```

**Unix/Linux/macOS:**

```bash
./scripts/deploy_firestore.sh
```

### Option 2: Manual Deployment

Deploy rules and indexes separately:

```bash
# Deploy security rules
firebase deploy --only firestore:rules

# Deploy indexes
firebase deploy --only firestore:indexes

# Or deploy both at once
firebase deploy --only firestore
```

## Security Rules Overview

The security rules implement the following access patterns:

### Users Collection

- Users can only read/write their own user document
- Authentication required for all operations

### Groups Collection

- Only group members can access group data
- Group creators have additional permissions for member management
- Invitation system allows email-based access for pending invites

### Expenses Collection

- Only group members can view expenses
- Only expense creators can modify their own expenses
- All group members can create new expenses

### Settlements Collection

- Only group members can view settlements
- Only the paying user can create settlements
- Settlements are immutable once created (audit trail)

### Balances Collection

- Only group members can read balance data
- Write access restricted to server-side operations only

## Database Indexes

The following indexes are configured for optimal query performance:

### Expenses

- `groupId` + `date` (descending) - For group expense lists
- `groupId` + `createdAt` (descending) - For recent expenses
- `paidBy` + `date` (descending) - For user's payment history

### Settlements

- `groupId` + `settledAt` (descending) - For group settlement history
- `fromUserId` + `settledAt` (descending) - For user's payment history
- `toUserId` + `settledAt` (descending) - For user's received payments

### Groups

- `memberIds` (array-contains) + `createdAt` (descending) - For user's groups

## Testing the Setup

After deployment, you can test the configuration:

1. **Firebase Console**: Visit the [Firebase Console](https://console.firebase.google.com/project/settle-up-jf/firestore) to verify:

   - Rules are deployed correctly
   - Indexes are building/built
   - Collections structure matches the schema

2. **Flutter App**: Run your Flutter app and test:
   - User authentication and data access
   - Group creation and member management
   - Expense creation and viewing
   - Real-time updates

## Troubleshooting

### Common Issues

1. **Permission Denied Errors**

   - Check that security rules are deployed
   - Verify user authentication status
   - Ensure user is a member of the group they're trying to access

2. **Slow Queries**

   - Check that required indexes are built
   - Monitor index build status in Firebase Console
   - Consider adding additional indexes for complex queries

3. **Deployment Failures**
   - Verify Firebase CLI is installed and up to date
   - Check that you're logged in: `firebase login`
   - Ensure correct project is selected: `firebase use settle-up-jf`

### Useful Commands

```bash
# Check current project
firebase projects:list

# Switch project
firebase use settle-up-jf

# Test security rules locally
firebase emulators:start --only firestore

# View deployment history
firebase projects:list
```

## Schema Updates

When updating the database schema:

1. Update `firestore_schema.md` with new structure
2. Modify `firestore.rules` if access patterns change
3. Add new indexes to `firestore.indexes.json` if needed
4. Deploy changes using the deployment script
5. Test thoroughly before releasing to production

## Performance Monitoring

Monitor your Firestore usage:

1. **Firebase Console**: Check usage metrics and performance
2. **Query Performance**: Monitor slow queries and add indexes as needed
3. **Security Rules**: Review rule evaluation metrics
4. **Costs**: Monitor read/write operations and storage usage

## Next Steps

After setting up Firestore:

1. Implement the service layer (GroupService, ExpenseService, etc.)
2. Create Flutter UI screens that interact with Firestore
3. Add real-time listeners for live updates
4. Implement offline support with local caching
5. Add comprehensive error handling
