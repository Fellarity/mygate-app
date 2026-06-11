import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/report.dart';
import '../services/report_service.dart';

class ReportFormScreen extends StatefulWidget {
  final String employeeCode;
  final String assignedTL;
  final String assignedTLCode;
  final String empName;
  final String contactNo;

  ReportFormScreen({
    required this.employeeCode, 
    required this.assignedTL,
    required this.assignedTLCode,
    required this.empName,
    required this.contactNo,
  });

  @override
  _ReportFormScreenState createState() => _ReportFormScreenState();
}

class _ReportFormScreenState extends State<ReportFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final ReportService _reportService = ReportService();

  // Form Fields
  late String _employeeCode;
  late String _empName;
  late String _contactNo;
  DateTime _selectedDate = DateTime.now();
  String _department = 'Engineering';
  String _subtitle = 'Simulation';
  String _workingDetails = '';
  TimeOfDay _startTime = TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = TimeOfDay(hour: 18, minute: 0);
  late String _teamLeader;
  late String _teamLeaderCode;
  String _projectNumber = '';

  @override
  void initState() {
    super.initState();
    _employeeCode = widget.employeeCode;
    _teamLeader = widget.assignedTL;
    _teamLeaderCode = widget.assignedTLCode;
    _empName = widget.empName;
    _contactNo = widget.contactNo;
  }

  String _calculateHours() {
    final start = _startTime.hour + _startTime.minute / 60.0;
    final end = _endTime.hour + _endTime.minute / 60.0;
    double diff = end - start;
    if (diff < 0) diff += 24; // Handle overnight shifts
    final int hours = diff.floor();
    final int mins = ((diff - hours) * 60).round();
    return '$hours:${mins.toString().padLeft(2, '0')}';
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final report = Report(
        employeeCode: _employeeCode,
        empName: _empName,
        contactNo: _contactNo,
        date: DateFormat('dd-MM-yyyy').format(_selectedDate),
        department: _department,
        subtitle: _subtitle,
        workingDetails: _workingDetails,
        startTime: _startTime.format(context),
        endTime: _endTime.format(context),
        hoursCalculate: _calculateHours(),
        teamLeader: _teamLeader,
        teamLeaderCode: _teamLeaderCode,
        projectNumber: _projectNumber,
      );

      bool success = await _reportService.submitReport(report);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Report submitted to $_teamLeader!')),
        );
        _formKey.currentState!.reset();
        setState(() {
          _employeeCode = widget.employeeCode;
          _teamLeader = widget.assignedTL;
          _teamLeaderCode = widget.assignedTLCode;
          _empName = widget.empName;
          _contactNo = widget.contactNo;
          _workingDetails = '';
          _projectNumber = '';
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error submitting report.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Daily Work Report'), automaticallyImplyLeading: false),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                initialValue: _employeeCode,
                readOnly: true,
                decoration: InputDecoration(
                  labelText: 'Employee Code',
                  filled: true,
                  fillColor: Colors.grey.shade100,
                ),
              ),
              SizedBox(height: 10),
              TextFormField(
                initialValue: _empName,
                readOnly: true,
                decoration: InputDecoration(
                  labelText: 'Employee Name',
                  filled: true,
                  fillColor: Colors.grey.shade100,
                ),
              ),
              SizedBox(height: 10),
              TextFormField(
                initialValue: _contactNo,
                readOnly: true,
                decoration: InputDecoration(
                  labelText: 'Contact No.',
                  filled: true,
                  fillColor: Colors.grey.shade100,
                ),
              ),
              SizedBox(height: 10),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.indigo.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.person_pin, color: Colors.indigo),
                    SizedBox(width: 10),
                    Text("Reporting to: ", style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(_teamLeader, style: TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              SizedBox(height: 10),
              Row(
                children: [
                  Text("Date: ${DateFormat('dd-MM-yyyy').format(_selectedDate)}"),
                  IconButton(
                    icon: Icon(Icons.calendar_today),
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                      );
                      if (picked != null) setState(() => _selectedDate = picked);
                    },
                  ),
                ],
              ),
              DropdownButtonFormField(
                value: _department,
                items: ['Engineering', 'Design', 'Simulation', 'Marketing', 'Sales', 'HR']
                    .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                    .toList(),
                onChanged: (v) => setState(() => _department = v as String),
                decoration: InputDecoration(labelText: 'Department'),
              ),
              DropdownButtonFormField(
                value: _subtitle,
                items: ['Simulation', 'Process', '3D', 'Other']
                    .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                    .toList(),
                onChanged: (v) => setState(() => _subtitle = v as String),
                decoration: InputDecoration(labelText: 'Subtitle'),
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Project Number (e.g., FA-241)'),
                validator: (v) => v!.isEmpty ? 'Required' : null,
                onSaved: (v) => _projectNumber = v!,
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Working Details'),
                maxLines: 4,
                validator: (v) => v!.isEmpty ? 'Required' : null,
                onSaved: (v) => _workingDetails = v!,
              ),
              Row(
                children: [
                  Expanded(
                    child: ListTile(
                      title: Text("Start: ${_startTime.format(context)}"),
                      onTap: () async {
                        final picked = await showTimePicker(context: context, initialTime: _startTime);
                        if (picked != null) setState(() => _startTime = picked);
                      },
                    ),
                  ),
                  Expanded(
                    child: ListTile(
                      title: Text("End: ${_endTime.format(context)}"),
                      onTap: () async {
                        final picked = await showTimePicker(context: context, initialTime: _endTime);
                        if (picked != null) setState(() => _endTime = picked);
                      },
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submit,
                child: Text('Submit Report'),
                style: ElevatedButton.styleFrom(minimumSize: Size(double.infinity, 50)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
