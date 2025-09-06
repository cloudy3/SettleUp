import "package:firebase_auth/firebase_auth.dart";
import "package:flutter/material.dart";
import "package:settle_up/models/models.dart";
import "package:settle_up/services/services.dart";
import "add_expense_screen.dart";
import "expense_detail_screen.dart";
import "balance_screen.dart";

class GroupDetailScreen extends StatefulWidget {
  final String groupId;

  const GroupDetailScreen({super.key, required this.groupId});

  @override
  State<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends State<GroupDetailScreen>
    with SingleTickerProviderStateMixin {
  final GroupService _groupService = GroupService();
  final BalanceService _balanceService = BalanceService();
  final ExpenseService _expenseService = ExpenseService();
  final String? _currentUserId = FirebaseAuth.instance.currentUser?.uid;

  late TabController _tabController;
  Group? _group;
  List<Map<String, dynamic>> _members = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadGroupData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadGroupData() async {
    try {
      final group = await _groupService.getGroupById(widget.groupId);
      final members = await _groupService.getGroupMembers(widget.groupId);

      if (mounted) {
        setState(() {
          _group = group;
          _members = members;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error loading group: ${e.toString()}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text("Loading...")),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_group == null) {
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

    return Scaffold(
      appBar: AppBar(
        title: Text(_group!.name),
        actions: [
          PopupMenuButton<String>(
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'invite',
                child: Row(
                  children: [
                    Icon(Icons.person_add),
                    SizedBox(width: 8),
                    Text('Invite Members'),
                  ],
                ),
              ),
              if (_group!.createdBy == _currentUserId)
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit),
                      SizedBox(width: 8),
                      Text('Edit Group'),
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
            Tab(text: "Balances", icon: Icon(Icons.account_balance_wallet)),
            Tab(text: "Members", icon: Icon(Icons.group)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildExpensesTab(),
          _buildBalancesTab(),
          _buildMembersTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToAddExpense,
        label: const Text("Add Expense"),
        icon: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildExpensesTab() {
    return StreamBuilder<List<Expense>>(
      stream: _expenseService.getExpensesStream(widget.groupId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text("Error: ${snapshot.error}"),
              ],
            ),
          );
        }

        final expenses = snapshot.data ?? [];

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
            return _buildExpenseCard(expense);
          },
        );
      },
    );
  }

  Widget _buildBalancesTab() {
    return StreamBuilder<List<Balance>>(
      stream: _balanceService.getGroupBalancesStream(widget.groupId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text("Error: ${snapshot.error}"),
              ],
            ),
          );
        }

        final balances = snapshot.data ?? [];
        final currentUserBalance = balances.firstWhere(
          (b) => b.userId == _currentUserId,
          orElse: () => Balance.create(
            userId: _currentUserId!,
            groupId: widget.groupId,
            owes: {},
            owedBy: {},
          ),
        );

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildBalanceSummaryCard(currentUserBalance),
              const SizedBox(height: 16),
              _buildBalancesList(balances),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMembersTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount:
          _members.length + (_group!.pendingInvitations.isNotEmpty ? 1 : 0),
      itemBuilder: (context, index) {
        if (index < _members.length) {
          final member = _members[index];
          return _buildMemberCard(member);
        } else {
          return _buildPendingInvitationsCard();
        }
      },
    );
  }

  Widget _buildExpenseCard(Expense expense) {
    final payerName = _getMemberName(expense.paidBy);
    final amount = expense.amount;
    final userShare = expense.participantAmounts[_currentUserId] ?? 0.0;

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
            Text("Paid by $payerName • \$${amount.toStringAsFixed(2)}"),
            if (userShare > 0)
              Text(
                "Your share: \$${userShare.toStringAsFixed(2)}",
                style: TextStyle(
                  color: expense.paidBy == _currentUserId
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
        onTap: () => _navigateToExpenseDetail(expense),
      ),
    );
  }

  Widget _buildBalanceSummaryCard(Balance balance) {
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
                const Spacer(),
                TextButton.icon(
                  onPressed: () => _navigateToBalanceScreen(),
                  icon: const Icon(Icons.visibility, size: 18),
                  label: const Text('View All'),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
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
                          "You are owed \$${balance.netBalance.toStringAsFixed(2)}",
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
                          "You owe \$${(-balance.netBalance).toStringAsFixed(2)}",
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

  Widget _buildBalancesList(List<Balance> balances) {
    final currentUserBalance = balances.firstWhere(
      (b) => b.userId == _currentUserId,
      orElse: () => Balance.create(
        userId: _currentUserId!,
        groupId: widget.groupId,
        owes: {},
        owedBy: {},
      ),
    );

    final debts = <Widget>[];
    final credits = <Widget>[];

    // Add debts (what current user owes)
    currentUserBalance.owes.forEach((userId, amount) {
      if (amount > 0.01) {
        final memberName = _getMemberName(userId);
        debts.add(
          ListTile(
            leading: const Icon(Icons.arrow_upward, color: Colors.red),
            title: Text("You owe $memberName"),
            trailing: Text(
              "\$${amount.toStringAsFixed(2)}",
              style: const TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.w600,
              ),
            ),
            onTap: () => _showSettleUpDialog(userId, amount),
          ),
        );
      }
    });

    // Add credits (what others owe current user)
    currentUserBalance.owedBy.forEach((userId, amount) {
      if (amount > 0.01) {
        final memberName = _getMemberName(userId);
        credits.add(
          ListTile(
            leading: const Icon(Icons.arrow_downward, color: Colors.green),
            title: Text("$memberName owes you"),
            trailing: Text(
              "\$${amount.toStringAsFixed(2)}",
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

  Widget _buildMemberCard(Map<String, dynamic> member) {
    final isCreator = member['id'] == _group!.createdBy;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).primaryColor,
          child: Text(
            member['name'].isNotEmpty ? member['name'][0].toUpperCase() : "?",
            style: const TextStyle(color: Colors.white),
          ),
        ),
        title: Text(member['name'] ?? member['email']),
        subtitle: Text(member['email']),
        trailing: isCreator
            ? Chip(
                label: const Text("Creator"),
                backgroundColor: Theme.of(
                  context,
                ).primaryColor.withValues(alpha: 0.1),
              )
            : null,
      ),
    );
  }

  Widget _buildPendingInvitationsCard() {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        leading: const Icon(Icons.pending),
        title: Text(
          "Pending Invitations (${_group!.pendingInvitations.length})",
        ),
        children: _group!.pendingInvitations.map((invitation) {
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

  String _getMemberName(String userId) {
    final member = _members.firstWhere(
      (m) => m['id'] == userId,
      orElse: () => {'name': 'Unknown User'},
    );
    return member['name'] ?? 'Unknown User';
  }

  String _formatDate(DateTime date) {
    return "${date.month}/${date.day}/${date.year}";
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'invite':
        _showInviteMembersDialog();
        break;
      case 'edit':
        _showEditGroupDialog();
        break;
    }
  }

  void _showInviteMembersDialog() {
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
                  await _groupService.inviteMembers(
                    groupId: widget.groupId,
                    emails: [email],
                  );
                  if (mounted) {
                    navigator.pop();
                    scaffoldMessenger.showSnackBar(
                      SnackBar(
                        content: Text("Invitation sent to $email"),
                        backgroundColor: Colors.green,
                      ),
                    );
                    _loadGroupData(); // Refresh data
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

  void _showEditGroupDialog() {
    final nameController = TextEditingController(text: _group!.name);
    final descriptionController = TextEditingController(
      text: _group!.description,
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
                await _groupService.updateGroup(
                  groupId: widget.groupId,
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
                  _loadGroupData(); // Refresh data
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

  void _showSettleUpDialog(String userId, double amount) {
    final memberName = _getMemberName(userId);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Settle Up with $memberName"),
        content: Text(
          "Record a payment of \$${amount.toStringAsFixed(2)} to $memberName?",
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
                await _balanceService.recordSettlement(
                  groupId: widget.groupId,
                  fromUserId: _currentUserId!,
                  toUserId: userId,
                  amount: amount,
                );
                if (mounted) {
                  navigator.pop();
                  scaffoldMessenger.showSnackBar(
                    SnackBar(
                      content: Text("Settlement recorded with $memberName"),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
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

  Future<void> _navigateToAddExpense() async {
    if (_group == null || _members.isEmpty) {
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
        builder: (context) =>
            AddExpenseScreen(groupId: widget.groupId, groupMembers: _members),
      ),
    );

    if (result == true) {
      // Expense was added successfully, refresh data if needed
      _loadGroupData();
    }
  }

  Future<void> _navigateToExpenseDetail(Expense expense) async {
    if (_members.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Group members not loaded yet'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) =>
            ExpenseDetailScreen(expenseId: expense.id, groupMembers: _members),
      ),
    );

    if (result == true) {
      // Expense was updated or deleted, refresh data if needed
      _loadGroupData();
    }
  }

  Future<void> _navigateToBalanceScreen() async {
    if (_members.isEmpty) {
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
        builder: (context) =>
            BalanceScreen(groupId: widget.groupId, groupMembers: _members),
      ),
    );
  }
}
