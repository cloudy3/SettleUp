import "package:firebase_auth/firebase_auth.dart";
import "package:flutter/material.dart";
import "package:provider/provider.dart";
import "package:settle_up/models/models.dart";
import "package:settle_up/providers/providers.dart";
import "add_expense_screen.dart";
import "expense_detail_screen.dart";
import "member_management_screen.dart";

class GroupDetailScreen extends StatefulWidget {
  final String groupId;

  const GroupDetailScreen({super.key, required this.groupId});

  @override
  State<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends State<GroupDetailScreen>
    with SingleTickerProviderStateMixin {
  final String? _currentUserId = FirebaseAuth.instance.currentUser?.uid;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => GroupProvider(widget.groupId),
      child: Consumer2<GroupProvider, OfflineProvider>(
        builder: (context, groupProvider, offlineProvider, child) {
          if (groupProvider.isLoadingGroup) {
            return Scaffold(
              appBar: AppBar(title: const Text("Loading...")),
              body: const Center(child: CircularProgressIndicator()),
            );
          }

          if (groupProvider.group == null) {
            return Scaffold(
              appBar: AppBar(title: const Text("Group Not Found")),
              body: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error, size: 64, color: Colors.red),
                    SizedBox(height: 16),
                    Text("Group not found or you don't have access"),
                  ],
                ),
              ),
            );
          }

          final group = groupProvider.group!;

          return Scaffold(
            appBar: AppBar(
              title: Row(
                children: [
                  Text(group.name),
                  if (!offlineProvider.isOnline) ...[
                    const SizedBox(width: 8),
                    Icon(Icons.wifi_off, size: 16, color: Colors.grey.shade300),
                  ],
                ],
              ),
              actions: [
                PopupMenuButton<String>(
                  onSelected: (action) =>
                      _handleMenuAction(action, groupProvider, offlineProvider),
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'invite',
                      enabled: offlineProvider.isOnline,
                      child: Row(
                        children: [
                          Icon(
                            Icons.person_add,
                            color: offlineProvider.isOnline
                                ? null
                                : Colors.grey,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Invite Members',
                            style: TextStyle(
                              color: offlineProvider.isOnline
                                  ? null
                                  : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (group.createdBy == _currentUserId)
                      PopupMenuItem(
                        value: 'edit',
                        enabled: offlineProvider.isOnline,
                        child: Row(
                          children: [
                            Icon(
                              Icons.edit,
                              color: offlineProvider.isOnline
                                  ? null
                                  : Colors.grey,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Edit Group',
                              style: TextStyle(
                                color: offlineProvider.isOnline
                                    ? null
                                    : Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
              bottom: TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: "Expenses", icon: Icon(Icons.receipt)),
                  Tab(
                    text: "Balances",
                    icon: Icon(Icons.account_balance_wallet),
                  ),
                  Tab(text: "Members", icon: Icon(Icons.group)),
                ],
              ),
            ),
            body: Column(
              children: [
                if (!offlineProvider.isOnline)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    color: Colors.orange.shade100,
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 16,
                          color: Colors.orange.shade700,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Viewing cached data. Changes will sync when online.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.orange.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _ExpensesTab(
                        groupProvider: groupProvider,
                        currentUserId: _currentUserId!,
                        isOnline: offlineProvider.isOnline,
                      ),
                      _BalancesTab(
                        groupProvider: groupProvider,
                        currentUserId: _currentUserId!,
                        groupId: widget.groupId,
                        isOnline: offlineProvider.isOnline,
                      ),
                      _MembersTab(
                        groupProvider: groupProvider,
                        isOnline: offlineProvider.isOnline,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            floatingActionButton: FloatingActionButton.extended(
              onPressed: offlineProvider.isOnline
                  ? () => _navigateToAddExpense(groupProvider)
                  : () => _showOfflineMessage(context),
              label: const Text("Add Expense"),
              icon: const Icon(Icons.add),
              backgroundColor: offlineProvider.isOnline
                  ? null
                  : Colors.grey.shade400,
            ),
          );
        },
      ),
    );
  }

  void _handleMenuAction(
    String action,
    GroupProvider groupProvider,
    OfflineProvider offlineProvider,
  ) {
    switch (action) {
      case 'invite':
        _showInviteMembersDialog(groupProvider);
        break;
      case 'edit':
        _showEditGroupDialog(groupProvider);
        break;
    }
  }

  void _showOfflineMessage(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('This action requires an internet connection'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _showInviteMembersDialog(GroupProvider groupProvider) {
    final emailController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Invite Members"),
        content: TextField(
          controller: emailController,
          decoration: const InputDecoration(
            labelText: "Email Address",
            hintText: "Enter email to invite",
          ),
          keyboardType: TextInputType.emailAddress,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              final email = emailController.text.trim();
              if (email.isNotEmpty) {
                final navigator = Navigator.of(context);
                final scaffoldMessenger = ScaffoldMessenger.of(context);
                try {
                  await groupProvider.inviteMembers([email]);
                  if (mounted) {
                    navigator.pop();
                    scaffoldMessenger.showSnackBar(
                      SnackBar(
                        content: Text("Invitation sent to $email"),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    scaffoldMessenger.showSnackBar(
                      SnackBar(
                        content: Text("Failed to send invitation: $e"),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              }
            },
            child: const Text("Send Invite"),
          ),
        ],
      ),
    );
  }

  void _showEditGroupDialog(GroupProvider groupProvider) {
    final group = groupProvider.group!;
    final nameController = TextEditingController(text: group.name);
    final descriptionController = TextEditingController(
      text: group.description,
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Edit Group"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: "Group Name"),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(labelText: "Description"),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              final navigator = Navigator.of(context);
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              try {
                await groupProvider.updateGroup(
                  name: nameController.text.trim(),
                  description: descriptionController.text.trim(),
                );
                if (mounted) {
                  navigator.pop();
                  scaffoldMessenger.showSnackBar(
                    const SnackBar(
                      content: Text("Group updated successfully"),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  scaffoldMessenger.showSnackBar(
                    SnackBar(
                      content: Text("Failed to update group: $e"),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  Future<void> _navigateToAddExpense(GroupProvider groupProvider) async {
    if (groupProvider.group == null || groupProvider.members.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Group data not loaded yet'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => AddExpenseScreen(
          groupId: widget.groupId,
          groupMembers: groupProvider.members,
        ),
      ),
    );

    if (result == true) {
      // Expense was added successfully - real-time updates will handle UI refresh
    }
  }
}

// Separate widget for expenses tab with real-time updates
class _ExpensesTab extends StatelessWidget {
  final GroupProvider groupProvider;
  final String currentUserId;
  final bool isOnline;

  const _ExpensesTab({
    required this.groupProvider,
    required this.currentUserId,
    required this.isOnline,
  });

  @override
  Widget build(BuildContext context) {
    if (groupProvider.isLoadingExpenses) {
      return const Center(child: CircularProgressIndicator());
    }

    final expenses = groupProvider.expenses;

    if (expenses.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long, size: 80, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              "No expenses yet",
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              "Add your first expense to get started",
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: expenses.length,
      itemBuilder: (context, index) {
        final expense = expenses[index];
        return _ExpenseCard(
          expense: expense,
          groupProvider: groupProvider,
          currentUserId: currentUserId,
        );
      },
    );
  }
}

// Separate widget for balances tab with real-time updates
class _BalancesTab extends StatelessWidget {
  final GroupProvider groupProvider;
  final String currentUserId;
  final String groupId;
  final bool isOnline;

  const _BalancesTab({
    required this.groupProvider,
    required this.currentUserId,
    required this.groupId,
    required this.isOnline,
  });

  @override
  Widget build(BuildContext context) {
    if (groupProvider.isLoadingBalances) {
      return const Center(child: CircularProgressIndicator());
    }

    final currentUserBalance =
        groupProvider.getCurrentUserBalance(currentUserId) ??
        Balance.create(
          userId: currentUserId,
          groupId: groupId,
          owes: {},
          owedBy: {},
        );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _BalanceSummaryCard(balance: currentUserBalance),
          const SizedBox(height: 16),
          _BalancesList(
            currentUserBalance: currentUserBalance,
            groupProvider: groupProvider,
          ),
        ],
      ),
    );
  }
}

// Separate widget for members tab
class _MembersTab extends StatelessWidget {
  final GroupProvider groupProvider;
  final bool isOnline;

  const _MembersTab({required this.groupProvider, required this.isOnline});

  @override
  Widget build(BuildContext context) {
    final members = groupProvider.members;
    final group = groupProvider.group!;
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final isCreator = group.createdBy == currentUserId;

    return Column(
      children: [
        // Header with manage members button
        if (isOnline)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            child: ElevatedButton.icon(
              onPressed: () => _navigateToMemberManagement(context, group),
              icon: const Icon(Icons.settings),
              label: const Text('Manage Members'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
          ),

        // Members list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount:
                members.length + (group.pendingInvitations.isNotEmpty ? 1 : 0),
            itemBuilder: (context, index) {
              if (index < members.length) {
                final member = members[index];
                return _MemberCard(
                  member: member,
                  group: group,
                  showRemoveOption: isCreator && isOnline,
                );
              } else {
                return _PendingInvitationsCard(group: group);
              }
            },
          ),
        ),
      ],
    );
  }

  Future<void> _navigateToMemberManagement(
    BuildContext context,
    Group group,
  ) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) =>
            MemberManagementScreen(groupId: group.id, group: group),
      ),
    );

    // If changes were made, the GroupProvider will automatically update via real-time listeners
    if (result == true) {
      // Optional: Show a success message or refresh indicator
    }
  }
}

// Individual expense card widget
class _ExpenseCard extends StatelessWidget {
  final Expense expense;
  final GroupProvider groupProvider;
  final String currentUserId;

  const _ExpenseCard({
    required this.expense,
    required this.groupProvider,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    final payerName = groupProvider.getMemberName(expense.paidBy);
    final userShare = expense.participantAmounts[currentUserId] ?? 0.0;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).primaryColor,
          child: Text(
            payerName.isNotEmpty ? payerName[0].toUpperCase() : "?",
            style: const TextStyle(color: Colors.white),
          ),
        ),
        title: Text(expense.description),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Paid by $payerName • \${expense.amount.toStringAsFixed(2)}"),
            if (userShare > 0)
              Text(
                "Your share: \${userShare.toStringAsFixed(2)}",
                style: TextStyle(
                  color: expense.paidBy == currentUserId
                      ? Colors.green
                      : Colors.orange,
                ),
              ),
          ],
        ),
        trailing: Text(
          "${expense.date.month}/${expense.date.day}",
          style: Theme.of(context).textTheme.bodySmall,
        ),
        onTap: () => _navigateToExpenseDetail(context, expense, groupProvider),
      ),
    );
  }

  Future<void> _navigateToExpenseDetail(
    BuildContext context,
    Expense expense,
    GroupProvider groupProvider,
  ) async {
    if (groupProvider.members.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Group members not loaded yet'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ExpenseDetailScreen(
          expenseId: expense.id,
          groupMembers: groupProvider.members,
        ),
      ),
    );
  }
}

// Balance summary card widget
class _BalanceSummaryCard extends StatelessWidget {
  final Balance balance;

  const _BalanceSummaryCard({required this.balance});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.account_balance_wallet,
                  color: Theme.of(context).primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  "Your Balance",
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (balance.isSettledUp)
              const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green),
                  SizedBox(width: 8),
                  Text(
                    "You are all settled up!",
                    style: TextStyle(color: Colors.green, fontSize: 16),
                  ),
                ],
              )
            else
              Column(
                children: [
                  if (balance.netBalance > 0)
                    Row(
                      children: [
                        const Icon(Icons.arrow_downward, color: Colors.green),
                        const SizedBox(width: 8),
                        Text(
                          "You are owed \${balance.netBalance.toStringAsFixed(2)}",
                          style: const TextStyle(
                            color: Colors.green,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    )
                  else
                    Row(
                      children: [
                        const Icon(Icons.arrow_upward, color: Colors.red),
                        const SizedBox(width: 8),
                        Text(
                          "You owe \${(-balance.netBalance).toStringAsFixed(2)}",
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

// Balances list widget
class _BalancesList extends StatelessWidget {
  final Balance currentUserBalance;
  final GroupProvider groupProvider;

  const _BalancesList({
    required this.currentUserBalance,
    required this.groupProvider,
  });

  @override
  Widget build(BuildContext context) {
    final debts = <Widget>[];
    final credits = <Widget>[];

    // Add debts (what current user owes)
    currentUserBalance.owes.forEach((userId, amount) {
      if (amount > 0.01) {
        final memberName = groupProvider.getMemberName(userId);
        debts.add(
          ListTile(
            leading: const Icon(Icons.arrow_upward, color: Colors.red),
            title: Text("You owe $memberName"),
            trailing: Text(
              "\${amount.toStringAsFixed(2)}",
              style: const TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.w600,
              ),
            ),
            onTap: () => _showSettleUpDialog(
              context,
              userId,
              amount,
              memberName,
              groupProvider,
            ),
          ),
        );
      }
    });

    // Add credits (what others owe current user)
    currentUserBalance.owedBy.forEach((userId, amount) {
      if (amount > 0.01) {
        final memberName = groupProvider.getMemberName(userId);
        credits.add(
          ListTile(
            leading: const Icon(Icons.arrow_downward, color: Colors.green),
            title: Text("$memberName owes you"),
            trailing: Text(
              "\${amount.toStringAsFixed(2)}",
              style: const TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
      }
    });

    if (debts.isEmpty && credits.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: Text("No outstanding balances")),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (debts.isNotEmpty) ...[
          Text(
            "You Owe",
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          Card(child: Column(children: debts)),
          const SizedBox(height: 16),
        ],
        if (credits.isNotEmpty) ...[
          Text(
            "You Are Owed",
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          Card(child: Column(children: credits)),
        ],
      ],
    );
  }

  void _showSettleUpDialog(
    BuildContext context,
    String userId,
    double amount,
    String memberName,
    GroupProvider groupProvider,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Settle Up with $memberName"),
        content: Text(
          "Record a payment of \${amount.toStringAsFixed(2)} to $memberName?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              final navigator = Navigator.of(context);
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              try {
                final currentUserId = FirebaseAuth.instance.currentUser?.uid;
                if (currentUserId == null) return;
                await groupProvider.recordSettlement(
                  fromUserId: currentUserId,
                  toUserId: userId,
                  amount: amount,
                );
                if (context.mounted) {
                  navigator.pop();
                  scaffoldMessenger.showSnackBar(
                    SnackBar(
                      content: Text("Settlement recorded with $memberName"),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  scaffoldMessenger.showSnackBar(
                    SnackBar(
                      content: Text("Failed to record settlement: $e"),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text("Record Payment"),
          ),
        ],
      ),
    );
  }
}

// Member card widget
class _MemberCard extends StatelessWidget {
  final Map<String, dynamic> member;
  final Group group;
  final bool showRemoveOption;

  const _MemberCard({
    required this.member,
    required this.group,
    this.showRemoveOption = false,
  });

  @override
  Widget build(BuildContext context) {
    final isCreator = member['id'] == group.createdBy;
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final isCurrentUser = member['id'] == currentUserId;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).primaryColor,
          child: Text(
            (member['name']?.isNotEmpty == true
                    ? member['name'][0]
                    : member['email'][0])
                .toUpperCase(),
            style: const TextStyle(color: Colors.white),
          ),
        ),
        title: Text(member['name'] ?? member['email']),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(member['email']),
            if (isCreator)
              Container(
                margin: const EdgeInsets.only(top: 4),
                child: Chip(
                  label: const Text("Creator", style: TextStyle(fontSize: 12)),
                  backgroundColor: Theme.of(
                    context,
                  ).primaryColor.withValues(alpha: 0.1),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
          ],
        ),
        trailing: (showRemoveOption && !isCreator && !isCurrentUser)
            ? IconButton(
                icon: const Icon(
                  Icons.remove_circle_outline,
                  color: Colors.red,
                ),
                onPressed: () => _showRemoveConfirmation(context, member),
                tooltip: 'Remove member',
              )
            : null,
      ),
    );
  }

  void _showRemoveConfirmation(
    BuildContext context,
    Map<String, dynamic> member,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Member'),
        content: Text(
          'Are you sure you want to remove ${member['name'] ?? member['email']} from this group?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Navigate to member management for removal
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) =>
                      MemberManagementScreen(groupId: group.id, group: group),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }
}

// Pending invitations card widget
class _PendingInvitationsCard extends StatelessWidget {
  final Group group;

  const _PendingInvitationsCard({required this.group});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        leading: const Icon(Icons.pending),
        title: Text("Pending Invitations (${group.pendingInvitations.length})"),
        children: group.pendingInvitations.map((invitation) {
          return ListTile(
            leading: const Icon(Icons.email),
            title: Text(invitation.email),
            subtitle: Text("Invited ${_formatDate(invitation.invitedAt)}"),
            trailing: Text(invitation.status.name.toUpperCase()),
          );
        }).toList(),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return "${date.month}/${date.day}/${date.year}";
  }
}
