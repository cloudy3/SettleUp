import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/models.dart';
import '../services/services.dart';
import '../widgets/split_calculator.dart';

class AddExpenseScreen extends StatefulWidget {
  final String groupId;
  final List<Map<String, dynamic>> groupMembers;

  const AddExpenseScreen({
    super.key,
    required this.groupId,
    required this.groupMembers,
  });

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  final ExpenseService _expenseService = ExpenseService();

  String? _selectedPayer;
  DateTime _selectedDate = DateTime.now();
  ExpenseSplit? _expenseSplit;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Default payer to current user
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId != null &&
        widget.groupMembers.any((m) => m['id'] == currentUserId)) {
      _selectedPayer = currentUserId;
    }

    // Default to equal split with all members
    _expenseSplit = _expenseService.createEqualSplit(
      widget.groupMembers.map((m) => m['id'] as String).toList(),
    );
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Expense'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveExpense,
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
              _buildDescriptionField(),
              const SizedBox(height: 16),
              _buildAmountField(),
              const SizedBox(height: 16),
              _buildPayerSelector(),
              const SizedBox(height: 16),
              _buildDateSelector(),
              const SizedBox(height: 24),
              _buildSplitSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDescriptionField() {
    return TextFormField(
      controller: _descriptionController,
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
    return TextFormField(
      controller: _amountController,
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
    return DropdownButtonFormField<String>(
      value: _selectedPayer,
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
      onChanged: (value) {
        setState(() {
          _selectedPayer = value;
        });
      },
    );
  }

  Widget _buildDateSelector() {
    return InkWell(
      onTap: _selectDate,
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Date',
          border: OutlineInputBorder(),
          prefixIcon: Icon(Icons.calendar_today),
        ),
        child: Text(
          '${_selectedDate.month}/${_selectedDate.day}/${_selectedDate.year}',
        ),
      ),
    );
  }

  Widget _buildSplitSection() {
    final amount = double.tryParse(_amountController.text) ?? 0.0;

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
        if (_expenseSplit != null)
          SplitCalculator(
            totalAmount: amount,
            groupMembers: widget.groupMembers,
            initialSplit: _expenseSplit!,
            onSplitChanged: (split) {
              setState(() {
                _expenseSplit = split;
              });
            },
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

    if (_expenseSplit == null || !_expenseSplit!.isValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please configure a valid expense split'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final amount = double.parse(_amountController.text);
    if (!_expenseService.validateSplit(_expenseSplit!, amount)) {
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
      await _expenseService.addExpense(
        groupId: widget.groupId,
        description: _descriptionController.text.trim(),
        amount: amount,
        paidBy: _selectedPayer!,
        date: _selectedDate,
        split: _expenseSplit!,
      );

      if (mounted) {
        Navigator.of(context).pop(true); // Return true to indicate success
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Expense added successfully'),
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
            content: Text('Failed to add expense: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
