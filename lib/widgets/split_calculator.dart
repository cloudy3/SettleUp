import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/models.dart';

class SplitCalculator extends StatefulWidget {
  final double totalAmount;
  final List<Map<String, dynamic>> groupMembers;
  final ExpenseSplit initialSplit;
  final Function(ExpenseSplit)? onSplitChanged;
  final bool readOnly;

  const SplitCalculator({
    super.key,
    required this.totalAmount,
    required this.groupMembers,
    required this.initialSplit,
    this.onSplitChanged,
    this.readOnly = false,
  });

  @override
  State<SplitCalculator> createState() => _SplitCalculatorState();
}

class _SplitCalculatorState extends State<SplitCalculator>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  // Remove ExpenseService dependency to avoid Firebase initialization in tests

  late ExpenseSplit _currentSplit;
  final Map<String, TextEditingController> _customControllers = {};
  final Map<String, TextEditingController> _percentageControllers = {};
  Set<String> _selectedParticipants = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _currentSplit = widget.initialSplit;
    _selectedParticipants = Set.from(_currentSplit.participants);

    // Initialize controllers
    for (final member in widget.groupMembers) {
      final memberId = member['id'] as String;
      _customControllers[memberId] = TextEditingController();
      _percentageControllers[memberId] = TextEditingController();
    }

    // Set initial tab based on split type
    switch (_currentSplit.type) {
      case SplitType.equal:
        _tabController.index = 0;
        break;
      case SplitType.custom:
        _tabController.index = 1;
        _updateCustomControllers();
        break;
      case SplitType.percentage:
        _tabController.index = 2;
        _updatePercentageControllers();
        break;
    }

    _tabController.addListener(_onTabChanged);
  }

  @override
  void dispose() {
    _tabController.dispose();
    for (final controller in _customControllers.values) {
      controller.dispose();
    }
    for (final controller in _percentageControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  void didUpdateWidget(SplitCalculator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.totalAmount != oldWidget.totalAmount) {
      _updateCalculations();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          TabBar(
            controller: _tabController,
            physics: widget.readOnly
                ? const NeverScrollableScrollPhysics()
                : null,
            tabs: const [
              Tab(text: 'Equal'),
              Tab(text: 'Custom'),
              Tab(text: 'Percentage'),
            ],
          ),
          SizedBox(
            height: 400,
            child: TabBarView(
              controller: _tabController,
              physics: widget.readOnly
                  ? const NeverScrollableScrollPhysics()
                  : null,
              children: [
                _buildEqualSplitTab(),
                _buildCustomSplitTab(),
                _buildPercentageSplitTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEqualSplitTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select participants for equal split:',
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.builder(
              itemCount: widget.groupMembers.length,
              itemBuilder: (context, index) {
                final member = widget.groupMembers[index];
                final memberId = member['id'] as String;
                final isSelected = _selectedParticipants.contains(memberId);
                final shareAmount =
                    isSelected && _selectedParticipants.isNotEmpty
                    ? widget.totalAmount / _selectedParticipants.length
                    : 0.0;

                return CheckboxListTile(
                  value: isSelected,
                  onChanged: widget.readOnly
                      ? null
                      : (value) {
                          setState(() {
                            if (value == true) {
                              _selectedParticipants.add(memberId);
                            } else {
                              _selectedParticipants.remove(memberId);
                            }
                            _updateEqualSplit();
                          });
                        },
                  title: Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: Theme.of(context).primaryColor,
                        child: Text(
                          member['name'].isNotEmpty
                              ? member['name'][0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Text(member['name'] ?? member['email'])),
                    ],
                  ),
                  subtitle: isSelected
                      ? Text(
                          'Share: \$${shareAmount.toStringAsFixed(2)}',
                          style: TextStyle(
                            color: Theme.of(context).primaryColor,
                            fontWeight: FontWeight.w500,
                          ),
                        )
                      : null,
                );
              },
            ),
          ),
          if (_selectedParticipants.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${_selectedParticipants.length} participants',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  Text(
                    '\$${(widget.totalAmount / _selectedParticipants.length).toStringAsFixed(2)} each',
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCustomSplitTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Enter custom amounts for each participant:',
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.builder(
              itemCount: widget.groupMembers.length,
              itemBuilder: (context, index) {
                final member = widget.groupMembers[index];
                final memberId = member['id'] as String;
                final controller = _customControllers[memberId]!;
                final isParticipant = _selectedParticipants.contains(memberId);

                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Checkbox(
                          value: isParticipant,
                          onChanged: widget.readOnly
                              ? null
                              : (value) {
                                  setState(() {
                                    if (value == true) {
                                      _selectedParticipants.add(memberId);
                                    } else {
                                      _selectedParticipants.remove(memberId);
                                      controller.clear();
                                    }
                                    _updateCustomSplit();
                                  });
                                },
                        ),
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: Theme.of(context).primaryColor,
                          child: Text(
                            member['name'].isNotEmpty
                                ? member['name'][0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: Text(
                            member['name'] ?? member['email'],
                            style: TextStyle(
                              color: isParticipant ? null : Colors.grey,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: controller,
                            enabled: isParticipant && !widget.readOnly,
                            decoration: const InputDecoration(
                              prefixText: '\$',
                              hintText: '0.00',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 8,
                              ),
                            ),
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'^\d*\.?\d{0,2}'),
                              ),
                            ],
                            onChanged: (value) => _updateCustomSplit(),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          _buildCustomSplitSummary(),
        ],
      ),
    );
  }

  Widget _buildPercentageSplitTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Enter percentage for each participant:',
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.builder(
              itemCount: widget.groupMembers.length,
              itemBuilder: (context, index) {
                final member = widget.groupMembers[index];
                final memberId = member['id'] as String;
                final controller = _percentageControllers[memberId]!;
                final isParticipant = _selectedParticipants.contains(memberId);

                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Checkbox(
                          value: isParticipant,
                          onChanged: widget.readOnly
                              ? null
                              : (value) {
                                  setState(() {
                                    if (value == true) {
                                      _selectedParticipants.add(memberId);
                                    } else {
                                      _selectedParticipants.remove(memberId);
                                      controller.clear();
                                    }
                                    _updatePercentageSplit();
                                  });
                                },
                        ),
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: Theme.of(context).primaryColor,
                          child: Text(
                            member['name'].isNotEmpty
                                ? member['name'][0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: Text(
                            member['name'] ?? member['email'],
                            style: TextStyle(
                              color: isParticipant ? null : Colors.grey,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: controller,
                            enabled: isParticipant && !widget.readOnly,
                            decoration: const InputDecoration(
                              suffixText: '%',
                              hintText: '0',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 8,
                              ),
                            ),
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'^\d*\.?\d{0,2}'),
                              ),
                            ],
                            onChanged: (value) => _updatePercentageSplit(),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          _buildPercentageSplitSummary(),
        ],
      ),
    );
  }

  Widget _buildCustomSplitSummary() {
    double totalCustom = 0.0;
    for (final memberId in _selectedParticipants) {
      final amount = double.tryParse(_customControllers[memberId]!.text) ?? 0.0;
      totalCustom += amount;
    }

    final difference = widget.totalAmount - totalCustom;
    final isValid = difference.abs() < 0.01;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isValid
            ? Colors.green.withValues(alpha: 0.1)
            : Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total entered:'),
              Text(
                '\$${totalCustom.toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Expense total:'),
              Text(
                '\$${widget.totalAmount.toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Difference:'),
              Text(
                '\$${difference.toStringAsFixed(2)}',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: isValid ? Colors.green : Colors.red,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPercentageSplitSummary() {
    double totalPercentage = 0.0;
    for (final memberId in _selectedParticipants) {
      final percentage =
          double.tryParse(_percentageControllers[memberId]!.text) ?? 0.0;
      totalPercentage += percentage;
    }

    final isValid = (totalPercentage - 100.0).abs() < 0.01;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isValid
            ? Colors.green.withValues(alpha: 0.1)
            : Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Total percentage:'),
          Text(
            '${totalPercentage.toStringAsFixed(1)}%',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: isValid ? Colors.green : Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) return;

    setState(() {
      switch (_tabController.index) {
        case 0:
          _updateEqualSplit();
          break;
        case 1:
          _updateCustomSplit();
          break;
        case 2:
          _updatePercentageSplit();
          break;
      }
    });
  }

  void _updateEqualSplit() {
    if (_selectedParticipants.isEmpty) return;

    try {
      _currentSplit = ExpenseSplit(
        type: SplitType.equal,
        participants: _selectedParticipants.toList(),
        shares: {
          for (String participant in _selectedParticipants) participant: 1.0,
        },
      );
      widget.onSplitChanged?.call(_currentSplit);
    } catch (e) {
      // Handle error silently or show user feedback
    }
  }

  void _updateCustomSplit() {
    final customAmounts = <String, double>{};

    for (final memberId in _selectedParticipants) {
      final amount = double.tryParse(_customControllers[memberId]!.text) ?? 0.0;
      if (amount > 0) {
        customAmounts[memberId] = amount;
      }
    }

    if (customAmounts.isEmpty) return;

    try {
      _currentSplit = ExpenseSplit(
        type: SplitType.custom,
        participants: customAmounts.keys.toList(),
        shares: customAmounts,
      );
      widget.onSplitChanged?.call(_currentSplit);
    } catch (e) {
      // Handle error silently or show user feedback
    }
  }

  void _updatePercentageSplit() {
    final percentages = <String, double>{};

    for (final memberId in _selectedParticipants) {
      final percentage =
          double.tryParse(_percentageControllers[memberId]!.text) ?? 0.0;
      if (percentage > 0) {
        percentages[memberId] = percentage;
      }
    }

    if (percentages.isEmpty) return;

    try {
      _currentSplit = ExpenseSplit(
        type: SplitType.percentage,
        participants: percentages.keys.toList(),
        shares: percentages,
      );
      widget.onSplitChanged?.call(_currentSplit);
    } catch (e) {
      // Handle error silently or show user feedback
    }
  }

  void _updateCustomControllers() {
    for (final entry in _currentSplit.shares.entries) {
      _customControllers[entry.key]?.text = entry.value.toStringAsFixed(2);
    }
  }

  void _updatePercentageControllers() {
    for (final entry in _currentSplit.shares.entries) {
      _percentageControllers[entry.key]?.text = entry.value.toStringAsFixed(1);
    }
  }

  void _updateCalculations() {
    switch (_currentSplit.type) {
      case SplitType.equal:
        _updateEqualSplit();
        break;
      case SplitType.custom:
        _updateCustomSplit();
        break;
      case SplitType.percentage:
        _updatePercentageSplit();
        break;
    }
  }
}
