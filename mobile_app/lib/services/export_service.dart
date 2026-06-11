import 'dart:io';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import '../models/report.dart';

class ExportService {
  Future<String?> exportReportsToCsv(List<Report> reports) async {
    List<List<dynamic>> rows = [];

    // Header
    rows.add([
      "Date",
      "Employee Name",
      "Employee Code",
      "Department",
      "Project Number",
      "Working Details",
      "Hours",
      "Team Leader",
      "Status"
    ]);

    for (var r in reports) {
      rows.add([
        r.date,
        r.empName,
        r.employeeCode,
        r.department,
        r.projectNumber,
        r.workingDetails,
        r.hoursCalculate,
        r.teamLeader,
        r.status
      ]);
    }

    try {
      String csvData = const ListToCsvConverter().convert(rows);
      final directory = await getApplicationDocumentsDirectory();
      final path = "${directory.path}/officegate_export_${DateTime.now().millisecondsSinceEpoch}.csv";
      final file = File(path);
      await file.writeAsString(csvData);
      return path;
    } catch (e) {
      print('Export error: $e');
      return null;
    }
  }
}
