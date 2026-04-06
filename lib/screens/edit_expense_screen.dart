import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import '../models/models.dart';
import '../services/services.dart';
import '../widgets/split_calculator.dart';

class EditExpenseScreen extends StatefulWidget {
  final Expense expense;
  final List<Map<String, dynamic>> groupMembers;

  const EditExpenseScreen({
    super.key,
    required this.expense,
    required this.groupMembers,
  });

  @override
  State<EditExpenseScreen> createState() => _EditExpenseScreenState();
}

class _EditExpenseScreenState extends State<EditExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _descriptionController;
  late final TextEditingController _amountController;
  late final TextEditingController _noteController;
  final ExpenseService _expenseService = ExpenseService();

  late String _selectedPayer;
  late DateTime _selectedDate;
  late ExpenseSplit _expenseSplit;
  bool _isLoading = false;
  late ExpenseCategory _category;
  XFile? _receiptFile;
  bool _clearReceipt = false;

  @override
  void initState() {
    super.initState();

    // Initialize controllers with current expense data
    _descriptionController = TextEditingController(
      text: widget.expense.description,
    );
    _amountController = TextEditingController(
      text: widget.expense.amount.toStringAsFixed(2),
    );
    _noteController = TextEditingController(text: widget.expense.note ?? '');
    _selectedPayer = widget.expense.paidBy;
    _selectedDate = widget.expense.date;
    _expenseSplit = widget.expense.split;
    _category = widget.expense.category;
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final canEdit = widget.expense.createdBy == currentUserId;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Expense'),
        actions: [
          TextButton(
            onPressed: (_isLoading || !canEdit) ? null : _saveExpense,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('SAVE'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!canEdit) _buildPermissionWarning(),
              _buildDescriptionField(),
              const SizedBox(height: 16),
              _buildAmountField(),
              const SizedBox(height: 16),
              _buildPayerSelector(),
              const SizedBox(height: 16),
              _buildDateSelector(),
              const SizedBox(height: 16),
              _buildCategoryField(),
              const SizedBox(height: 16),
              _buildNoteField(),
              const SizedBox(height: 16),
              _buildReceiptSection(),
              const SizedBox(height: 24),
              _buildSplitSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPermissionWarning() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange),
      ),
      child: const Row(
        children: [
          Icon(Icons.warning, color: Colors.orange),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'You can only edit expenses that you created. This expense is read-only.',
              style: TextStyle(color: Colors.orange),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionField() {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final canEdit = widget.expense.createdBy == currentUserId;

    return TextFormField(
      controller: _descriptionController,
      enabled: canEdit,
      decoration: const InputDecoration(
        labelText: 'Description',
        hintText: 'What was this expense for?',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.description),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Please enter a description';
        }
        return null;
      },
      textCapitalization: TextCapitalization.sentences,
    );
  }

  Widget _buildAmountField() {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final canEdit = widget.expense.createdBy == currentUserId;

    return TextFormField(
      controller: _amountController,
      enabled: canEdit,
      decoration: const InputDecoration(
        labelText: 'Amount',
        hintText: '0.00',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.attach_money),
        prefixText: '\$',
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
      ],
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Please enter an amount';
        }
        final amount = double.tryParse(value);
        if (amount == null || amount <= 0) {
          return 'Please enter a valid amount greater than 0';
        }
        return null;
      },
      onChanged: (value) {
        // Update split calculator when amount changes
        setState(() {});
      },
    );
  }

  Widget _buildPayerSelector() {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final canEdit = widget.expense.createdBy == currentUserId;

    return DropdownButtonFormField<String>(
      initialValue: _selectedPayer,
      decoration: const InputDecoration(
        labelText: 'Paid by',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.person),
      ),
      items: widget.groupMembers.map((member) {
        return DropdownMenuItem<String>(
          value: member['id'],
          child: Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: Theme.of(context).primaryColor,
                child: Text(
                  member['name'].isNotEmpty
                      ? member['name'][0].toUpperCase()
                      : '?',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  member['name'] ?? member['email'],
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      }).toList(),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please select who paid for this expense';
        }
        return null;
      },
      onChanged: canEdit
          ? (value) {
              setState(() {
                _selectedPayer = value!;
              });
            }
          : null,
    );
  }

  Widget _buildCategoryField() {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final canEdit = widget.expense.createdBy == currentUserId;

    return DropdownButtonFormField<ExpenseCategory>(
      initialValue: _category,
      decoration: InputDecoration(
        labelText: 'Category',
        border: const OutlineInputBorder(),
        prefixIcon: const Icon(Icons.category_outlined),
        enabled: canEdit,
      ),
      items: ExpenseCategory.values
          .map(
            (c) => DropdownMenuItem(
              value: c,
              child: Text(c.label),
            ),
          )
          .toList(),
      onChanged: canEdit
          ? (value) {
              if (value != null) {
                setState(() => _category = value);
              }
            }
          : null,
    );
  }

  Widget _buildNoteField() {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final canEdit = widget.expense.createdBy == currentUserId;

    return TextFormField(
      controller: _noteController,
      enabled: canEdit,
      decoration: const InputDecoration(
        labelText: 'Notes (optional)',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.notes),
      ),
      maxLines: 3,
      textCapitalization: TextCapitalization.sentences,
    );
  }

  Widget _buildReceiptSection() {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final canEdit = widget.expense.createdBy == currentUserId;
    final hasExisting =
        widget.expense.receiptUrl != null &&
        widget.expense.receiptUrl!.isNotEmpty &&
        !_clearReceipt;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasExisting)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              'Current receipt is attached.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        if (canEdit)
          OutlinedButton.icon(
            onPressed: _isLoading
                ? null
                : () async {
                    final picker = ImagePicker();
                    final file = await picker.pickImage(
                      source: ImageSource.gallery,
                      maxWidth: 1600,
                      imageQuality: 85,
                    );
                    if (file != null) {
                      setState(() {
                        _receiptFile = file;
                        _clearReceipt = false;
                      });
                    }
                  },
            icon: const Icon(Icons.photo_camera_outlined),
            label: Text(
              _receiptFile != null
                  ? 'Replace receipt'
                  : 'Attach new receipt',
            ),
          ),
        if (canEdit && (hasExisting || _receiptFile != null)) ...[
          const SizedBox(height: 8),
          TextButton(
            onPressed: _isLoading
                ? null
                : () {
                    setState(() {
                      _receiptFile = null;
                      _clearReceipt = true;
                    });
                  },
            child: const Text('Remove receipt'),
          ),
        ],
        if (_receiptFile != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Pending: ${_receiptFile!.name}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
      ],
    );
  }

  Widget _buildDateSelector() {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final canEdit = widget.expense.createdBy == currentUserId;

    return InkWell(
      onTap: canEdit ? _selectDate : null,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Date',
          border: const OutlineInputBorder(),
          prefixIcon: const Icon(Icons.calendar_today),
          enabled: canEdit,
        ),
        child: Text(
          '${_selectedDate.month}/${_selectedDate.day}/${_selectedDate.year}',
          style: TextStyle(color: canEdit ? null : Colors.grey),
        ),
      ),
    );
  }

  Widget _buildSplitSection() {
    final amount = double.tryParse(_amountController.text) ?? 0.0;
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final canEdit = widget.expense.createdBy == currentUserId;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Split Details',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        SplitCalculator(
          totalAmount: amount,
          groupMembers: widget.groupMembers,
          initialSplit: _expenseSplit,
          readOnly: !canEdit,
          onSplitChanged: canEdit
              ? (split) {
                  setState(() {
                    _expenseSplit = split;
                  });
                }
              : null,
        ),
      ],
    );
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _saveExpense() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_expenseSplit.isValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please configure a valid expense split'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final amount = double.parse(_amountController.text);
    if (!_expenseService.validateSplit(_expenseSplit, amount)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Split amounts do not match the total expense amount'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final noteTrim = _noteController.text.trim();
      await _expenseService.updateExpense(
        expenseId: widget.expense.id,
        description: _descriptionController.text.trim(),
        amount: amount,
        paidBy: _selectedPayer,
        date: _selectedDate,
        split: _expenseSplit,
        note: noteTrim.isEmpty ? null : noteTrim,
        clearNote: noteTrim.isEmpty,
        category: _category,
        receiptFile: _receiptFile,
        clearReceiptUrl: _clearReceipt,
      );

      if (mounted) {
        Navigator.of(context).pop(true); // Return true to indicate success
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Expense updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update expense: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
