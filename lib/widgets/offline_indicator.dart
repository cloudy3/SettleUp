import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/providers.dart';

/// Widget that shows offline status and pending operations
class OfflineIndicator extends StatelessWidget {
  const OfflineIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<OfflineProvider>(
      builder: (context, offlineProvider, child) {
        if (offlineProvider.isOnline &&
            offlineProvider.pendingOperations.isEmpty) {
          return const SizedBox.shrink();
        }

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: offlineProvider.isOnline ? Colors.orange : Colors.red,
          child: SafeArea(
            child: Row(
              children: [
                Icon(
                  offlineProvider.isOnline ? Icons.sync : Icons.wifi_off,
                  color: Colors.white,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _getStatusMessage(offlineProvider),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                if (offlineProvider.pendingOperations.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${offlineProvider.pendingOperations.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _getStatusMessage(OfflineProvider offlineProvider) {
    if (!offlineProvider.isOnline) {
      if (offlineProvider.pendingOperations.isEmpty) {
        return 'You are offline. Changes will sync when connection is restored.';
      } else {
        return 'Offline - ${offlineProvider.pendingOperations.length} changes pending sync';
      }
    } else if (offlineProvider.pendingOperations.isNotEmpty) {
      return 'Syncing ${offlineProvider.pendingOperations.length} pending changes...';
    }
    return '';
  }
}

/// Floating offline indicator that can be shown as an overlay
class FloatingOfflineIndicator extends StatelessWidget {
  const FloatingOfflineIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<OfflineProvider>(
      builder: (context, offlineProvider, child) {
        if (offlineProvider.isOnline &&
            offlineProvider.pendingOperations.isEmpty) {
          return const SizedBox.shrink();
        }

        return Positioned(
          top: MediaQuery.of(context).padding.top + 8,
          left: 16,
          right: 16,
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(8),
            color: offlineProvider.isOnline ? Colors.orange : Colors.red,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Icon(
                    offlineProvider.isOnline ? Icons.sync : Icons.wifi_off,
                    color: Colors.white,
                    size: 18,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          offlineProvider.isOnline ? 'Syncing...' : 'Offline',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (offlineProvider.pendingOperations.isNotEmpty)
                          Text(
                            '${offlineProvider.pendingOperations.length} changes pending',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (offlineProvider.pendingOperations.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${offlineProvider.pendingOperations.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
