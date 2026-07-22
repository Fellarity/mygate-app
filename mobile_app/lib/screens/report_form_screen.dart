import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:table_calendar/table_calendar.dart';
import '../models/report.dart';
import '../services/report_service.dart';
import '../widgets/design_spells.dart';

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
  String _department = '';
  String _subtitle = '';
  String _workingDetails = '';
  TimeOfDay _startTime = TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = TimeOfDay(hour: 18, minute: 0);
  late String _teamLeader;
  late String _teamLeaderCode;
  String? _projectNumber;
  List<String> _projectOptions = [];
  Map<DateTime, String> _submittedDates = {};
  DateTime? _registrationDate;

  @override
  void initState() {
    super.initState();
    _employeeCode = widget.employeeCode;
    _teamLeader = widget.assignedTL;
    _teamLeaderCode = widget.assignedTLCode;
    _empName = widget.empName;
    _contactNo = widget.contactNo;
    _fetchProjects();
    _fetchSubmittedDates();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    try {
      final user = await Supabase.instance.client
          .from('users')
          .select('created_at, department')
          .eq('employee_code', _employeeCode)
          .maybeSingle();
      if (user != null) {
        if (mounted) {
          setState(() {
            if (user['created_at'] != null) {
              _registrationDate = DateTime.parse(user['created_at']);
            }
            if (user['department'] != null) {
              _department = user['department'].toString();
            }
            _subtitle = 'N/A'; // Defaulting to N/A as subtitle is not in the schema
          });
        }
      }
    } catch (e) {
      print('Error fetching registration date: $e');
    }
  }

  Future<void> _fetchSubmittedDates() async {
    try {
      final response = await Supabase.instance.client
          .from('reports')
          .select('date, project_number')
          .eq('employee_code', _employeeCode);
          
      if (response != null) {
        final Map<DateTime, String> dates = {};
        for (var row in response) {
          if (row['date'] != null) {
             try {
               final d = DateTime.parse(row['date']);
               final proj = row['project_number']?.toString() ?? '';
               dates[DateTime(d.year, d.month, d.day)] = proj;
             } catch(_) {}
          }
        }
        setState(() {
          _submittedDates = dates;
        });
      }
    } catch (e) {
      print('Error fetching submitted dates: $e');
    }
  }

  Future<void> _fetchProjects() async {
    try {
      final response = await Supabase.instance.client
          .from('projects')
          .select('project_number')
          .order('project_number', ascending: true);
      if (response != null) {
        final List<String> projects = ['Holiday', 'Idle', 'On leave'];
        for (var row in response) {
          if (row['project_number'] != null && row['project_number'].toString().isNotEmpty) {
            String p = row['project_number'].toString().trim();
            if (!projects.map((e) => e.toLowerCase()).contains(p.toLowerCase())) {
                projects.add(p);
            }
          }
        }
        if (mounted) {
          setState(() {
            _projectOptions = projects;
          });
        }
      }
    } catch (e) {
      print('Error fetching projects: $e');
    }
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
        date: DateFormat('yyyy-MM-dd').format(_selectedDate),
        department: _department,
        subtitle: _subtitle,
        workingDetails: _workingDetails,
        startTime: _startTime.format(context),
        endTime: _endTime.format(context),
        hoursCalculate: _calculateHours(),
        teamLeader: _teamLeader,
        teamLeaderCode: _teamLeaderCode,
        projectNumber: _projectNumber ?? '',
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
          _projectNumber = null;
          _submittedDates[DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day)] = report.projectNumber;
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
        child: AnimatedGlassCard(
          padding: EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  StaggeredEntry(
                    index: 0,
                    child: Text(
                      'Report Details',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.indigo.shade800),
                    ),
                  ),
                  SizedBox(height: 20),
                  StaggeredEntry(
                    index: 1,
                    child: TextFormField(
                      initialValue: _employeeCode,
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: 'Employee Code',
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        prefixIcon: Icon(Icons.badge, color: Colors.indigo),
                      ),
                    ),
                  ),
                  SizedBox(height: 24),
                  TextFormField(
                    initialValue: _empName,
                    readOnly: true,
                    decoration: InputDecoration(
                      labelText: 'Employee Name',
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      prefixIcon: Icon(Icons.person, color: Colors.indigo),
                    ),
                  ),
                  SizedBox(height: 24),
                  TextFormField(
                    initialValue: _contactNo,
                    readOnly: true,
                    decoration: InputDecoration(
                      labelText: 'Contact No.',
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      prefixIcon: Icon(Icons.phone, color: Colors.indigo),
                    ),
                  ),
                  SizedBox(height: 24),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.indigo.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.indigo.shade100),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.person_pin, color: Colors.indigo),
                        SizedBox(width: 12),
                        Text("Reporting to: ", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Text(_teamLeader, style: TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold, fontSize: 16)),
                      ],
                    ),
                  ),
                  SizedBox(height: 24),
                  Divider(),
                  SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Date: ${DateFormat('dd-MM-yyyy').format(_selectedDate)}", style: TextStyle(fontSize: 16)),
                      OutlinedButton.icon(
                        icon: Icon(Icons.calendar_today),
                        label: Text('Change'),
                        onPressed: () async {
                          final picked = await showDialog<DateTime>(
                            context: context,
                            builder: (context) {
                              DateTime focusedDay = _selectedDate;
                              DateTime? selectedDay = _selectedDate;
                              
                                Widget? buildCell(DateTime day, {bool isSelected = false}) {
                                  if (day.weekday == DateTime.saturday || day.weekday == DateTime.sunday) return null;
                                  
                                  final targetDay = DateTime(day.year, day.month, day.day);
                                  final isFilled = _submittedDates.containsKey(targetDay);
                                  final project = isFilled ? _submittedDates[targetDay] : null;
                                  
                                  final today = DateTime.now();
                                  final todayNormalized = DateTime(today.year, today.month, today.day);
                                  
                                  if (targetDay.isAfter(todayNormalized)) return null;
                                  
                                  bool isBeforeReg = false;
                                  if (!isFilled && _registrationDate != null) {
                                    final regDateNormalized = DateTime(_registrationDate!.year, _registrationDate!.month, _registrationDate!.day);
                                    if (targetDay.isBefore(regDateNormalized)) {
                                      isBeforeReg = true;
                                    }
                                  }
                                  
                                  Color bgColor = isFilled ? Colors.teal.shade50 : (isBeforeReg ? Colors.grey.shade100 : Colors.red.shade50);
                                  Color textColor = isFilled ? Colors.teal.shade700 : (isBeforeReg ? Colors.grey.shade500 : Colors.red.shade700);
                                  Color borderColor = isSelected 
                                      ? (isFilled ? Colors.teal.shade400 : (isBeforeReg ? Colors.grey.shade400 : Colors.red.shade400)) 
                                      : Colors.transparent;

                                  if (isFilled && project != null) {
                                      final p = project.toLowerCase();
                                      if (p == 'holiday') {
                                          bgColor = Colors.blue.shade50;
                                          textColor = Colors.blue.shade700;
                                          if (isSelected) borderColor = Colors.blue.shade400;
                                      } else if (p == 'on leave') {
                                          bgColor = Colors.yellow.shade100;
                                          textColor = Colors.yellow.shade900;
                                          if (isSelected) borderColor = Colors.yellow.shade600;
                                      } else if (p == 'idle') {
                                          bgColor = Colors.orange.shade50;
                                          textColor = Colors.orange.shade800;
                                          if (isSelected) borderColor = Colors.orange.shade400;
                                      }
                                  }
                                
                                Widget cell = Container(
                                  margin: const EdgeInsets.all(4.0),
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: bgColor, 
                                    shape: BoxShape.circle,
                                    border: Border.all(color: borderColor, width: isSelected ? 2 : 0),
                                    boxShadow: isSelected ? [BoxShadow(color: borderColor.withOpacity(0.5), blurRadius: 8, spreadRadius: 2)] : null,
                                  ),
                                  child: Text(day.day.toString(), style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 16)),
                                );
                                
                                if (isSelected) {
                                  cell = cell.animate().scale(begin: const Offset(0.8, 0.8), duration: 400.ms, curve: Curves.elasticOut);
                                }
                                return cell;
                              }

                              return StatefulBuilder(
                                builder: (context, setDialogState) {
                                  return Dialog(
                                    backgroundColor: Colors.transparent,
                                    elevation: 0,
                                    child: AnimatedGlassCard(
                                      padding: EdgeInsets.zero,
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                                            decoration: BoxDecoration(
                                              color: Colors.indigo.shade50.withOpacity(0.5),
                                              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                                            ),
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Text("Select Report Date", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.indigo.shade900)),
                                                IconButton(
                                                  icon: Icon(Icons.close, color: Colors.indigo.shade900),
                                                  padding: EdgeInsets.zero,
                                                  constraints: BoxConstraints(),
                                                  onPressed: () => Navigator.pop(context),
                                                )
                                              ],
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.all(16.0),
                                            child: TableCalendar(
                                              firstDay: DateTime(2020),
                                              lastDay: DateTime.now().add(const Duration(days: 30)),
                                              focusedDay: focusedDay,
                                              selectedDayPredicate: (day) => isSameDay(selectedDay, day),
                                              headerStyle: HeaderStyle(
                                                formatButtonVisible: false,
                                                titleCentered: true,
                                                titleTextStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.indigo.shade800),
                                                leftChevronIcon: Icon(Icons.chevron_left, color: Colors.indigo.shade800),
                                                rightChevronIcon: Icon(Icons.chevron_right, color: Colors.indigo.shade800),
                                              ),
                                              daysOfWeekStyle: DaysOfWeekStyle(
                                                weekdayStyle: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo.shade300),
                                                weekendStyle: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade400),
                                              ),
                                              calendarStyle: CalendarStyle(
                                                outsideDaysVisible: false,
                                                weekendTextStyle: TextStyle(color: Colors.grey.shade400),
                                              ),
                                              onDaySelected: (selected, focused) {
                                                setDialogState(() {
                                                  selectedDay = selected;
                                                  focusedDay = focused;
                                                });
                                                Future.delayed(const Duration(milliseconds: 350), () {
                                                  if (context.mounted) Navigator.pop(context, selectedDay);
                                                });
                                              },
                                              calendarBuilders: CalendarBuilders(
                                                defaultBuilder: (context, day, focused) => buildCell(day),
                                                todayBuilder: (context, day, focused) => buildCell(day),
                                                selectedBuilder: (context, day, focused) => buildCell(day, isSelected: true),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ).animate().fade(duration: 300.ms, curve: Curves.easeOut).scale(begin: const Offset(0.8, 0.8), curve: Curves.easeOutBack, duration: 500.ms),
                                  );
                                },
                              );
                            },
                          );
                          if (picked != null) setState(() => _selectedDate = picked);
                        },
                      ),
                    ],
                  ),
                  SizedBox(height: 24),
                  TextFormField(
                    key: ValueKey('dept_$_department'),
                    initialValue: _department.isEmpty ? 'Loading...' : _department,
                    readOnly: true,
                    decoration: InputDecoration(
                      labelText: 'Department',
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      prefixIcon: Icon(Icons.business, color: Colors.indigo),
                    ),
                  ),
                  SizedBox(height: 24),
                  TextFormField(
                    key: ValueKey('sub_$_subtitle'),
                    initialValue: _subtitle.isEmpty ? 'Loading...' : _subtitle,
                    readOnly: true,
                    decoration: InputDecoration(
                      labelText: 'Subtitle',
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      prefixIcon: Icon(Icons.topic, color: Colors.indigo),
                    ),
                  ),
                  SizedBox(height: 24),
                  DropdownButtonFormField<String>(
                    value: _projectOptions.contains(_projectNumber) ? _projectNumber : null,
                    items: _projectOptions.isEmpty
                        ? [DropdownMenuItem(value: null, child: Text('No projects available'))]
                        : _projectOptions
                            .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                            .toList(),
                    onChanged: _projectOptions.isEmpty ? null : (v) => setState(() => _projectNumber = v),
                    decoration: InputDecoration(
                      labelText: 'Project Number',
                      prefixIcon: Icon(Icons.work),
                    ),
                    validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                    onSaved: (v) => _projectNumber = v,
                  ),
                  SizedBox(height: 24),
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Working Details',
                      alignLabelWithHint: true,
                    ),
                    maxLines: 4,
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                    onSaved: (v) => _workingDetails = v!,
                  ),
                  SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: Icon(Icons.access_time),
                          label: FittedBox(fit: BoxFit.scaleDown, child: Text("Start: ${_startTime.format(context)}")),
                          onPressed: () async {
                            final picked = await showTimePicker(context: context, initialTime: _startTime);
                            if (picked != null) setState(() => _startTime = picked);
                          },
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: Icon(Icons.access_time_filled),
                          label: FittedBox(fit: BoxFit.scaleDown, child: Text("End: ${_endTime.format(context)}")),
                          onPressed: () async {
                            final picked = await showTimePicker(context: context, initialTime: _endTime);
                            if (picked != null) setState(() => _endTime = picked);
                          },
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 32),
                  StaggeredEntry(
                    index: 12,
                    child: SizedBox(
                      width: double.infinity,
                      child: MagneticButton(
                        icon: Icons.send,
                        label: Text('Submit Report', style: TextStyle(fontSize: 18)),
                        onPressed: _submit,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
    );
  }
}
