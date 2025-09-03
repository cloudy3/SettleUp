# Requirements Document

## Introduction

The expense sharing system enables users to create groups, invite friends, track shared expenses, and manage settlements. Similar to Splitwise, this feature allows users to split bills fairly among group members and keep track of who owes whom. The system will use Firestore as the backend database and provide a seamless Flutter mobile experience.

## Requirements

### Requirement 1

**User Story:** As a user, I want to create expense groups, so that I can organize shared expenses with different sets of people.

#### Acceptance Criteria

1. WHEN a user taps "Create Group" THEN the system SHALL display a group creation form
2. WHEN a user enters a group name and description THEN the system SHALL validate the input is not empty
3. WHEN a user submits valid group details THEN the system SHALL create a new group in Firestore with the user as the creator
4. WHEN a group is created THEN the system SHALL automatically add the creator as the first member
5. WHEN a group is successfully created THEN the system SHALL navigate to the group detail screen

### Requirement 2

**User Story:** As a group creator, I want to invite friends to join my group, so that we can share expenses together.

#### Acceptance Criteria

1. WHEN a user is in a group they created THEN the system SHALL display an "Invite Members" option
2. WHEN a user taps "Invite Members" THEN the system SHALL display options to invite by email or username
3. WHEN a user enters valid contact information THEN the system SHALL send an invitation to the specified person
4. WHEN an invitation is sent THEN the system SHALL store the pending invitation in Firestore
5. WHEN an invited user accepts the invitation THEN the system SHALL add them to the group members list
6. WHEN an invited user declines the invitation THEN the system SHALL remove the pending invitation

### Requirement 3

**User Story:** As a group member, I want to add expenses to the group, so that we can track what money was spent and by whom.

#### Acceptance Criteria

1. WHEN a group member taps "Add Expense" THEN the system SHALL display an expense creation form
2. WHEN a user enters expense details (amount, description, date) THEN the system SHALL validate the amount is positive and description is not empty
3. WHEN a user selects who paid for the expense THEN the system SHALL allow selection from group members
4. WHEN a user selects how to split the expense THEN the system SHALL provide options for equal split, custom amounts, or percentages
5. WHEN a user submits a valid expense THEN the system SHALL save it to Firestore with proper member associations
6. WHEN an expense is added THEN the system SHALL update the group's expense list and recalculate balances

### Requirement 4

**User Story:** As a group member, I want to see how expenses are split among members, so that I understand who owes what to whom.

#### Acceptance Criteria

1. WHEN a user views a group THEN the system SHALL display a list of all expenses in chronological order
2. WHEN a user taps on an expense THEN the system SHALL show detailed split information for that expense
3. WHEN viewing expense details THEN the system SHALL show who paid, how much each person owes, and their share amount
4. WHEN multiple expenses exist THEN the system SHALL calculate net balances between all members
5. WHEN balances are calculated THEN the system SHALL show simplified debts (who owes whom and how much)

### Requirement 5

**User Story:** As a group member, I want to see my overall balance with each person, so that I know how much I owe or am owed.

#### Acceptance Criteria

1. WHEN a user views a group THEN the system SHALL display a balance summary section
2. WHEN displaying balances THEN the system SHALL show net amounts owed to or by the current user
3. WHEN a user owes money THEN the system SHALL display amounts in red with "You owe" text
4. WHEN a user is owed money THEN the system SHALL display amounts in green with "Owes you" text
5. WHEN balances are zero THEN the system SHALL display "Settled up" status
6. WHEN balances change THEN the system SHALL update the display in real-time

### Requirement 6

**User Story:** As a group member, I want to settle up debts, so that I can mark payments as complete and clear balances.

#### Acceptance Criteria

1. WHEN a user has outstanding debts THEN the system SHALL display "Settle Up" options next to each debt
2. WHEN a user taps "Settle Up" THEN the system SHALL display a settlement confirmation dialog
3. WHEN a user confirms a settlement THEN the system SHALL create a settlement record in Firestore
4. WHEN a settlement is recorded THEN the system SHALL update the balances to reflect the payment
5. WHEN both parties are online THEN the system SHALL notify the recipient of the settlement
6. WHEN a settlement is complete THEN the system SHALL update the UI to show the new balance state

### Requirement 7

**User Story:** As a user, I want to receive real-time updates about group activities, so that I stay informed about new expenses and settlements.

#### Acceptance Criteria

1. WHEN another member adds an expense THEN the system SHALL update the current user's view in real-time
2. WHEN another member settles a debt THEN the system SHALL update balances immediately for all affected users
3. WHEN a user is invited to a group THEN the system SHALL send them a notification
4. WHEN group data changes THEN the system SHALL use Firestore listeners to push updates to all connected clients
5. WHEN the app is in the background THEN the system SHALL still receive and queue important updates

### Requirement 8

**User Story:** As a user, I want to edit or delete expenses I created, so that I can correct mistakes or remove incorrect entries.

#### Acceptance Criteria

1. WHEN a user views an expense they created THEN the system SHALL display edit and delete options
2. WHEN a user taps "Edit Expense" THEN the system SHALL display the expense form pre-filled with current data
3. WHEN a user modifies expense details THEN the system SHALL validate the changes and update Firestore
4. WHEN an expense is edited THEN the system SHALL recalculate all affected balances
5. WHEN a user taps "Delete Expense" THEN the system SHALL display a confirmation dialog
6. WHEN a user confirms deletion THEN the system SHALL remove the expense and update all balances accordingly
