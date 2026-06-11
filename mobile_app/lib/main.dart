import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/report_form_screen.dart';
import 'screens/report_history_screen.dart';
import 'screens/tl_dashboard_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/admin_dashboard_screen.dart';
import 'providers/notification_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Supabase.initialize(
    url: 'https://eeayjyxzyuxbpmmrxmoc.supabase.co',
    anonKey: 'sb_publishable_d9AZZWdgrsO5aoR-U1h6Uw_1QB6OQ1a',
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
      ],
      child: OfficeGateApp(),
    ),
  );
}

class OfficeGateApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OfficeGate',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        visualDensity: VisualDensity.adaptivePlatformDensity,
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

  void _handleLogin(Map<String, dynamic> profile) {
    setState(() {
      _userProfile = profile;
    });

    final String notificationIdentifier = profile['employee_code'];

    Provider.of<NotificationProvider>(context, listen: false)
        .initNotifications(notificationIdentifier);
  }

  @override
  Widget build(BuildContext context) {
    if (_userProfile == null) {
      return SignupScreen(onLoginComplete: _handleLogin);
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

  @override
  void initState() {
    super.initState();
    final profile = widget.userProfile;
    final bool isTL = profile['role'] == 'Team Leader' || profile['role'] == 'Admin';
    final bool isAdmin = profile['role'] == 'Admin';

    // We now pass the assigned Team Leader's name AND code for accurate routing
    // In a real database, users.team_leader would ideally store the TL's code.
    // Since it currently stores the Name, we use it for display, and we'll refine the routing.
    
    _screens = [
      ReportFormScreen(
        employeeCode: profile['employee_code'] ?? 'N/A', 
        assignedTL: profile['team_leader'] ?? 'None',
        assignedTLCode: 'TL001', // Mock for now, ideally fetched during login lookup
        empName: profile['name'] ?? 'Unknown',
        contactNo: profile['contact_no'] ?? 'N/A',
      ),
      ReportHistoryScreen(employeeCode: profile['employee_code']),
    ];

    if (isTL) {
      _screens.add(TLDashboardScreen(tlCode: profile['employee_code']));
    }

    if (isAdmin) {
      _screens.add(AdminDashboardScreen());
    }

    _screens.add(ProfileScreen(userProfile: profile));

    _navItems = [
      BottomNavigationBarItem(icon: Icon(Icons.add_task), label: 'Report'),
      BottomNavigationBarItem(icon: Icon(Icons.history), label: 'History'),
    ];

    if (isTL) {
      _navItems.add(BottomNavigationBarItem(icon: Icon(Icons.admin_panel_settings), label: 'TL Review'));
    }

    if (isAdmin) {
      _navItems.add(BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Admin'));
    }

    _navItems.add(BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'));
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
        title: Text('OfficeGate'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () => Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => AuthWrapper()),
              (route) => false,
            ),
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
