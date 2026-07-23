import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'report_history_screen.dart';
import '../widgets/skeleton_loader.dart';
import 'employee_profile_detail_screen.dart';

class ManageEmployeesScreen extends StatefulWidget {
  final String tlName;
  final String tlCode;
  final bool isAdmin;

  ManageEmployeesScreen({required this.tlName, required this.tlCode, this.isAdmin = false});

  @override
  _ManageEmployeesScreenState createState() => _ManageEmployeesScreenState();
}

class _ManageEmployeesScreenState extends State<ManageEmployeesScreen> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _employees = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchEmployees();
  }

  Future<void> _fetchEmployees() async {
    setState(() => _isLoading = true);
    try {
      var query = _supabase.from('users').select();
      
      if (!widget.isAdmin) {
        query = query.eq('team_leader', widget.tlCode.trim());
      }
      
      final response = await query.order('name');
          
      if (response != null) {
        setState(() {
          _employees = List<Map<String, dynamic>>.from(response);
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching employees: $e');
      setState(() => _isLoading = false);
    }
  }

  void _viewEmployeeHistory(Map<String, dynamic> emp) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EmployeeProfileDetailScreen(employeeData: emp),
      ),
    );
  }

  Future<void> _deleteEmployee(String employeeCode) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Employee?'),
        content: Text('Are you sure you want to remove employee $employeeCode? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            child: Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _supabase.from('users').delete().eq('employee_code', employeeCode);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Employee removed')));
        _fetchEmployees();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    }
  }

  Future<void> _removeFromTeam(Map<String, dynamic> emp) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Remove from Team?'),
        content: Text('Are you sure you want to remove ${emp['name']} from your team?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Remove', style: TextStyle(color: Colors.orange)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _supabase.from('users').update({'team_leader': ''}).eq('id', emp['id']);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Employee removed from team')));
        _fetchEmployees();
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    }
  }

  Future<void> _toggleBlockEmployee(Map<String, dynamic> emp) async {
    final bool currentlyBlocked = emp['is_blocked'] ?? false;
    
    // Only Admin can unblock
    if (currentlyBlocked && !widget.isAdmin) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Only administrators can unblock employees.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final String action = currentlyBlocked ? 'unblock' : 'block';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${action[0].toUpperCase()}${action.substring(1)} Employee?'),
        content: Text('Are you sure you want to $action ${emp['name']}? ${currentlyBlocked ? "They will be able to log in again." : "They will be immediately logged out and unable to log in."}'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            child: Text(action.toUpperCase(), style: TextStyle(color: currentlyBlocked ? Colors.green : Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _supabase.from('users').update({'is_blocked': !currentlyBlocked}).eq('id', emp['id']);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Employee $action' + 'ed successfully')));
        _fetchEmployees();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    }
  }

  void _showAddEditDialog({Map<String, dynamic>? employee}) {
    final isEditing = employee != null;
    final _formKey = GlobalKey<FormState>();
    final _nameController = TextEditingController(text: employee?['name']);
    final _codeController = TextEditingController(text: employee?['employee_code']);
    final _deptController = TextEditingController(text: employee?['department']);
    // For TLs, we auto-set the team leader to themselves
    final _tlController = TextEditingController(
      text: isEditing 
          ? (employee['team_leader'] ?? '') 
          : (widget.isAdmin ? '' : widget.tlCode)
    );
    final _emailController = TextEditingController(text: employee?['email']);
    final _passController = TextEditingController(text: isEditing ? '' : 'pass123');
    String _role = employee?['role'] ?? 'Employee';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            isEditing ? 'Edit Employee Details' : 'Register New Employee',
            style: TextStyle(color: Colors.indigo.shade800, fontWeight: FontWeight.bold),
          ),
          content: Container(
            width: 400,
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Full Name',
                        prefixIcon: Icon(Icons.person),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      validator: (v) => v!.isEmpty ? 'Please enter name' : null,
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      controller: _codeController,
                      decoration: InputDecoration(
                        labelText: 'Employee Code',
                        prefixIcon: Icon(Icons.badge),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      enabled: !isEditing,
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        labelText: 'Email Address',
                        prefixIcon: Icon(Icons.email),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),
                    if (!isEditing) ...[
                      SizedBox(height: 16),
                      TextFormField(
                        controller: _passController,
                        decoration: InputDecoration(
                          labelText: 'Initial Password',
                          prefixIcon: Icon(Icons.lock_outline),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          helperText: 'Default: pass123',
                        ),
                        validator: (v) => v!.isEmpty ? 'Required' : null,
                      ),
                    ],
                    SizedBox(height: 16),
                    TextFormField(
                      controller: _deptController,
                      decoration: InputDecoration(
                        labelText: 'Department',
                        prefixIcon: Icon(Icons.business),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      controller: _tlController,
                      decoration: InputDecoration(
                        labelText: 'Team Leader',
                        prefixIcon: Icon(Icons.supervisor_account),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      enabled: widget.isAdmin, // Only Admin can change TL
                    ),
                    SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _role,
                      decoration: InputDecoration(
                        labelText: 'Access Role',
                        prefixIcon: Icon(Icons.security),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      items: (widget.isAdmin ? ['Employee', 'Team Leader', 'Admin'] : ['Employee'])
                          .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                          .toList(),
                      onChanged: widget.isAdmin ? (v) => setDialogState(() => _role = v!) : null,
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: TextStyle(color: Colors.grey.shade600)),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo.shade700,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () async {
                  if (!_formKey.currentState!.validate()) return;
                  
                  final data = {
                    'name': _nameController.text.trim(),
                    'employee_code': _codeController.text.trim(),
                    'email': _emailController.text.trim(),
                    'department': _deptController.text.trim(),
                    'team_leader': _tlController.text.trim(),
                    'role': _role,
                  };
                  
                  // NOTE: In a real production environment, you should NOT insert passwords directly
                  // into a public users table. You must use Supabase Edge Functions or an RPC 
                  // using the Service Role Key to call `supabase.auth.admin.createUser`.
                  // We are keeping this data struct for now but dropping the plaintext password.
                  // if (!isEditing) data['password'] = _passController.text;

                  try {
                    if (isEditing) {
                      await _supabase.from('users').update(data).eq('id', employee['id']);
                    } else {
                      await _supabase.from('users').insert(data);
                    }
                    Navigator.pop(context);
                    _fetchEmployees();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(isEditing ? 'Profile updated' : 'Employee registered')),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
                  }
                },
                child: Text(isEditing ? 'Update Profile' : 'Register'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isAdmin ? 'Manage Employees' : 'My Team'),
        actions: [
          IconButton(
            icon: Icon(Icons.add), 
            onPressed: () => _showAddEditDialog(),
            tooltip: 'Add Employee',
          ),
          IconButton(icon: Icon(Icons.refresh), onPressed: _fetchEmployees)
        ],
      ),
      body: _isLoading
          ? ListSkeleton()
          : _employees.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.group_off, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('No employees found.', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: EdgeInsets.all(8),
                  itemCount: _employees.length,
                  itemBuilder: (context, index) {
                    final emp = _employees[index];
                    final bool isBlocked = emp['is_blocked'] ?? false;

                    return Card(
                      elevation: 2,
                      margin: EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                      color: isBlocked ? Colors.red.shade50 : null,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isBlocked ? Colors.red.shade100 : Colors.indigo.shade100,
                          child: Text(
                            emp['name']?[0] ?? '?',
                            style: TextStyle(color: isBlocked ? Colors.red.shade900 : Colors.indigo.shade900, fontWeight: FontWeight.bold),
                          ),
                        ),
                        title: Row(
                          children: [
                            Text(emp['name'] ?? 'Unknown', style: TextStyle(fontWeight: FontWeight.bold)),
                            if (isBlocked) ...[
                              SizedBox(width: 8),
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(4)),
                                child: Text('BLOCKED', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('ID: ${emp['employee_code']} • ${(emp['designation'] != null && emp['designation'].toString().isNotEmpty) ? emp['designation'] : emp['role']}'),
                            Text('Dept: ${emp['department']}'),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (widget.isAdmin)
                              IconButton(
                                icon: Icon(Icons.edit, color: Colors.blue),
                                onPressed: () => _showAddEditDialog(employee: emp),
                                tooltip: 'Edit Profile',
                              ),
                            IconButton(
                              icon: Icon(
                                isBlocked ? Icons.lock_open : Icons.block,
                                color: isBlocked ? Colors.green : Colors.orange,
                              ),
                              onPressed: () => _toggleBlockEmployee(emp),
                              tooltip: isBlocked ? 'Unblock (Admin only)' : 'Block Employee',
                            ),
                            if (widget.isAdmin)
                              IconButton(
                                icon: Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _deleteEmployee(emp['employee_code']),
                                tooltip: 'Delete Permanently',
                              ),
                            if (!widget.isAdmin)
                              IconButton(
                                icon: Icon(Icons.person_remove, color: Colors.orange),
                                onPressed: () => _removeFromTeam(emp),
                                tooltip: 'Remove from Team',
                              ),
                            if (emp['role'] == 'Team Leader')
                              TextButton.icon(
                                icon: Icon(Icons.people, size: 16),
                                label: Text('Team'),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ManageEmployeesScreen(
                                        tlName: emp['name'] ?? 'Team',
                                        tlCode: emp['employee_code'],
                                        isAdmin: false,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            if (!widget.isAdmin)
                              Icon(Icons.arrow_forward_ios, color: Colors.indigo, size: 16),
                          ],
                        ),
                        onTap: () => _viewEmployeeHistory(emp),
                      ),
                    );
                  },
                ),
    );
  }
}

