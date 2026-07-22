import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/report.dart';
import '../services/export_service.dart';
import '../widgets/skeleton_loader.dart';
import 'manage_employees_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  @override
  _AdminDashboardScreenState createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final supabase = Supabase.instance.client;
  final ExportService _exportService = ExportService();
  
  bool _isLoading = true;
  int _totalEmployees = 0;
  int _pendingApprovals = 0;
  List<Report> _allReports = [];
  List<Map<String, dynamic>> _allProjects = [];

  @override
  void initState() {
    super.initState();
    _fetchAdminData();
  }

  Future<void> _fetchAdminData() async {
    setState(() => _isLoading = true);
    try {
      // 1. Get total users
      final userCount = await supabase.from('users').select('id').count(CountOption.exact);
      
      // 2. Get pending reports count
      final pendingCount = await supabase.from('reports').select('id').eq('status', 'Pending').count(CountOption.exact);

      // 3. Get all approved reports (no limit) for the export pivot table
      final reportsData = await supabase.from('reports').select().eq('status', 'Approved');

      // 4. Get all projects
      final projectsData = await supabase.from('projects').select('project_number, description');

      setState(() {
        _totalEmployees = userCount.count ?? 0;
        _pendingApprovals = pendingCount.count ?? 0;
        _allReports = (reportsData as List).map((r) => Report.fromJson(r)).toList();
        _allProjects = List<Map<String, dynamic>>.from(projectsData);
        _isLoading = false;
      });
    } catch (e) {
      print('Admin Data Error: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleExport() async {
    String? path = await _exportService.exportReportsToCsv(_allReports, _allProjects);
    if (path != null) {
      if (path.startsWith("ERROR:")) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: $path'), backgroundColor: Colors.red),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Reports exported to: $path'), backgroundColor: Colors.green),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Admin Dashboard'), automaticallyImplyLeading: false),
      body: _isLoading 
        ? ListSkeleton()
        : Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatCard("Total Employees", _totalEmployees.toString(), Icons.people, Colors.blue),
                SizedBox(height: 16),
                _buildStatCard("Pending Approvals", _pendingApprovals.toString(), Icons.pending, Colors.orange),
                SizedBox(height: 32),
                Text("Management Actions", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Divider(),
                ListTile(
                  leading: Icon(Icons.file_download, color: Colors.green),
                  title: Text("Export Project Workload Tracking Sheet"),
                  subtitle: Text("Generate pivot table CSV of all project hours"),
                  onTap: _handleExport,
                ),
                ListTile(
                  leading: Icon(Icons.manage_accounts, color: Colors.indigo),
                  title: Text("Manage Employee Profiles"),
                  subtitle: Text("Edit roles and team leaders"),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ManageEmployeesScreen(tlName: '', tlCode: '', isAdmin: true),
                      ),
                    );
                  },
                ),
                Spacer(),
                Center(
                  child: TextButton.icon(
                    onPressed: _fetchAdminData, 
                    icon: Icon(Icons.refresh), 
                    label: Text("Refresh Metrics")
                  ),
                )
              ],
            ),
          ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Row(
          children: [
            CircleAvatar(backgroundColor: color.withOpacity(0.1), child: Icon(icon, color: color)),
            SizedBox(width: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: Colors.grey)),
                Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              ],
            )
          ],
        ),
      ),
    );
  }
}
