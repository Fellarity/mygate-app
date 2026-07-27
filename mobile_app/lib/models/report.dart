class ReportProject {
  final String projectNumber;
  final String startTime;
  final String endTime;
  final String hours;

  ReportProject({
    required this.projectNumber,
    required this.startTime,
    required this.endTime,
    required this.hours,
  });

  factory ReportProject.fromJson(Map<String, dynamic> json) {
    return ReportProject(
      projectNumber: json['project_number']?.toString() ?? '',
      startTime: json['start_time']?.toString() ?? '',
      endTime: json['end_time']?.toString() ?? '',
      hours: json['hours']?.toString() ?? '0',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'project_number': projectNumber,
      'start_time': startTime,
      'end_time': endTime,
      'hours': hours,
    };
  }
}

class Report {
  final int? id;
  final String employeeCode;
  final String empName;
  final String contactNo;
  final String date;
  final String department;
  final String subtitle;
  final String workingDetails;
  
  // Legacy fields (kept for backward compatibility with old reports)
  final String startTime;
  final String endTime;
  final String hoursCalculate;
  final String projectNumber;
  
  // New multiple projects list
  final List<ReportProject> projects;

  final String teamLeader;
  final String teamLeaderCode;
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
    this.startTime = '',
    this.endTime = '',
    required this.hoursCalculate,
    required this.teamLeader,
    required this.teamLeaderCode,
    this.projectNumber = '',
    this.projects = const [],
    this.status = 'Pending',
    this.tlComments,
  });

  factory Report.fromJson(Map<String, dynamic> json) {
    List<ReportProject> parsedProjects = [];
    if (json['projects'] != null) {
      if (json['projects'] is List) {
        parsedProjects = (json['projects'] as List).map((p) => ReportProject.fromJson(p)).toList();
      }
    }

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
      projects: parsedProjects,
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
      'projects': projects.map((p) => p.toJson()).toList(),
      'status': status,
    };
  }
}
