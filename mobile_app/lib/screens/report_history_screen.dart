import 'package:flutter/material.dart';
import '../models/report.dart';
import '../services/report_service.dart';
import '../widgets/skeleton_loader.dart';
import 'report_detail_screen.dart';

class ReportHistoryScreen extends StatelessWidget {
  final String employeeCode;
  final bool hideAppBar;
  ReportHistoryScreen({required this.employeeCode, this.hideAppBar = false});

  final ReportService _reportService = ReportService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: hideAppBar ? null : AppBar(title: Text('My Report History'), automaticallyImplyLeading: false),
      body: FutureBuilder<List<Report>>(
        future: _reportService.getEmployeeReports(employeeCode),
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
              if (r.status == 'Approve' || r.status == 'Approved') statusColor = Colors.green;
              if (r.status == 'Rejected') statusColor = Colors.red;

              return Card(
                margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: ListTile(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ReportDetailScreen(report: r)),
                  ),
                  title: Text('${r.date} - ${r.projectNumber}'),
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
