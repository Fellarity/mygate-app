import 'package:flutter_test/flutter_test.dart';
import 'package:faith_hours/models/report.dart';

void main() {
  group('Report Model Tests', () {
    test('fromJson should parse correctly', () {
      final json = {
        'id': 1,
        'employee_code': 'EMP001',
        'date': '2026-06-29',
        'department': 'Engineering',
        'working_details': 'Fixed a bug',
        'start_time': '09:00 AM',
        'end_time': '05:00 PM',
        'team_leader': 'TL-John',
        'team_leader_code': 'TL001',
        'project_number': 'FA-241',
        'status': 'Approved',
        'tl_comments': 'Good job',
        'emp_name': 'Alice',
        'contact_no': '1234567890',
        'subtitle': 'N/A',
        'hours_calculate': '8:00',
      };

      final report = Report.fromJson(json);

      expect(report.id, 1);
      expect(report.employeeCode, 'EMP001');
      expect(report.date, '2026-06-29');
      expect(report.department, 'Engineering');
      expect(report.workingDetails, 'Fixed a bug');
      expect(report.startTime, '09:00 AM');
      expect(report.endTime, '05:00 PM');
      expect(report.teamLeader, 'TL-John');
      expect(report.status, 'Approved');
      expect(report.tlComments, 'Good job');
      expect(report.empName, 'Alice');
      expect(report.contactNo, '1234567890');
      expect(report.subtitle, 'N/A');
      expect(report.hoursCalculate, '8:00');
      expect(report.subtitle, 'N/A');
      expect(report.hoursCalculate, '8:00');
    });

    test('toJson should serialize correctly', () {
      final report = Report(
        id: 1,
        employeeCode: 'EMP001',
        date: '2026-06-29',
        department: 'Engineering',
        workingDetails: 'Fixed a bug',
        startTime: '09:00 AM',
        endTime: '05:00 PM',
        teamLeader: 'TL-John',
        teamLeaderCode: 'TL001',
        projectNumber: 'FA-241',
        status: 'Approved',
        empName: 'Alice',
        contactNo: '1234567890',
        subtitle: 'N/A',
        hoursCalculate: '8:00',
      );

      final json = report.toJson();

      // Note: id, status, and tlComments are not serialized in toJson
      // because they are handled by the database (auto-increment, defaults, triggers).
      expect(json['employee_code'], 'EMP001');
      expect(json['date'], '2026-06-29');
      expect(json['department'], 'Engineering');
      expect(json['working_details'], 'Fixed a bug');
      expect(json['start_time'], '09:00 AM');
      expect(json['end_time'], '05:00 PM');
      expect(json['team_leader'], 'TL-John');
      expect(json['team_leader_code'], 'TL001');
      expect(json['project_number'], 'FA-241');
      expect(json['emp_name'], 'Alice');
      expect(json['contact_no'], '1234567890');
      expect(json['subtitle'], 'N/A');
      expect(json['hours_calculate'], '8:00');
      
      // Ensure excluded fields are not present
      expect(json.containsKey('id'), false);
      expect(json.containsKey('tl_comments'), false);
    });

    test('fromJson handles null values gracefully', () {
      final json = {
        'employee_code': 'EMP001',
        'date': '2026-06-29',
        'department': 'Engineering',
        'start_time': '09:00 AM',
        'end_time': '05:00 PM',
        'project_number': 'FA-241',
      };

      final report = Report.fromJson(json);

      expect(report.workingDetails, '');
      expect(report.teamLeader, 'None');
      expect(report.status, 'Pending');
      expect(report.empName, 'Unknown');
    });
  });
}
