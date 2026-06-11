import 'package:flutter/material.dart';
import '../models/report.dart';

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
            _buildSectionTitle('Work Details'),
            _buildDetailTile(Icons.calendar_today, 'Date', report.date),
            _buildDetailTile(Icons.topic, 'Subtitle', report.subtitle),
            _buildDetailTile(Icons.work, 'Project No.', report.projectNumber),
            _buildDetailTile(Icons.timer, 'Hours', '${report.startTime} - ${report.endTime} (${report.hoursCalculate})'),
            
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
            SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusHeader() {
    Color color = Colors.orange;
    if (report.status == 'Approve' || report.status == 'Approved') color = Colors.green;
    if (report.status == 'Rejected') color = Colors.red;

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
