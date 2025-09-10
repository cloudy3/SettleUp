import "package:cloud_firestore/cloud_firestore.dart";
import "package:firebase_auth/firebase_auth.dart";
import "package:flutter/material.dart";
import "package:firebase_core/firebase_core.dart";
import "package:provider/provider.dart";
import "package:settle_up/screens/home_screen.dart";
import "package:settle_up/screens/onboarding_scren.dart";
import "firebase_options.dart";
import "package:settle_up/screens/auth_screen.dart";
import "package:settle_up/providers/providers.dart";
import "package:settle_up/services/services.dart";
import "package:settle_up/models/models.dart";
// Expense sharing screens
import "package:settle_up/screens/group_list_screen.dart";
import "package:settle_up/screens/create_group_screen.dart";
import "package:settle_up/screens/group_detail_screen.dart";
import "package:settle_up/screens/add_expense_screen.dart";
import "package:settle_up/screens/expense_detail_screen.dart";
import "package:settle_up/screens/edit_expense_screen.dart";
import "package:settle_up/screens/balance_screen.dart";
import "package:settle_up/screens/settle_up_screen.dart";
import "package:settle_up/screens/settlement_history_screen.dart";
import "package:settle_up/screens/member_management_screen.dart";
import "package:settle_up/screens/expense_audit_screen.dart";

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize connectivity service
  await ConnectivityService().initialize();

  // Fetch initial route
  final initialRoute = await getInitialRoute();

  runApp(MyApp(initialRoute: initialRoute));
}

Future<String> getInitialRoute() async {
  final user = FirebaseAuth.instance.currentUser;

  if (user == null) {
    return "/auth"; // User not signed in
  }

  // Fetch onboarding status from Firestore
  final userDoc = await FirebaseFirestore.instance
      .collection("Users")
      .doc(user.uid)
      .get();

  if (!userDoc.exists || !(userDoc.data()?["onboardingCompleted"] ?? false)) {
    return "/onboarding"; // Onboarding not completed
  }

  return "/home"; // Onboarding completed
}

class MyApp extends StatelessWidget {
  final String initialRoute;
  const MyApp({required this.initialRoute, super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AppStateProvider()),
        ChangeNotifierProvider(create: (_) => OfflineProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return _ConnectivityWrapper(
            child: MaterialApp(
              debugShowCheckedModeBanner: false,
              title: "Splitwise Clone",
              theme: themeProvider.currentTheme,
              initialRoute: initialRoute,
              routes: {
                "/auth": (context) => const AuthScreen(),
                "/onboarding": (context) => const OnboardingScreen(),
                "/home": (context) => const HomeScreen(),
                // Expense sharing routes
                "/groups": (context) => const GroupListScreen(),
                "/create-group": (context) => const CreateGroupScreen(),
              },
              onGenerateRoute: (settings) {
                // Handle parameterized routes
                if (settings.name?.startsWith('/group/') == true) {
                  final groupId = settings.name!.split('/')[2];
                  return MaterialPageRoute(
                    builder: (context) => GroupDetailScreen(groupId: groupId),
                    settings: settings,
                  );
                }
                if (settings.name?.startsWith('/add-expense/') == true) {
                  final groupId = settings.name!.split('/')[2];
                  return MaterialPageRoute(
                    builder: (context) =>
                        _AddExpenseScreenWrapper(groupId: groupId),
                    settings: settings,
                  );
                }
                if (settings.name?.startsWith('/expense/') == true) {
                  final expenseId = settings.name!.split('/')[2];
                  return MaterialPageRoute(
                    builder: (context) =>
                        _ExpenseDetailScreenWrapper(expenseId: expenseId),
                    settings: settings,
                  );
                }
                if (settings.name?.startsWith('/edit-expense/') == true) {
                  final expenseId = settings.name!.split('/')[2];
                  return MaterialPageRoute(
                    builder: (context) =>
                        _EditExpenseScreenWrapper(expenseId: expenseId),
                    settings: settings,
                  );
                }
                if (settings.name?.startsWith('/balance/') == true) {
                  final groupId = settings.name!.split('/')[2];
                  return MaterialPageRoute(
                    builder: (context) =>
                        _BalanceScreenWrapper(groupId: groupId),
                    settings: settings,
                  );
                }
                if (settings.name?.startsWith('/settle-up/') == true) {
                  final parts = settings.name!.split('/');
                  final groupId = parts[2];
                  final fromUserId = parts[3];
                  final toUserId = parts[4];
                  final amount = double.parse(parts[5]);
                  return MaterialPageRoute(
                    builder: (context) => _SettleUpScreenWrapper(
                      groupId: groupId,
                      fromUserId: fromUserId,
                      toUserId: toUserId,
                      amount: amount,
                    ),
                    settings: settings,
                  );
                }
                if (settings.name?.startsWith('/settlement-history/') == true) {
                  final groupId = settings.name!.split('/')[2];
                  return MaterialPageRoute(
                    builder: (context) =>
                        _SettlementHistoryScreenWrapper(groupId: groupId),
                    settings: settings,
                  );
                }
                if (settings.name?.startsWith('/member-management/') == true) {
                  final groupId = settings.name!.split('/')[2];
                  return MaterialPageRoute(
                    builder: (context) =>
                        _MemberManagementScreenWrapper(groupId: groupId),
                    settings: settings,
                  );
                }
                if (settings.name?.startsWith('/expense-audit/') == true) {
                  final expenseId = settings.name!.split('/')[2];
                  return MaterialPageRoute(
                    builder: (context) =>
                        _ExpenseAuditScreenWrapper(expenseId: expenseId),
                    settings: settings,
                  );
                }
                return null;
              },
            ),
          );
        },
      ),
    );
  }
}

/// Wrapper to handle connectivity changes and update offline provider
class _ConnectivityWrapper extends StatefulWidget {
  final Widget child;

  const _ConnectivityWrapper({required this.child});

  @override
  State<_ConnectivityWrapper> createState() => _ConnectivityWrapperState();
}

class _ConnectivityWrapperState extends State<_ConnectivityWrapper> {
  late final ConnectivityService _connectivityService;

  @override
  void initState() {
    super.initState();
    _connectivityService = ConnectivityService();

    // Listen to connectivity changes and update offline provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _connectivityService.connectivityStream.listen((isOnline) {
        if (mounted) {
          final offlineProvider = context.read<OfflineProvider>();
          offlineProvider.updateOnlineStatus(isOnline);
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = false;

  bool get isDarkMode => _isDarkMode;

  ThemeData get currentTheme => _isDarkMode ? darkTheme : lightTheme;

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }

  ThemeData get lightTheme => ThemeData(
    brightness: Brightness.light,
    primarySwatch: Colors.deepPurple,
    primaryColor: Colors.blue.shade900,
    scaffoldBackgroundColor: Colors.grey.shade100,
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.blue.shade900,
      titleTextStyle: const TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: Colors.blue.shade900,
      foregroundColor: Colors.white,
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      shadowColor: Colors.grey[300],
      elevation: 4,
      margin: const EdgeInsets.all(8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    textTheme: TextTheme(
      headlineLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: Colors.blue.shade900,
      ),
      headlineMedium: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: Colors.blue.shade800,
      ),
      bodyLarge: TextStyle(fontSize: 16, color: Colors.grey.shade700),
      bodyMedium: TextStyle(fontSize: 14, color: Colors.grey.shade600),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.blue.shade900, width: 2),
      ),
    ),
  );

  ThemeData get darkTheme => ThemeData(
    brightness: Brightness.dark,
    primarySwatch: Colors.deepPurple,
    primaryColor: Colors.deepPurple.shade900,
    scaffoldBackgroundColor: const Color.fromARGB(255, 4, 0, 53),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.deepPurple,
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: Colors.blue.shade900,
      foregroundColor: Colors.white,
    ),
    cardTheme: CardThemeData(
      color: Colors.grey[800],
      shadowColor: Colors.grey[700],
      elevation: 4,
      margin: const EdgeInsets.all(8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    textTheme: TextTheme(
      headlineLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: Colors.deepPurple.shade100,
      ),
      headlineMedium: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: Colors.deepPurple.shade200,
      ),
      bodyLarge: TextStyle(fontSize: 16, color: Colors.grey.shade400),
      bodyMedium: TextStyle(fontSize: 14, color: Colors.grey.shade500),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.grey[800],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.deepPurple, width: 2),
      ),
    ),
  );
}

/// Wrapper widget to load group members before showing AddExpenseScreen
class _AddExpenseScreenWrapper extends StatelessWidget {
  final String groupId;

  const _AddExpenseScreenWrapper({required this.groupId});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: GroupService().getGroupMembers(groupId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(title: const Text('Add Expense')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(title: const Text('Add Expense')),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error loading group: ${snapshot.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Go Back'),
                  ),
                ],
              ),
            ),
          );
        }

        final groupMembers = snapshot.data ?? [];
        return AddExpenseScreen(groupId: groupId, groupMembers: groupMembers);
      },
    );
  }
}

/// Wrapper widget to load expense and group members before showing ExpenseDetailScreen
class _ExpenseDetailScreenWrapper extends StatelessWidget {
  final String expenseId;

  const _ExpenseDetailScreenWrapper({required this.expenseId});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _loadExpenseData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(title: const Text('Expense Details')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(title: const Text('Expense Details')),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error loading expense: ${snapshot.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Go Back'),
                  ),
                ],
              ),
            ),
          );
        }

        final data = snapshot.data!;
        return ExpenseDetailScreen(
          expenseId: expenseId,
          groupMembers: data['groupMembers'],
        );
      },
    );
  }

  Future<Map<String, dynamic>> _loadExpenseData() async {
    final expenseService = ExpenseService();
    final groupService = GroupService();

    final expense = await expenseService.getExpenseById(expenseId);
    if (expense == null) {
      throw Exception('Expense not found');
    }
    final groupMembers = await groupService.getGroupMembers(expense.groupId);

    return {'expense': expense, 'groupMembers': groupMembers};
  }
}

/// Wrapper widget to load expense and group members before showing EditExpenseScreen
class _EditExpenseScreenWrapper extends StatelessWidget {
  final String expenseId;

  const _EditExpenseScreenWrapper({required this.expenseId});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _loadExpenseData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(title: const Text('Edit Expense')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(title: const Text('Edit Expense')),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error loading expense: ${snapshot.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Go Back'),
                  ),
                ],
              ),
            ),
          );
        }

        final data = snapshot.data!;
        return EditExpenseScreen(
          expense: data['expense'],
          groupMembers: data['groupMembers'],
        );
      },
    );
  }

  Future<Map<String, dynamic>> _loadExpenseData() async {
    final expenseService = ExpenseService();
    final groupService = GroupService();

    final expense = await expenseService.getExpenseById(expenseId);
    if (expense == null) {
      throw Exception('Expense not found');
    }
    final groupMembers = await groupService.getGroupMembers(expense.groupId);

    return {'expense': expense, 'groupMembers': groupMembers};
  }
}

/// Wrapper widget to load group members before showing BalanceScreen
class _BalanceScreenWrapper extends StatelessWidget {
  final String groupId;

  const _BalanceScreenWrapper({required this.groupId});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: GroupService().getGroupMembers(groupId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(title: const Text('Balances')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(title: const Text('Balances')),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error loading group: ${snapshot.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Go Back'),
                  ),
                ],
              ),
            ),
          );
        }

        final groupMembers = snapshot.data ?? [];
        return BalanceScreen(groupId: groupId, groupMembers: groupMembers);
      },
    );
  }
}

/// Wrapper widget to load user name before showing SettleUpScreen
class _SettleUpScreenWrapper extends StatelessWidget {
  final String groupId;
  final String fromUserId;
  final String toUserId;
  final double amount;

  const _SettleUpScreenWrapper({
    required this.groupId,
    required this.fromUserId,
    required this.toUserId,
    required this.amount,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _getToUserName(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(title: const Text('Settle Up')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(title: const Text('Settle Up')),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error loading user: ${snapshot.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Go Back'),
                  ),
                ],
              ),
            ),
          );
        }

        final toUserName = snapshot.data ?? 'Unknown User';
        return SettleUpScreen(
          groupId: groupId,
          toUserId: toUserId,
          toUserName: toUserName,
          amount: amount,
        );
      },
    );
  }

  Future<String> _getToUserName() async {
    final userDoc = await FirebaseFirestore.instance
        .collection('Users')
        .doc(toUserId)
        .get();
    return userDoc.data()?['name'] ?? 'Unknown User';
  }
}

/// Wrapper widget to load group data before showing SettlementHistoryScreen
class _SettlementHistoryScreenWrapper extends StatelessWidget {
  final String groupId;

  const _SettlementHistoryScreenWrapper({required this.groupId});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _loadGroupData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(title: const Text('Settlement History')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(title: const Text('Settlement History')),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error loading group: ${snapshot.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Go Back'),
                  ),
                ],
              ),
            ),
          );
        }

        final data = snapshot.data!;
        return SettlementHistoryScreen(
          groupId: groupId,
          groupName: data['groupName'],
          groupMembers: data['groupMembers'],
        );
      },
    );
  }

  Future<Map<String, dynamic>> _loadGroupData() async {
    final groupService = GroupService();
    final group = await groupService.getGroupById(groupId);
    if (group == null) {
      throw Exception('Group not found');
    }
    final groupMembers = await groupService.getGroupMembers(groupId);

    return {'groupName': group.name, 'groupMembers': groupMembers};
  }
}

/// Wrapper widget to load group data before showing MemberManagementScreen
class _MemberManagementScreenWrapper extends StatelessWidget {
  final String groupId;

  const _MemberManagementScreenWrapper({required this.groupId});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Group?>(
      future: GroupService().getGroupById(groupId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(title: const Text('Manage Members')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(title: const Text('Manage Members')),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error loading group: ${snapshot.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Go Back'),
                  ),
                ],
              ),
            ),
          );
        }

        final group = snapshot.data;
        if (group == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Manage Members')),
            body: const Center(child: Text('Group not found')),
          );
        }
        return MemberManagementScreen(groupId: groupId, group: group);
      },
    );
  }
}

/// Wrapper widget to load expense and group members before showing ExpenseAuditScreen
class _ExpenseAuditScreenWrapper extends StatelessWidget {
  final String expenseId;

  const _ExpenseAuditScreenWrapper({required this.expenseId});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _loadGroupMembers(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(title: const Text('Expense Audit')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(title: const Text('Expense Audit')),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error loading data: ${snapshot.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Go Back'),
                  ),
                ],
              ),
            ),
          );
        }

        final groupMembers = snapshot.data ?? [];
        return ExpenseAuditScreen(
          expenseId: expenseId,
          groupMembers: groupMembers,
        );
      },
    );
  }

  Future<List<Map<String, dynamic>>> _loadGroupMembers() async {
    final expenseService = ExpenseService();
    final groupService = GroupService();

    final expense = await expenseService.getExpenseById(expenseId);
    if (expense == null) {
      throw Exception('Expense not found');
    }
    return await groupService.getGroupMembers(expense.groupId);
  }
}
