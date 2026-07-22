import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'report_history_screen.dart';

class EmployeeProfileDetailScreen extends StatefulWidget {
  final Map<String, dynamic> employeeData;

  EmployeeProfileDetailScreen({required this.employeeData});

  @override
  _EmployeeProfileDetailScreenState createState() => _EmployeeProfileDetailScreenState();
}

class _EmployeeProfileDetailScreenState extends State<EmployeeProfileDetailScreen> {
  final _supabase = Supabase.instance.client;
  String _totalHours = "0:00";
  bool _isLoadingHours = true;

  @override
  void initState() {
    super.initState();
    _calculateTotalHours();
  }

  Future<void> _calculateTotalHours() async {
    try {
      final now = DateTime.now();
      final firstDay = DateTime(now.year, now.month, 1).toIso8601String().split('T')[0];
      final lastDay = DateTime(now.year, now.month + 1, 0).toIso8601String().split('T')[0];

      final response = await _supabase
          .from('reports')
          .select('hours_calculate')
          .eq('employee_code', widget.employeeData['employee_code'])
          .inFilter('status', ['Approve', 'Approved'])
          .gte('date', firstDay)
          .lte('date', lastDay);

      if (response != null) {
        int totalMinutes = 0;
        for (var row in response) {
          final hoursStr = row['hours_calculate']?.toString();
          if (hoursStr != null && hoursStr.contains(':')) {
            final parts = hoursStr.split(':');
            if (parts.length == 2) {
              totalMinutes += (int.tryParse(parts[0]) ?? 0) * 60;
              totalMinutes += (int.tryParse(parts[1]) ?? 0);
            }
          }
        }

        final hours = totalMinutes ~/ 60;
        final mins = totalMinutes % 60;
        if (mounted) {
          setState(() {
            _totalHours = '$hours:${mins.toString().padLeft(2, '0')}';
            _isLoadingHours = false;
          });
        }
      }
    } catch (e) {
      print('Error calculating hours: $e');
      if (mounted) setState(() => _isLoadingHours = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final emp = widget.employeeData;
    
    return Scaffold(
      appBar: AppBar(
        title: Text('${emp['name']} Profile'),
        backgroundColor: Colors.indigo.shade800,
        foregroundColor: Colors.white,
      ),
      body: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            // Profile Summary Header
            Container(
              padding: EdgeInsets.all(20),
              color: Colors.indigo.shade50,
              child: Column(
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.indigo,
                        child: Text(
                          emp['name']?[0] ?? '?',
                          style: TextStyle(fontSize: 24, color: Colors.white),
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(emp['name'] ?? 'Unknown', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                            Text('ID: ${emp['employee_code']}', style: TextStyle(color: Colors.grey.shade700)),
                            Text('Contact: ${emp['contact_no']}', style: TextStyle(color: Colors.grey.shade700)),
                            Text('Dept: ${emp['department']}', style: TextStyle(color: Colors.grey.shade700)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  // Total Hours Card
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.timer, color: Colors.indigo),
                          SizedBox(width: 12),
                          Text('Approved Hours This Month:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade700)),
                          SizedBox(width: 12),
                          _isLoadingHours
                              ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                              : Text(_totalHours, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.indigo.shade900)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // TabBar
            Container(
              color: Colors.white,
              child: TabBar(
                labelColor: Colors.indigo,
                unselectedLabelColor: Colors.grey,
                indicatorColor: Colors.indigo,
                tabs: [
                  Tab(text: 'Report History', icon: Icon(Icons.history)),
                  Tab(text: 'Analytics', icon: Icon(Icons.bar_chart)),
                ],
              ),
            ),
            
            // Tab Views
            Expanded(
              child: TabBarView(
                children: [
                  // Tab 1: History
                  ReportHistoryScreen(employeeCode: emp['employee_code'], hideAppBar: true),
                  
                  // Tab 2: Future Analytics
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.insert_chart_outlined, size: 64, color: Colors.grey.shade300),
                        SizedBox(height: 16),
                        Text('Analytics coming soon', style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
