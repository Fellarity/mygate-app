import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:csv/csv.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:universal_io/io.dart';
import 'package:universal_html/html.dart' as html;
import '../models/report.dart';

class ExportService {
  int _getIsoWeekNumber(DateTime date) {
    DateTime d = DateTime.utc(date.year, date.month, date.day);
    int dayOfWeek = d.weekday;
    d = d.add(Duration(days: 4 - dayOfWeek));
    DateTime firstDayOfYear = DateTime.utc(d.year, 1, 1);
    int dayOfYear = d.difference(firstDayOfYear).inDays + 1;
    return ((dayOfYear - 1) / 7).floor() + 1;
  }

  Future<String?> exportReportsToCsv(List<Report> reports, List<Map<String, dynamic>> projects) async {
    Map<String, Map<String, dynamic>> pivot = {};
    for (var p in projects) {
      pivot[p['project_number'] ?? ''] = {
        'desc': p['description'] ?? '',
        'months': List<double>.filled(12, 0.0),
        'weeks': List<double>.filled(53, 0.0),
        'total': 0.0,
      };
    }
    
    for (var r in reports) {
      if (r.projectNumber == null || r.projectNumber!.isEmpty) continue;
      
      String proj = r.projectNumber!;
      if (!pivot.containsKey(proj)) {
        pivot[proj] = {
          'desc': '',
          'months': List<double>.filled(12, 0.0),
          'weeks': List<double>.filled(53, 0.0),
          'total': 0.0,
        };
      }
      
      try {
        if (r.date == null) continue;
        DateTime date = DateTime.parse(r.date!);
        int monthIdx = date.month - 1;
        int weekNum = _getIsoWeekNumber(date);
        int weekIdx = weekNum - 1;
        
        double hours = 0.0;
        if (r.hoursCalculate != null) {
          if (r.hoursCalculate!.contains(':')) {
            final parts = r.hoursCalculate!.split(':');
            hours = (double.tryParse(parts[0]) ?? 0.0) + ((double.tryParse(parts[1]) ?? 0.0) / 60.0);
          } else {
            hours = double.tryParse(r.hoursCalculate!) ?? 0.0;
          }
        }
        
        if (monthIdx >= 0 && monthIdx < 12) {
          pivot[proj]!['months'][monthIdx] += hours;
        }
        if (weekIdx >= 0 && weekIdx < 53) {
          pivot[proj]!['weeks'][weekIdx] += hours;
        }
        pivot[proj]!['total'] += hours;
      } catch (e) {
        print('Error parsing report date/hours: $e');
      }
    }
    
    List<List<dynamic>> rows = [];
    rows.add(["PROJECT WORK LOAD TRAKING SHEET"]);
    
    List<dynamic> header = [
      "Sr. No.",
      "PROJECT CODE",
      "PROJECT NAME",
      "January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December",
      "Total Hrs",
      "ETC",
      "Over Budget"
    ];
    for (int i = 1; i <= 53; i++) {
      header.add("WK${i.toString().padLeft(2, '0')}");
    }
    rows.add(header);
    
    int srNo = 1;
    final sortedProjects = pivot.keys.toList()..sort();
    
    for (var proj in sortedProjects) {
      if (proj.isEmpty) continue;
      var data = pivot[proj]!;
      List<dynamic> row = [
        srNo++,
        proj,
        data['desc'],
        ...data['months'],
        data['total'],
        "", 
        "", 
        ...data['weeks']
      ];
      
      for (int i=0; i<row.length; i++) {
        if (row[i] is double) {
          row[i] = double.parse((row[i] as double).toStringAsFixed(2));
        }
      }
      
      rows.add(row);
    }

    try {
      String csvData = const ListToCsvConverter().convert(rows);
      String fileName = "faithhours_export_${DateTime.now().millisecondsSinceEpoch}.csv";

      if (kIsWeb) {
        // Web download
        final bytes = utf8.encode(csvData);
        final blob = html.Blob([bytes]);
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.AnchorElement(href: url)
          ..setAttribute("download", fileName)
          ..click();
        html.Url.revokeObjectUrl(url);
        return "Downloads folder";
      } else {
        // Mobile/Desktop: Save to temp and Share
        final directory = await getTemporaryDirectory();
        final path = "${directory.path}/$fileName";
        final file = File(path);
        
        // Write the data safely to the app's cache
        await file.writeAsString(csvData);
        
        // Trigger native share sheet with explicit MIME type
        await Share.shareXFiles(
          [XFile(path, mimeType: 'text/csv')], 
          text: 'Faith Hours Payroll Export',
          subject: 'Faith Hours Export',
        );
        
        return "Shared successfully";
      }
    } catch (e) {
      print('Export error: $e');
      return "ERROR: $e";
    }
  }
}
