# Firestore Database Schema

This document defines the structure of all Firestore collections and their document schemas for the expense sharing system.

## Collections Overview

- `users` - User profile and settings
- `groups` - Expense sharing groups
- `expenses` - Individual expense records
- `settlements` - Payment records between users
- `balances` - Computed balance data (optional, can be calculated on-demand)

## Collection Schemas

### Users Collection (`/users/{userId}`)

```typescript
interface User {
  uid: string; // Firebase Auth UID (document ID)
  email: string; // User's email address
  name: string; // Display name
  avatarName: string; // Avatar identifier
  groups: string[]; // Array of group IDs user belongs to
  friends: string[]; // Array of friend user IDs
  onboardingCompleted: boolean; // Whether user completed onboarding
  createdAt: Timestamp; // Account creation timestamp
  updatedAt: Timestamp; // Last profile update timestamp
}
```

**Indexes:**

- Single field index on `email` (ascending)
- Single field index on `createdAt` (descending)

### Groups Collection (`/groups/{groupId}`)

```typescript
interface Group {
  id: string; // Document ID
  name: string; // Group display name
  description: string; // Group description
  createdBy: string; // Creator's user ID
  createdAt: Timestamp; // Creation timestamp
  updatedAt: Timestamp; // Last update timestamp
  memberIds: string[]; // Array of member user IDs
  pendingInvitations: GroupInvitation[]; // Pending invites
  totalExpenses: number; // Sum of all expenses
  currency: string; // Currency code (default: "USD")
  isActive: boolean; // Whether group is active
}

interface GroupInvitation {
  email: string; // Invited user's email
  invitedBy: string; // Inviter's user ID
  invitedAt: Timestamp; // Invitation timestamp
  status: "pending" | "accepted" | "declined";
  expiresAt: Timestamp; // Invitation expiry
}
```

**Indexes:**

- Composite index on `memberIds` (array-contains) + `createdAt` (descending)
- Single field index on `createdBy` (ascending)
- Single field index on `isActive` (ascending)

### Expenses Collection (`/expenses/{expenseId}`)

```typescript
interface Expense {
  id: string; // Document ID
  groupId: string; // Parent group ID
  description: string; // Expense description
  amount: number; // Total expense amount
  paidBy: string; // User ID who paid
  date: Timestamp; // Expense date
  createdAt: Timestamp; // Creation timestamp
  updatedAt: Timestamp; // Last update timestamp
  createdBy: string; // User ID who created expense
  split: ExpenseSplit; // Split configuration
  category: string; // Expense category (optional)
  receiptUrl?: string; // Receipt image URL (optional)
  isDeleted: boolean; // Soft delete flag
}

interface ExpenseSplit {
  type: "equal" | "custom" | "percentage"; // Split type
  participants: string[]; // User IDs involved in split
  shares: Record<string, number>; // userId -> amount or percentage
}
```

**Indexes:**

- Composite index on `groupId` (ascending) + `date` (descending)
- Composite index on `groupId` (ascending) + `createdAt` (descending)
- Composite index on `paidBy` (ascending) + `date` (descending)
- Single field index on `createdBy` (ascending)
- Single field index on `isDeleted` (ascending)

### Settlements Collection (`/settlements/{settlementId}`)

```typescript
interface Settlement {
  id: string; // Document ID
  groupId: string; // Parent group ID
  fromUserId: string; // User who paid
  toUserId: string; // User who received payment
  amount: number; // Settlement amount
  settledAt: Timestamp; // Settlement timestamp
  note?: string; // Optional settlement note
  method?: string; // Payment method (cash, venmo, etc.)
  confirmedBy?: string; // User ID who confirmed receipt
  confirmedAt?: Timestamp; // Confirmation timestamp
}
```

**Indexes:**

- Composite index on `groupId` (ascending) + `settledAt` (descending)
- Composite index on `fromUserId` (ascending) + `settledAt` (descending)
- Composite index on `toUserId` (ascending) + `settledAt` (descending)

### Balances Collection (`/balances/{balanceId}`) - Optional

This collection can be used for caching computed balances to improve performance.

```typescript
interface Balance {
  id: string; // Document ID (format: {groupId}_{userId})
  userId: string; // User ID
  groupId: string; // Group ID
  owes: Record<string, number>; // userId -> amount owed to them
  owedBy: Record<string, number>; // userId -> amount they owe you
  netBalance: number; // Overall net balance (positive = owed, negative = owes)
  lastCalculated: Timestamp; // When balance was last computed
}
```

**Indexes:**

- Composite index on `groupId` (ascending) + `userId` (ascending)
- Single field index on `lastCalculated` (descending)

## Security Rules Summary

### Access Patterns

1. **Users**: Can only access their own user document
2. **Groups**: Only group members can read/write group data
3. **Expenses**: Only group members can access expenses, only creators can modify
4. **Settlements**: Only group members can read, only payer can create
5. **Balances**: Only group members can read, computed server-side only

### Key Security Features

- Authentication required for all operations
- Group membership validation for all group-related data
- Expense modification restricted to creators
- Settlement creation restricted to the paying user
- Immutable settlements for audit trail
- Email-based invitation validation

## Data Validation Rules

### Required Fields

- **Users**: `uid`, `email`, `name`, `createdAt`
- **Groups**: `name`, `createdBy`, `createdAt`, `memberIds`
- **Expenses**: `groupId`, `description`, `amount`, `paidBy`, `date`, `createdBy`, `split`
- **Settlements**: `groupId`, `fromUserId`, `toUserId`, `amount`, `settledAt`

### Constraints

- Expense amounts must be positive numbers
- Split shares must sum to the total expense amount
- Group names must be 1-50 characters
- User emails must be valid email format
- Settlement amounts must be positive numbers

## Query Patterns

### Common Queries

1. **User's Groups**: `groups` where `memberIds` array-contains `userId`
2. **Group Expenses**: `expenses` where `groupId == groupId` order by `date desc`
3. **User's Expenses**: `expenses` where `paidBy == userId` order by `date desc`
4. **Group Settlements**: `settlements` where `groupId == groupId` order by `settledAt desc`
5. **User's Settlements**: `settlements` where `fromUserId == userId` or `toUserId == userId`

### Performance Considerations

- Use composite indexes for multi-field queries
- Implement pagination for large result sets
- Cache frequently accessed data in local storage
- Use Firestore listeners for real-time updates
- Consider denormalization for read-heavy operations
