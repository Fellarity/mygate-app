import 'package:flutter/material.dart';
import '../models/report.dart';
import '../services/report_service.dart';
import '../widgets/skeleton_loader.dart';
import 'report_detail_screen.dart';

class ReportHistoryScreen extends StatefulWidget {
  final String employeeCode;
  final bool hideAppBar;
  ReportHistoryScreen({required this.employeeCode, this.hideAppBar = false});

  @override
  _ReportHistoryScreenState createState() => _ReportHistoryScreenState();
}

class _ReportHistoryScreenState extends State<ReportHistoryScreen> {
  final ReportService _reportService = ReportService();
  late Future<List<Report>> _reportsFuture;

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  void _loadReports() {
    _reportsFuture = _reportService.getEmployeeReports(widget.employeeCode);
  }

  void _refresh() {
    setState(() {
      _loadReports();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.hideAppBar ? null : AppBar(title: Text('My Report History'), automaticallyImplyLeading: false),
      body: FutureBuilder<List<Report>>(
        future: _reportsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return ListSkeleton();
          }
          if (snapshot.hasError) {
            return Center(child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, color: Colors.red, size: 60),
                Text('Error loading history: ${snapshot.error}'),
              ],
            ));
          }
          
          final reports = snapshot.data ?? [];
          if (reports.isEmpty) return Center(child: Text('No reports found.'));

          return ListView.builder(
            itemCount: reports.length,
            itemBuilder: (context, index) {
              final r = reports[index];
              Color statusColor = Colors.orange;
              String statusStr = r.status.toLowerCase();
              if (statusStr.contains('approve')) statusColor = Colors.green;
              if (statusStr.contains('reject')) statusColor = Colors.red;

              String displayProject = r.projects.length > 1 ? 'Multiple Projects' : r.projectNumber;

              return Card(
                margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: ListTile(
                  onTap: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => ReportDetailScreen(report: r)),
                    );
                    if (result == true) {
                      _refresh();
                    }
                  },
                  title: Text('${r.date} - $displayProject'),
                  subtitle: Text(r.workingDetails, maxLines: 2, overflow: TextOverflow.ellipsis),
                  trailing: Container(
                    padding: EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(
                      r.status,
                      style: TextStyle(color: statusColor, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
