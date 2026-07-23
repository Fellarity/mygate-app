import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/report.dart';
import '../services/report_service.dart';
import '../widgets/skeleton_loader.dart';
import 'report_detail_screen.dart';

class TLDashboardScreen extends StatefulWidget {
  final String tlCode;
  TLDashboardScreen({required this.tlCode});

  @override
  _TLDashboardScreenState createState() => _TLDashboardScreenState();
}

class _TLDashboardScreenState extends State<TLDashboardScreen> {
  final ReportService _reportService = ReportService();
  List<Report> _pendingReports = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchReports();
  }

  Future<void> _fetchReports() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      // Filtering by the TL's unique employee_code instead of name
      final reports = await _reportService.getPendingReports(widget.tlCode.trim());
      if (mounted) {
        setState(() {
          _pendingReports = reports;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _navigateToDetail(Report report) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReportDetailScreen(
          report: report,
          showReviewActions: true,
          onReview: (status, comments) async {
            bool success = await _reportService.reviewReport(report.id!, status, comments);
            if (success) {
              Navigator.pop(context); // Go back from detail screen
              _fetchReports(); // Refresh list
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Report $status successfully')),
              );
            }
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Pending Reviews'), 
        automaticallyImplyLeading: false,
        actions: [
          IconButton(icon: Icon(Icons.refresh), onPressed: _fetchReports)
        ],
      ),
      body: _isLoading
          ? ListSkeleton()
          : _pendingReports.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.done_all, size: 64, color: Colors.green),
                      SizedBox(height: 16),
                      Text('No pending reports for your team'),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _pendingReports.length,
                  itemBuilder: (context, index) {
                    final r = _pendingReports[index];
                    return Card(
                      margin: EdgeInsets.all(8),
                      child: ListTile(
                        title: Text('${r.empName} - ${r.date}'),
                        subtitle: Text('${r.projectNumber}: ${r.workingDetails}', maxLines: 1, overflow: TextOverflow.ellipsis),
                        trailing: Icon(Icons.chevron_right, color: Colors.indigo),
                        onTap: () => _navigateToDetail(r),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          final _projectController = TextEditingController();
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text('Add New Project'),
              content: TextField(
                controller: _projectController,
                decoration: InputDecoration(
                  labelText: 'Project Number',
                  hintText: 'e.g. PRJ-1001',
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final newProject = _projectController.text.trim();
                    if (newProject.isNotEmpty) {
                      try {
                        await Supabase.instance.client
                            .from('projects')
                            .insert({'project_number': newProject});
                        if (mounted) Navigator.pop(context);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Project added successfully')),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error adding project: \$e')),
                          );
                        }
                      }
                    }
                  },
                  child: Text('Add'),
                ),
              ],
            ),
          );
        },
        child: Icon(Icons.add_task),
        tooltip: 'Add New Project',
      ),
    );
  }
}
