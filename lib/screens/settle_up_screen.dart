import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:settle_up/theme/app_theme.dart';
import 'package:settle_up/theme/app_tokens.dart';

import '../services/services.dart';

class SettleUpScreen extends StatefulWidget {
  final String groupId;
  final String toUserId;
  final double amount;
  final String toUserName;

  const SettleUpScreen({
    super.key,
    required this.groupId,
    required this.toUserId,
    required this.amount,
    required this.toUserName,
  });

  @override
  State<SettleUpScreen> createState() => _SettleUpScreenState();
}

class _SettleUpScreenState extends State<SettleUpScreen> {
  final BalanceService _balanceService = BalanceService();
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  final String? _currentUserId = FirebaseAuth.instance.currentUser?.uid;

  bool _isLoading = false;
  bool _isPartialPayment = false;

  @override
  void initState() {
    super.initState();
    _amountController.text = widget.amount.toStringAsFixed(2);
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settle Up'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.lg),
            child: Icon(Icons.payments_outlined, color: colorScheme.primary),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: AppInsets.screen,
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSettlementSummaryCard(),
              const SizedBox(height: AppSpacing.xl),
              _buildAmountSection(),
              const SizedBox(height: AppSpacing.xl),
              _buildNoteSection(),
              const SizedBox(height: AppSpacing.xxl),
              _buildConfirmationSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettlementSummaryCard() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final semantic = AppTheme.semanticOf(context);

    return Card(
      child: Padding(
        padding: AppInsets.card,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: colorScheme.errorContainer,
                  child: Text(
                    _currentUserId != null ? 'Y' : '?',
                    style: TextStyle(
                      color: colorScheme.onErrorContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Icon(Icons.arrow_forward, color: colorScheme.outline),
                const SizedBox(width: AppSpacing.md),
                CircleAvatar(
                  backgroundColor: colorScheme.primaryContainer,
                  child: Text(
                    widget.toUserName.isNotEmpty
                        ? widget.toUserName[0].toUpperCase()
                        : '?',
                    style: TextStyle(
                      color: colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'You are settling up with ${widget.toUserName}',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.symmetric(
                vertical: AppSpacing.sm,
                horizontal: AppSpacing.md,
              ),
              decoration: BoxDecoration(
                color: semantic.warning.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadii.sm),
                border: Border.all(
                  color: semantic.warning.withValues(alpha: 0.35),
                ),
              ),
              child: Text(
                'Total owed: \$${widget.amount.toStringAsFixed(2)}',
                style: TextStyle(
                  color: semantic.warning,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAmountSection() {
    final theme = Theme.of(context);
    final semantic = AppTheme.semanticOf(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Payment Amount',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Card(
          child: Padding(
            padding: AppInsets.card,
            child: Column(
              children: [
                TextFormField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(r'^\d*\.?\d{0,2}'),
                    ),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Amount',
                    prefixText: '\$',
                    border: OutlineInputBorder(),
                    helperText: 'Enter the amount you are paying',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter an amount';
                    }
                    final amount = double.tryParse(value);
                    if (amount == null || amount <= 0) {
                      return 'Please enter a valid amount';
                    }
                    if (amount > widget.amount) {
                      return 'Amount cannot exceed what you owe (\$${widget.amount.toStringAsFixed(2)})';
                    }
                    return null;
                  },
                  onChanged: (value) {
                    final amount = double.tryParse(value);
                    setState(() {
                      _isPartialPayment =
                          amount != null &&
                          amount < widget.amount &&
                          amount > 0;
                    });
                  },
                ),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          _amountController.text = (widget.amount / 2)
                              .toStringAsFixed(2);
                          setState(() {
                            _isPartialPayment = true;
                          });
                        },
                        child: const Text('Pay Half'),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          _amountController.text = widget.amount
                              .toStringAsFixed(2);
                          setState(() {
                            _isPartialPayment = false;
                          });
                        },
                        child: const Text('Pay Full'),
                      ),
                    ),
                  ],
                ),
                if (_isPartialPayment) ...[
                  const SizedBox(height: AppSpacing.md),
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: semantic.warning.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppRadii.sm),
                      border: Border.all(
                        color: semantic.warning.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info, color: semantic.warning, size: 20),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            'This is a partial payment. You will still owe \$${(widget.amount - (double.tryParse(_amountController.text) ?? 0)).toStringAsFixed(2)}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: semantic.warning,
                              fontWeight: FontWeight.w600,
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
        ),
      ],
    );
  }

  Widget _buildNoteSection() {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Note (Optional)',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Card(
          child: Padding(
            padding: AppInsets.card,
            child: TextFormField(
              controller: _noteController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Add a note',
                hintText: 'e.g., "Paid via Venmo", "Cash payment", etc.',
                border: OutlineInputBorder(),
              ),
              maxLength: 200,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildConfirmationSection() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final semantic = AppTheme.semanticOf(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: AppInsets.card,
          decoration: BoxDecoration(
            color: semantic.info.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppRadii.md),
            border: Border.all(color: semantic.info.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.info, color: semantic.info, size: 20),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    'Confirmation',
                    style: TextStyle(
                      color: semantic.info,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'By confirming this settlement, you are recording that you have paid this amount to the other person. This action cannot be undone.',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Both you and ${widget.toUserName} will be notified of this settlement.',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _isLoading
                    ? null
                    : () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _recordSettlement,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : const Text(
                        'Record Payment',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _recordSettlement() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter a valid amount'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    // Show confirmation dialog
    final confirmed = await _showConfirmationDialog(amount);
    if (!confirmed) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await _balanceService.recordSettlement(
        groupId: widget.groupId,
        fromUserId: _currentUserId!,
        toUserId: widget.toUserId,
        amount: amount,
        note: _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
      );

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to record settlement: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
            action: SnackBarAction(
              label: 'Retry',
              onPressed: _recordSettlement,
            ),
          ),
        );
      }
    }
  }

  Future<bool> _showConfirmationDialog(double amount) async {
    final theme = Theme.of(context);
    final semantic = AppTheme.semanticOf(context);

    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Confirm Settlement'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('You are about to record a payment of:'),
                const SizedBox(height: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: semantic.success.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadii.sm),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.payment, color: semantic.success),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        '\$${amount.toStringAsFixed(2)} to ${widget.toUserName}',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                if (_noteController.text.trim().isNotEmpty) ...[
                  Text(
                    'Note:',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(_noteController.text.trim()),
                  const SizedBox(height: AppSpacing.md),
                ],
                Text(
                  'This action cannot be undone. Are you sure?',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: semantic.success,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Confirm'),
              ),
            ],
          ),
        ) ??
        false;
  }
}
