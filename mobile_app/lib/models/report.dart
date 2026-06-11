class Report {
  final int? id;
  final String employeeCode;
  final String empName;
  final String contactNo;
  final String date;
  final String department;
  final String subtitle;
  final String workingDetails;
  final String startTime;
  final String endTime;
  final String hoursCalculate;
  final String teamLeader;
  final String teamLeaderCode;
  final String projectNumber;
  final String status;
  final String? tlComments;

  Report({
    this.id,
    required this.employeeCode,
    required this.empName,
    required this.contactNo,
    required this.date,
    required this.department,
    required this.subtitle,
    required this.workingDetails,
    required this.startTime,
    required this.endTime,
    required this.hoursCalculate,
    required this.teamLeader,
    required this.teamLeaderCode,
    required this.projectNumber,
    this.status = 'Pending',
    this.tlComments,
  });

  factory Report.fromJson(Map<String, dynamic> json) {
    return Report(
      id: json['id'],
      employeeCode: json['employee_code']?.toString() ?? 'N/A',
      empName: json['emp_name']?.toString() ?? 'Unknown',
      contactNo: json['contact_no']?.toString() ?? 'N/A',
      date: json['date']?.toString() ?? '',
      department: json['department']?.toString() ?? '',
      subtitle: json['subtitle']?.toString() ?? '',
      workingDetails: json['working_details']?.toString() ?? '',
      startTime: json['start_time']?.toString() ?? '',
      endTime: json['end_time']?.toString() ?? '',
      hoursCalculate: json['hours_calculate']?.toString() ?? '0:00',
      teamLeader: json['team_leader']?.toString() ?? 'None',
      teamLeaderCode: json['team_leader_code']?.toString() ?? '',
      projectNumber: json['project_number']?.toString() ?? '',
      status: json['status']?.toString() ?? 'Pending',
      tlComments: json['tl_comments']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'employee_code': employeeCode,
      'emp_name': empName,
      'contact_no': contactNo,
      'date': date,
      'department': department,
      'subtitle': subtitle,
      'working_details': workingDetails,
      'start_time': startTime,
      'end_time': endTime,
      'hours_calculate': hoursCalculate,
      'team_leader': teamLeader,
      'team_leader_code': teamLeaderCode,
      'project_number': projectNumber,
      'status': status,
    };
  }
}
