import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/services.dart';

class ExpenseAuditScreen extends StatefulWidget {
  final String expenseId;
  final List<Map<String, dynamic>> groupMembers;

  const ExpenseAuditScreen({
    super.key,
    required this.expenseId,
    required this.groupMembers,
  });

  @override
  State<ExpenseAuditScreen> createState() => _ExpenseAuditScreenState();
}

class _ExpenseAuditScreenState extends State<ExpenseAuditScreen> {
  final ExpenseService _expenseService = ExpenseService();
  List<ExpenseAudit> _auditTrail = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAuditTrail();
  }

  Future<void> _loadAuditTrail() async {
    try {
      final audits = await _expenseService.getExpenseAuditTrail(
        widget.expenseId,
      );
      if (mounted) {
        setState(() {
          _auditTrail = audits;
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
            content: Text('Error loading audit trail: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Expense History')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _auditTrail.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No history available'),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _auditTrail.length,
              itemBuilder: (context, index) {
                final audit = _auditTrail[index];
                return _buildAuditItem(audit);
              },
            ),
    );
  }

  Widget _buildAuditItem(ExpenseAudit audit) {
    final performerName = _getMemberName(audit.performedBy);
    final actionIcon = _getActionIcon(audit.action);
    final actionColor = _getActionColor(audit.action);
    final actionText = _getActionText(audit.action);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: actionColor.withValues(alpha: 0.2),
                  child: Icon(actionIcon, color: actionColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        actionText,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        'by $performerName',
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                    ],
                  ),
                ),
                Text(
                  _formatDateTime(audit.performedAt),
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
            if (audit.action == ExpenseAuditAction.updated) ...[
              const SizedBox(height: 16),
              _buildChangeDetails(audit),
            ],
            if (audit.reason != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.note, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        audit.reason!,
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildChangeDetails(ExpenseAudit audit) {
    if (audit.previousData == null || audit.newData == null) {
      return const SizedBox.shrink();
    }

    final changes = <Widget>[];
    final previous = audit.previousData!;
    final updated = audit.newData!;

    // Check for description changes
    if (previous['description'] != updated['description']) {
      changes.add(
        _buildChangeItem(
          'Description',
          previous['description'] ?? '',
          updated['description'] ?? '',
        ),
      );
    }

    // Check for amount changes
    if (previous['amount'] != updated['amount']) {
      changes.add(
        _buildChangeItem(
          'Amount',
          '\$${(previous['amount'] ?? 0.0).toStringAsFixed(2)}',
          '\$${(updated['amount'] ?? 0.0).toStringAsFixed(2)}',
        ),
      );
    }

    // Check for payer changes
    if (previous['paidBy'] != updated['paidBy']) {
      changes.add(
        _buildChangeItem(
          'Paid by',
          _getMemberName(previous['paidBy'] ?? ''),
          _getMemberName(updated['paidBy'] ?? ''),
        ),
      );
    }

    // Check for date changes
    if (previous['date'] != updated['date']) {
      final prevDate = (previous['date'] as Timestamp?)?.toDate();
      final newDate = (updated['date'] as Timestamp?)?.toDate();
      if (prevDate != null && newDate != null) {
        changes.add(
          _buildChangeItem('Date', _formatDate(prevDate), _formatDate(newDate)),
        );
      }
    }

    // Check for split changes
    final prevSplit = previous['split'] as Map<String, dynamic>?;
    final newSplit = updated['split'] as Map<String, dynamic>?;
    if (prevSplit != null && newSplit != null) {
      if (prevSplit['type'] != newSplit['type']) {
        changes.add(
          _buildChangeItem(
            'Split type',
            _getSplitTypeLabel(prevSplit['type'] ?? 'equal'),
            _getSplitTypeLabel(newSplit['type'] ?? 'equal'),
          ),
        );
      }
    }

    if (changes.isEmpty) {
      return const Text('No specific changes detected');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Changes:',
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        ...changes,
      ],
    );
  }

  Widget _buildChangeItem(String field, String oldValue, String newValue) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$field:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.remove, size: 16, color: Colors.red[400]),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        oldValue,
                        style: TextStyle(
                          color: Colors.red[600],
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(Icons.add, size: 16, color: Colors.green[400]),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        newValue,
                        style: TextStyle(
                          color: Colors.green[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getMemberName(String userId) {
    final member = widget.groupMembers.firstWhere(
      (m) => m['id'] == userId,
      orElse: () => {'name': 'Unknown User'},
    );
    return member['name'] ?? 'Unknown User';
  }

  IconData _getActionIcon(ExpenseAuditAction action) {
    switch (action) {
      case ExpenseAuditAction.created:
        return Icons.add_circle;
      case ExpenseAuditAction.updated:
        return Icons.edit;
      case ExpenseAuditAction.deleted:
        return Icons.delete;
    }
  }

  Color _getActionColor(ExpenseAuditAction action) {
    switch (action) {
      case ExpenseAuditAction.created:
        return Colors.green;
      case ExpenseAuditAction.updated:
        return Colors.blue;
      case ExpenseAuditAction.deleted:
        return Colors.red;
    }
  }

  String _getActionText(ExpenseAuditAction action) {
    switch (action) {
      case ExpenseAuditAction.created:
        return 'Expense created';
      case ExpenseAuditAction.updated:
        return 'Expense updated';
      case ExpenseAuditAction.deleted:
        return 'Expense deleted';
    }
  }

  String _getSplitTypeLabel(String type) {
    switch (type) {
      case 'equal':
        return 'Equal Split';
      case 'custom':
        return 'Custom Split';
      case 'percentage':
        return 'Percentage Split';
      default:
        return 'Unknown Split';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.month}/${dateTime.day}/${dateTime.year} at ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
