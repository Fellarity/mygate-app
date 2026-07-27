import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/report.dart';

class ReportService {
  final supabase = Supabase.instance.client;

  Future<bool> submitReport(Report report) async {
    try {
      await supabase.from('reports').insert(report.toJson());
      
      // Update contact number in users table
      await supabase.from('users').update({'contact_no': report.contactNo}).eq('employee_code', report.employeeCode);

      // Check if email notifications are enabled
      final settings = await supabase.from('app_settings').select('setting_value').eq('setting_key', 'notifications').maybeSingle();
      if (settings != null && settings['setting_value'] != null && settings['setting_value']['email_enabled'] == true) {
        // Fetch TL Email
        final tlUser = await supabase.from('users').select('email').eq('employee_code', report.teamLeaderCode).maybeSingle();
        if (tlUser != null && tlUser['email'] != null) {
          final tlEmail = tlUser['email'];
          
          try {
            await supabase.functions.invoke('send-email', body: {
              'to': tlEmail,
              'subject': 'New Timesheet Submitted by ${report.empName}',
              'body': '''
                <h3>New Timesheet Submission</h3>
                <p><strong>Employee:</strong> ${report.empName} (${report.employeeCode})</p>
                <p><strong>Date:</strong> ${report.date}</p>
                <p><strong>Total Hours:</strong> ${report.hoursCalculate}</p>
                <br>
                <p>Please log in to the App to approve or reject this timesheet.</p>
              '''
            });
            print("Email notification sent to TL");
          } catch (funcErr) {
            print("Edge function error: $funcErr");
          }
        }
      }
      
      return true;
    } catch (e) {
      print('Error submitting report: $e');
      return false;
    }
  }

  Future<bool> updateReport(Report report) async {
    try {
      if (report.id == null) return false;
      await supabase.from('reports').update(report.toJson()).eq('id', report.id!);
      
      // Update contact number in users table
      await supabase.from('users').update({'contact_no': report.contactNo}).eq('employee_code', report.employeeCode);

      return true;
    } catch (e) {
      print('Error updating report: $e');
      return false;
    }
  }

  Future<bool> deleteReport(int id) async {
    try {
      await supabase.from('reports').delete().eq('id', id);
      return true;
    } catch (e) {
      print('Error deleting report: $e');
      return false;
    }
  }

  Future<List<Report>> getEmployeeReports(String employeeCode) async {
    try {
      final response = await supabase
          .from('reports')
          .select()
          .eq('employee_code', employeeCode)
          .order('submitted_at', ascending: false);
      
      return (response as List).map((data) => Report.fromJson(data)).toList();
    } catch (e) {
      print('Error fetching history: $e');
      return [];
    }
  }

  Future<List<Report>> getPendingReports(String tlCode) async {
    try {
      final response = await supabase
          .from('reports')
          .select()
          .eq('team_leader_code', tlCode)
          .eq('status', 'Pending');
      
      return (response as List).map((data) => Report.fromJson(data)).toList();
    } catch (e) {
      print('Error fetching pending: $e');
      return [];
    }
  }

  Future<bool> reviewReport(int reportId, String status, String comments) async {
    try {
      await supabase.from('reports').update({
        'status': status,
        'tl_comments': comments,
        'reviewed_at': DateTime.now().toIso8601String(),
      }).eq('id', reportId);
      
      // Check if email notifications are enabled
      final settings = await supabase.from('app_settings').select('setting_value').eq('setting_key', 'notifications').maybeSingle();
      if (settings != null && settings['setting_value'] != null && settings['setting_value']['email_enabled'] == true) {
        // Fetch Report to get Employee Code
        final report = await supabase.from('reports').select('employee_code, date, hours_calculate').eq('id', reportId).maybeSingle();
        if (report != null) {
          // Fetch Employee Email
          final empUser = await supabase.from('users').select('email, full_name').eq('employee_code', report['employee_code']).maybeSingle();
          if (empUser != null && empUser['email'] != null) {
            try {
              await supabase.functions.invoke('send-email', body: {
                'to': empUser['email'],
                'subject': 'Timesheet $status: ${report["date"]}',
                'body': '''
                  <h3>Timesheet $status</h3>
                  <p>Hi ${empUser["full_name"]},</p>
                  <p>Your timesheet for <strong>${report["date"]}</strong> (${report["hours_calculate"]} hrs) has been <strong>$status</strong>.</p>
                  <p><strong>Team Leader Comments:</strong> $comments</p>
                  <br>
                  <p>Please log in to the App to view details.</p>
                '''
              });
              print("Email notification sent to Employee");
            } catch (funcErr) {
              print("Edge function error: $funcErr");
            }
          }
        }
      }

      return true;
    } catch (e) {
      print('Error reviewing report: $e');
      return false;
    }
  }

  Future<double> fetchCurrentMonthHours(String employeeCode) async {
    try {
      final now = DateTime.now();
      final firstDay = DateTime(now.year, now.month, 1).toIso8601String().split('T')[0];
      final lastDay = DateTime(now.year, now.month + 1, 0).toIso8601String().split('T')[0];

      final response = await supabase
          .from('reports')
          .select('hours_calculate')
          .eq('employee_code', employeeCode)
          .ilike('status', 'approve%') // Supports Approve or Approved
          .gte('date', firstDay)
          .lte('date', lastDay);
      
      double totalHours = 0;
      for (var row in response) {
        final hoursStr = row['hours_calculate']?.toString() ?? '0';
        totalHours += double.tryParse(hoursStr) ?? 0.0;
      }
      return totalHours;
    } catch (e) {
      print('Error fetching monthly hours: $e');
      return 0.0;
    }
  }
}
