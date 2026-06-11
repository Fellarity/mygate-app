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

  Future<void> _changePassword() async {
    if (_passwordController.text.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      await _supabase
          .from('users')
          .update({'password': _passwordController.text})
          .eq('employee_code', widget.userProfile['employee_code']);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Password updated successfully!')),
      );
      _passwordController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating password: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
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
            _profileTile(Icons.person, "Name", p['name']),
            _profileTile(Icons.badge, "Employee ID", p['employee_code']),
            _profileTile(Icons.phone, "Contact", p['contact_no']),
            _profileTile(Icons.business, "Department", p['department']),
            _profileTile(Icons.supervisor_account, "Team Leader", p['team_leader']),
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
