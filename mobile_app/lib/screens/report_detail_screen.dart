import 'package:flutter/material.dart';
import '../models/report.dart';
import '../services/report_service.dart';
import 'report_form_screen.dart';

class ReportDetailScreen extends StatelessWidget {
  final Report report;
  final bool showReviewActions;
  final Function(String status, String comments)? onReview;

  ReportDetailScreen({
    required this.report,
    this.showReviewActions = false,
    this.onReview,
  });

  @override
  Widget build(BuildContext context) {
    String comments = '';

    return Scaffold(
      appBar: AppBar(
        title: Text('Report Details'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatusHeader(),
            SizedBox(height: 20),
            _buildSectionTitle('Employee Information'),
            _buildDetailTile(Icons.person, 'Name', report.empName),
            _buildDetailTile(Icons.badge, 'ID', report.employeeCode),
            _buildDetailTile(Icons.phone, 'Contact', report.contactNo),
            _buildDetailTile(Icons.business, 'Department', report.department),
            
            Divider(height: 32),
            _buildSectionTitle('Work Details (Total: ${report.hoursCalculate} hrs)'),
            _buildDetailTile(Icons.calendar_today, 'Date', report.date),
            _buildDetailTile(Icons.topic, 'Subtitle', report.subtitle),
            
            SizedBox(height: 16),
            if (report.projects.isNotEmpty) ...[
              Text('Projects:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade700)),
              SizedBox(height: 8),
              ...report.projects.map((p) => Container(
                margin: EdgeInsets.only(bottom: 8),
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.indigo.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.indigo.shade100),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.work, size: 16, color: Colors.indigo),
                        SizedBox(width: 8),
                        Text(p.projectNumber, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)),
                      ],
                    ),
                    SizedBox(height: 4),
                    Text('${p.startTime} - ${p.endTime} (${p.hours} hrs)', style: TextStyle(color: Colors.grey.shade700)),
                  ],
                ),
              )).toList(),
            ] else ...[
              _buildDetailTile(Icons.work, 'Project No.', report.projectNumber),
              _buildDetailTile(Icons.timer, 'Hours', '${report.startTime} - ${report.endTime} (${report.hoursCalculate})'),
            ],
            
            SizedBox(height: 16),
            Text('Working Details:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade700)),
            Container(
              width: double.infinity,
              margin: EdgeInsets.only(top: 8),
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Text(report.workingDetails, style: TextStyle(fontSize: 16)),
            ),

            if (report.tlComments != null && report.tlComments!.isNotEmpty) ...[
              Divider(height: 32),
              _buildSectionTitle('Team Leader Comments'),
              Text(report.tlComments!, style: TextStyle(fontStyle: FontStyle.italic)),
            ],

            if (showReviewActions && onReview != null) ...[
              SizedBox(height: 40),
              _buildSectionTitle('Review Submission'),
              TextField(
                decoration: InputDecoration(
                  labelText: 'Comments (Optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
                onChanged: (v) => comments = v,
              ),
              SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => onReview!('Rejected', comments),
                      child: Text('Reject'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: BorderSide(color: Colors.red),
                        padding: EdgeInsets.symmetric(vertical: 15),
                      ),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => onReview!('Approve', comments),
                      child: Text('Approve'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 15),
                      ),
                    ),
                  ),
                ],
              ),
            ],
            
            if (!showReviewActions) ...[
              SizedBox(height: 40),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: Icon(Icons.edit),
                      label: Text('Edit'),
                      onPressed: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => ReportFormScreen(
                            employeeCode: report.employeeCode,
                            assignedTL: report.teamLeader,
                            assignedTLCode: report.teamLeaderCode,
                            empName: report.empName,
                            contactNo: report.contactNo,
                            existingReport: report,
                          )),
                        );
                        if (result == true) {
                          Navigator.pop(context, true); // Pop back to history to refresh
                        }
                      },
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 15),
                      ),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: Icon(Icons.delete),
                      label: Text('Delete'),
                      onPressed: () async {
                        bool confirm = await showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text('Delete Report'),
                            content: Text('Are you sure you want to delete this report?'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Cancel')),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true), 
                                child: Text('Delete', style: TextStyle(color: Colors.red)),
                              ),
                            ],
                          ),
                        ) ?? false;
                        
                        if (confirm && report.id != null) {
                          final success = await ReportService().deleteReport(report.id!);
                          if (success) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Report deleted.')));
                            Navigator.pop(context, true);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error deleting report.')));
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 15),
                      ),
                    ),
                  ),
                ],
              ),
            ],
            
            SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusHeader() {
    Color color = Colors.orange;
    String statusStr = report.status.toLowerCase();
    
    if (statusStr.contains('approve')) {
      color = Colors.green;
    } else if (statusStr.contains('reject')) {
      color = Colors.red;
    }

    return Container(
      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.info_outline, color: color, size: 20),
          SizedBox(width: 8),
          Text(
            'Status: ${report.status}',
            style: TextStyle(color: color, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        title,
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.indigo),
      ),
    );
  }

  Widget _buildDetailTile(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey),
          SizedBox(width: 8),
          Text('$label: ', style: TextStyle(fontWeight: FontWeight.w600)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
