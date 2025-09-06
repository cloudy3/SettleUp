import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/models.dart';
import '../services/services.dart';

/// Main application state provider that manages global app state
class AppStateProvider extends ChangeNotifier {
  final GroupService _groupService = GroupService();
  final NotificationService _notificationService = NotificationService();

  // Current user
  User? _currentUser;
  User? get currentUser => _currentUser;

  // Groups
  List<Group> _groups = [];
  List<Group> get groups => _groups;

  // Notifications
  List<SettlementNotification> _notifications = [];
  List<SettlementNotification> get notifications => _notifications;
  int _unreadNotificationCount = 0;
  int get unreadNotificationCount => _unreadNotificationCount;

  // Loading states
  bool _isLoadingGroups = false;
  bool get isLoadingGroups => _isLoadingGroups;

  bool _isLoadingNotifications = false;
  bool get isLoadingNotifications => _isLoadingNotifications;

  // Error states
  String? _error;
  String? get error => _error;

  // Stream subscriptions for cleanup
  StreamSubscription<List<Group>>? _groupsSubscription;
  StreamSubscription<List<SettlementNotification>>? _notificationsSubscription;
  StreamSubscription<int>? _unreadCountSubscription;
  StreamSubscription<User?>? _authSubscription;

  AppStateProvider() {
    _initializeAuth();
  }

  /// Initialize authentication listener
  void _initializeAuth() {
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((user) {
      _currentUser = user;
      if (user != null) {
        _initializeUserData();
      } else {
        _clearUserData();
      }
      notifyListeners();
    });
  }

  /// Initialize user-specific data streams
  void _initializeUserData() {
    _loadGroups();
    _loadNotifications();
    _loadUnreadNotificationCount();
  }

  /// Clear user data when logged out
  void _clearUserData() {
    _groups.clear();
    _notifications.clear();
    _unreadNotificationCount = 0;
    _error = null;
    _cancelSubscriptions();
    notifyListeners();
  }

  /// Load groups with real-time updates
  void _loadGroups() {
    _isLoadingGroups = true;
    _error = null;
    notifyListeners();

    _groupsSubscription?.cancel();
    _groupsSubscription = _groupService.getGroupsStream().listen(
      (groups) {
        _groups = groups;
        _isLoadingGroups = false;
        _error = null;
        notifyListeners();
      },
      onError: (error) {
        _error = 'Failed to load groups: $error';
        _isLoadingGroups = false;
        notifyListeners();
      },
    );
  }

  /// Load notifications with real-time updates
  void _loadNotifications() {
    _isLoadingNotifications = true;
    notifyListeners();

    _notificationsSubscription?.cancel();
    _notificationsSubscription = _notificationService
        .getUserNotificationsStream()
        .listen(
          (notifications) {
            _notifications = notifications;
            _isLoadingNotifications = false;
            notifyListeners();
          },
          onError: (error) {
            debugPrint('Failed to load notifications: $error');
            _isLoadingNotifications = false;
            notifyListeners();
          },
        );
  }

  /// Load unread notification count with real-time updates
  void _loadUnreadNotificationCount() {
    _unreadCountSubscription?.cancel();
    _unreadCountSubscription = _notificationService
        .getUnreadNotificationCountStream()
        .listen(
          (count) {
            _unreadNotificationCount = count;
            notifyListeners();
          },
          onError: (error) {
            debugPrint('Failed to load unread notification count: $error');
          },
        );
  }

  /// Refresh groups manually
  Future<void> refreshGroups() async {
    try {
      _isLoadingGroups = true;
      _error = null;
      notifyListeners();

      final groups = await _groupService.getGroupsForUser();
      _groups = groups;
      _isLoadingGroups = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to refresh groups: $e';
      _isLoadingGroups = false;
      notifyListeners();
    }
  }

  /// Mark notification as read
  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await _notificationService.markNotificationAsRead(notificationId);
      // The stream will automatically update the UI
    } catch (e) {
      debugPrint('Failed to mark notification as read: $e');
    }
  }

  /// Mark all notifications as read
  Future<void> markAllNotificationsAsRead() async {
    try {
      await _notificationService.markAllNotificationsAsRead();
      // The stream will automatically update the UI
    } catch (e) {
      debugPrint('Failed to mark all notifications as read: $e');
    }
  }

  /// Get group by ID
  Group? getGroupById(String groupId) {
    try {
      return _groups.firstWhere((group) => group.id == groupId);
    } catch (e) {
      return null;
    }
  }

  /// Cancel all subscriptions
  void _cancelSubscriptions() {
    _groupsSubscription?.cancel();
    _notificationsSubscription?.cancel();
    _unreadCountSubscription?.cancel();
  }

  @override
  void dispose() {
    _cancelSubscriptions();
    _authSubscription?.cancel();
    super.dispose();
  }
}
