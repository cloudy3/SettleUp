import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/services.dart';
import 'settle_up_screen.dart';
import 'settlement_history_screen.dart';

class BalanceScreen extends StatefulWidget {
  final String groupId;
  final List<Map<String, dynamic>> groupMembers;

  const BalanceScreen({
    super.key,
    required this.groupId,
    required this.groupMembers,
  });

  @override
  State<BalanceScreen> createState() => _BalanceScreenState();
}

class _BalanceScreenState extends State<BalanceScreen> {
  final BalanceService _balanceService = BalanceService();
  final String? _currentUserId = FirebaseAuth.instance.currentUser?.uid;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Balances'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: _showSettlementHistory,
            tooltip: 'Settlement History',
          ),
        ],
      ),
      body: StreamBuilder<List<Balance>>(
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
                  Text('Error: ${snapshot.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => setState(() {}),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final balances = snapshot.data ?? [];
          return _buildBalancesList(balances);
        },
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

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildOverallBalanceCard(currentUserBalance),
          const SizedBox(height: 24),
          _buildYouOweSection(currentUserBalance),
          const SizedBox(height: 24),
          _buildYouAreOwedSection(currentUserBalance),
          const SizedBox(height: 24),
          _buildAllMembersBalances(balances),
        ],
      ),
    );
  }

  Widget _buildOverallBalanceCard(Balance balance) {
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
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text(
                  'Your Overall Balance',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (balance.isSettledUp)
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 16,
                ),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.green.withValues(alpha: 0.3),
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green, size: 24),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'You are all settled up!',
                        style: TextStyle(
                          color: Colors.green,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 16,
                ),
                decoration: BoxDecoration(
                  color: balance.netBalance > 0
                      ? Colors.green.withValues(alpha: 0.1)
                      : Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: balance.netBalance > 0
                        ? Colors.green.withValues(alpha: 0.3)
                        : Colors.red.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      balance.netBalance > 0
                          ? Icons.trending_up
                          : Icons.trending_down,
                      color: balance.netBalance > 0 ? Colors.green : Colors.red,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        balance.netBalance > 0
                            ? 'You are owed \$${balance.netBalance.toStringAsFixed(2)}'
                            : 'You owe \$${(-balance.netBalance).toStringAsFixed(2)}',
                        style: TextStyle(
                          color: balance.netBalance > 0
                              ? Colors.green
                              : Colors.red,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildYouOweSection(Balance balance) {
    final debts = balance.owes.entries
        .where((entry) => entry.value > 0.01)
        .toList();

    if (debts.isEmpty) {
      return _buildEmptySection(
        'You Owe',
        'You don\'t owe anyone money',
        Icons.check_circle,
        Colors.green,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'You Owe',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: Colors.red,
          ),
        ),
        const SizedBox(height: 8),
        Card(
          child: Column(
            children: debts.map((entry) {
              final memberName = _getMemberName(entry.key);
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.red,
                  child: Text(
                    memberName.isNotEmpty ? memberName[0].toUpperCase() : '?',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                title: Text('You owe $memberName'),
                subtitle: Text('Tap to settle up'),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '\$${entry.value.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios, size: 12),
                  ],
                ),
                onTap: () => _navigateToSettleUp(entry.key, entry.value),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildYouAreOwedSection(Balance balance) {
    final credits = balance.owedBy.entries
        .where((entry) => entry.value > 0.01)
        .toList();

    if (credits.isEmpty) {
      return _buildEmptySection(
        'You Are Owed',
        'No one owes you money',
        Icons.check_circle,
        Colors.green,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'You Are Owed',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: Colors.green,
          ),
        ),
        const SizedBox(height: 8),
        Card(
          child: Column(
            children: credits.map((entry) {
              final memberName = _getMemberName(entry.key);
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.green,
                  child: Text(
                    memberName.isNotEmpty ? memberName[0].toUpperCase() : '?',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                title: Text('$memberName owes you'),
                subtitle: const Text('Waiting for payment'),
                trailing: Text(
                  '\$${entry.value.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildAllMembersBalances(List<Balance> balances) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'All Member Balances',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Card(
          child: Column(
            children: balances.map((balance) {
              final memberName = _getMemberName(balance.userId);
              final isCurrentUser = balance.userId == _currentUserId;

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: isCurrentUser
                      ? Theme.of(context).primaryColor
                      : balance.netBalance > 0
                      ? Colors.green
                      : balance.netBalance < 0
                      ? Colors.red
                      : Colors.grey,
                  child: Text(
                    memberName.isNotEmpty ? memberName[0].toUpperCase() : '?',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                title: Text(
                  isCurrentUser ? '$memberName (You)' : memberName,
                  style: TextStyle(
                    fontWeight: isCurrentUser
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                ),
                subtitle: Text(
                  balance.isSettledUp
                      ? 'Settled up'
                      : balance.netBalance > 0
                      ? 'Gets back \$${balance.netBalance.toStringAsFixed(2)}'
                      : 'Owes \$${(-balance.netBalance).toStringAsFixed(2)}',
                ),
                trailing: balance.isSettledUp
                    ? const Icon(Icons.check_circle, color: Colors.green)
                    : Icon(
                        balance.netBalance > 0
                            ? Icons.trending_up
                            : Icons.trending_down,
                        color: balance.netBalance > 0
                            ? Colors.green
                            : Colors.red,
                      ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptySection(
    String title,
    String message,
    IconData icon,
    Color color,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 12),
                Text(message),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _getMemberName(String userId) {
    final member = widget.groupMembers.firstWhere(
      (m) => m['id'] == userId,
      orElse: () => {'name': 'Unknown User'},
    );
    return member['name'] ?? 'Unknown User';
  }

  void _navigateToSettleUp(String userId, double amount) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => SettleUpScreen(
          groupId: widget.groupId,
          toUserId: userId,
          amount: amount,
          toUserName: _getMemberName(userId),
        ),
      ),
    );

    if (result == true && mounted) {
      // Settlement was recorded, show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Settlement recorded with ${_getMemberName(userId)}'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _showSettlementHistory() async {
    // Get group name for the screen title
    String groupName = 'Group';
    try {
      final groupService = GroupService();
      final group = await groupService.getGroupById(widget.groupId);
      if (group != null) {
        groupName = group.name;
      }
    } catch (e) {
      // Use default name if we can't get the group name
    }

    if (mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => SettlementHistoryScreen(
            groupId: widget.groupId,
            groupMembers: widget.groupMembers,
            groupName: groupName,
          ),
        ),
      );
    }
  }
}
