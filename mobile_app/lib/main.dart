import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'config/app_config.dart';
import 'screens/report_form_screen.dart';
import 'screens/report_history_screen.dart';
import 'screens/tl_dashboard_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/admin_dashboard_screen.dart';
import 'screens/manage_employees_screen.dart';
import 'screens/app_settings_screen.dart';
import 'providers/notification_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Supabase.initialize(
    url: AppConfig.supabaseUrl,
    anonKey: AppConfig.supabaseAnonKey,
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
      ],
      child: FaithHoursApp(),
    ),
  );
}

class FaithHoursApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Faith Hours',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo, secondary: Colors.deepPurpleAccent),
        scaffoldBackgroundColor: const Color(0xFFF8F9FE),
        textTheme: GoogleFonts.latoTextTheme(
          Theme.of(context).textTheme,
        ),
        pageTransitionsTheme: PageTransitionsTheme(
          builders: {
            TargetPlatform.android: const FadeUpwardsPageTransitionsBuilder(),
            TargetPlatform.iOS: const FadeUpwardsPageTransitionsBuilder(),
          },
        ),
        visualDensity: VisualDensity.adaptivePlatformDensity,
        appBarTheme: AppBarTheme(
          elevation: 0,
          centerTitle: true,
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.indigo.shade900,
          iconTheme: IconThemeData(color: Colors.indigo.shade900),
        ),
        cardTheme: CardThemeData(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 8,
          shadowColor: Colors.indigo.withOpacity(0.1),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.indigo.shade100),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.indigo.shade50),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.indigo, width: 2),
          ),
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          elevation: 20,
          backgroundColor: Colors.white,
          selectedItemColor: Colors.indigo,
          unselectedItemColor: Colors.grey.shade400,
          type: BottomNavigationBarType.fixed,
        ),
      ),
      home: AuthWrapper(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class AuthWrapper extends StatefulWidget {
  @override
  _AuthWrapperState createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  Map<String, dynamic>? _userProfile;
  bool _isLoading = true;
  final _storage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _loadSavedSession();
  }

  Future<void> _loadSavedSession() async {
    final profileString = await _storage.read(key: 'user_profile');
    if (profileString != null) {
      final profile = jsonDecode(profileString);
      _handleLogin(profile, saveSession: false);
    } else {
      setState(() => _isLoading = false);
    }
  }

  void _handleLogin(Map<String, dynamic> profile, {bool saveSession = true}) async {
    if (saveSession) {
      await _storage.write(key: 'user_profile', value: jsonEncode(profile));
    }

    setState(() {
      _userProfile = profile;
      _isLoading = false;
    });

    final String notificationIdentifier = profile['employee_code'];

    Provider.of<NotificationProvider>(context, listen: false)
        .initNotifications(notificationIdentifier);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_userProfile == null) {
      return SignupScreen(onLoginComplete: (profile) => _handleLogin(profile));
    }
    return HomeScreen(userProfile: _userProfile!);
  }
}


class HomeScreen extends StatefulWidget {
  final Map<String, dynamic> userProfile;

  HomeScreen({required this.userProfile});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  
  late List<Widget> _screens;
  late List<BottomNavigationBarItem> _navItems;
  String _resolvedTLCode = '';
  String _resolvedTLName = '';

  @override
  void initState() {
    super.initState();
    _buildNavigation();
  }

  Future<void> _buildNavigation() async {
    final profile = widget.userProfile;
    final bool isTL = profile['role'] == 'Team Leader' || profile['role'] == 'Admin' || profile['role'] == 'App Admin';
    final bool isAdmin = profile['role'] == 'Admin' || profile['role'] == 'App Admin';
    final bool isAppAdmin = profile['role'] == 'App Admin';

    // Resolve the TL's employee_code and name from the users table
    final tlInfo = await _resolveTLInfo(profile['team_leader'] ?? '');
    if (tlInfo['code']!.isEmpty) {
      _resolvedTLCode = profile['employee_code'];
      _resolvedTLName = profile['name'];
    } else {
      _resolvedTLCode = tlInfo['code']!;
      _resolvedTLName = tlInfo['name']!;
    }
    profile['team_leader_name'] = _resolvedTLName;

    final screens = <Widget>[];
    final navItems = <BottomNavigationBarItem>[];

    // Everyone gets Report Form
    screens.add(
      ReportFormScreen(
        employeeCode: profile['employee_code'] ?? 'N/A', 
        assignedTL: _resolvedTLName,
        assignedTLCode: _resolvedTLCode,
        empName: profile['name'] ?? 'Unknown',
        contactNo: profile['contact_no'] ?? 'N/A',
      )
    );
    navItems.add(BottomNavigationBarItem(icon: Icon(Icons.add_task), label: 'Report'));

    if (isTL) {
      // TLs and Admins manage teams. Pass employee_code for team filtering.
      screens.add(ManageEmployeesScreen(
        tlName: profile['name'],
        tlCode: profile['employee_code'],
      ));
      navItems.add(BottomNavigationBarItem(icon: Icon(Icons.groups), label: 'My Team'));
    }

    // Everyone gets History
    screens.add(ReportHistoryScreen(employeeCode: profile['employee_code']));
    navItems.add(BottomNavigationBarItem(icon: Icon(Icons.history), label: 'History'));

    // TL Review Panel
    if (isTL) {
      screens.add(TLDashboardScreen(tlCode: profile['employee_code']));
      navItems.add(BottomNavigationBarItem(icon: Icon(Icons.admin_panel_settings), label: 'TL Review'));
    }

    // Admin Dashboard
    if (isAdmin) {
      screens.add(AdminDashboardScreen());
      navItems.add(BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Admin'));
    }

    // App Admin Settings
    if (isAppAdmin) {
      screens.add(AppSettingsScreen());
      navItems.add(BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'));
    }

    // Profile for everyone
    screens.add(ProfileScreen(userProfile: profile));
    navItems.add(BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'));

    if (mounted) {
      setState(() {
        _screens = screens;
        _navItems = navItems;
      });
    }
  }

  /// Resolves the Team Leader's employee_code and name.
  /// Supports both pre-migration (name) and post-migration (code) data.
  Future<Map<String, String>> _resolveTLInfo(String teamLeaderValue) async {
    if (teamLeaderValue.isEmpty) return {'code': '', 'name': 'None'};
    try {
      // First try: team_leader already stores an employee_code
      final byCode = await Supabase.instance.client
          .from('users')
          .select('employee_code, name')
          .eq('employee_code', teamLeaderValue.trim())
          .maybeSingle();
      if (byCode != null) return {'code': byCode['employee_code'], 'name': byCode['name']};

      // Fallback: team_leader stores a name (pre-migration)
      final byName = await Supabase.instance.client
          .from('users')
          .select('employee_code, name')
          .eq('name', teamLeaderValue.trim())
          .maybeSingle();
      if (byName != null) return {'code': byName['employee_code'], 'name': byName['name']};
    } catch (e) {
      print('Error resolving TL info: $e');
    }
    return {'code': teamLeaderValue, 'name': teamLeaderValue}; // Return as-is if unresolvable
  }

  void _showNotifications(BuildContext context, NotificationProvider provider) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Text('Notifications', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Divider(),
            Expanded(
              child: provider.notifications.isEmpty
                  ? Center(child: Text('No new notifications'))
                  : ListView.builder(
                      itemCount: provider.notifications.length,
                      itemBuilder: (context, index) => ListTile(
                        leading: Icon(Icons.info_outline, color: Colors.indigo),
                        title: Text(provider.notifications[index]),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final navProvider = Provider.of<NotificationProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Image.asset('assets/images/faith_logo.png', height: 24),
            ),
            SizedBox(width: 12),
            Text('Faith Hours', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () async {
              final storage = const FlutterSecureStorage();
              await storage.delete(key: 'user_profile');
              await Supabase.instance.client.auth.signOut();
              
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => AuthWrapper()),
                (route) => false,
              );
            },
          ),
          Stack(
            children: [
              IconButton(
                icon: Icon(Icons.notifications),
                onPressed: () {
                  final String identifier = widget.userProfile['employee_code'];
                  navProvider.markAsRead(identifier);
                  _showNotifications(context, navProvider);
                },
              ),
              if (navProvider.hasUnread)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: EdgeInsets.all(2),
                    decoration: BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                    constraints: BoxConstraints(minWidth: 12, minHeight: 12),
                  ),
                )
            ],
          )
        ],
      ),
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        type: BottomNavigationBarType.fixed,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: _navItems,
      ),
    );
  }
}
