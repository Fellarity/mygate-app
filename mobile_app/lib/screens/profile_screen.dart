import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileScreen extends StatefulWidget {
  final Map<String, dynamic> userProfile;

  ProfileScreen({required this.userProfile});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _supabase = Supabase.instance.client;
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String _totalHours = "0:00";

  @override
  void initState() {
    super.initState();
    _calculateTotalHours();
  }

  Future<void> _calculateTotalHours() async {
    try {
      final now = DateTime.now();
      final firstDay = DateTime(now.year, now.month, 1).toIso8601String().split('T')[0];
      final lastDay = DateTime(now.year, now.month + 1, 0).toIso8601String().split('T')[0];

      final response = await _supabase
          .from('reports')
          .select('hours_calculate')
          .eq('employee_code', widget.userProfile['employee_code'])
          .inFilter('status', ['Approve', 'Approved']) // Only count approved hours
          .gte('date', firstDay)
          .lte('date', lastDay);

      if (response != null) {
        int totalMinutes = 0;
        for (var row in response) {
          final hoursStr = row['hours_calculate']?.toString();
          if (hoursStr != null && hoursStr.contains(':')) {
            final parts = hoursStr.split(':');
            if (parts.length == 2) {
              totalMinutes += (int.tryParse(parts[0]) ?? 0) * 60;
              totalMinutes += (int.tryParse(parts[1]) ?? 0);
            }
          }
        }

        final hours = totalMinutes ~/ 60;
        final mins = totalMinutes % 60;
        setState(() {
          _totalHours = '$hours:${mins.toString().padLeft(2, '0')}';
        });
      }
    } catch (e) {
      print('Error calculating hours: $e');
    }
  }

  Future<void> _changePassword() async {
    if (_passwordController.text.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      // Update Supabase Auth password
      await _supabase.auth.updateUser(
        UserAttributes(password: _passwordController.text),
      );

      // We no longer update the plaintext 'password' column in the users table
      // as it's a security risk and legacy code.

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Password updated successfully!')),
      );
      _passwordController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating password: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.userProfile;
    return Scaffold(
      appBar: AppBar(title: Text('My Profile'), automaticallyImplyLeading: false),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: Colors.indigo,
              child: Text(
                p['name']?[0] ?? '?',
                style: TextStyle(fontSize: 40, color: Colors.white),
              ),
            ),
            SizedBox(height: 20),
            
            // Total Hours Card
            Card(
              elevation: 4,
              color: Colors.indigo.shade50,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.timer, size: 32, color: Colors.indigo),
                    SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Approved Hours This Month', style: TextStyle(color: Colors.indigo.shade300, fontWeight: FontWeight.bold)),
                        Text(_totalHours, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.indigo.shade900)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),

            _profileTile(Icons.person, "Name", p['name']),
            _profileTile(Icons.badge, "Employee ID", p['employee_code']),
            _profileTile(Icons.phone, "Contact", p['contact_no']),
            _profileTile(Icons.business, "Department", p['department']),
            _profileTile(Icons.supervisor_account, "Team Leader", p['team_leader_name'] ?? p['team_leader']),
            Divider(height: 40),
            Text('Change Password', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'New Password',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock_outline),
              ),
            ),
            SizedBox(height: 16),
            _isLoading
                ? CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _changePassword,
                    child: Text('Update Password'),
                    style: ElevatedButton.styleFrom(minimumSize: Size(double.infinity, 50)),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _profileTile(IconData icon, String label, String? value) {
    return ListTile(
      leading: Icon(icon, color: Colors.indigo),
      title: Text(label, style: TextStyle(fontSize: 12, color: Colors.grey)),
      subtitle: Text(value ?? 'N/A', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
    );
  }
}
