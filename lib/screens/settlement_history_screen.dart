import 'package:flutter/material.dart';
import '../widgets/settlement_history_widget.dart';

class SettlementHistoryScreen extends StatelessWidget {
  final String groupId;
  final List<Map<String, dynamic>> groupMembers;
  final String groupName;
  final String currencyCode;

  const SettlementHistoryScreen({
    super.key,
    required this.groupId,
    required this.groupMembers,
    required this.groupName,
    this.currencyCode = 'USD',
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('$groupName - Settlement History'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: SettlementHistoryWidget(
        groupId: groupId,
        groupMembers: groupMembers,
        currencyCode: currencyCode,
      ),
    );
  }
}
