import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/report.dart';

class ReportService {
  final supabase = Supabase.instance.client;

  Future<bool> submitReport(Report report) async {
    try {
      await supabase.from('reports').insert(report.toJson());
      return true;
    } catch (e) {
      print('Error submitting report: $e');
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
      return true;
    } catch (e) {
      print('Error reviewing report: $e');
      return false;
    }
  }
}
