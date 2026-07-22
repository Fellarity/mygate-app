import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/skeleton_loader.dart';

class AppSettingsScreen extends StatefulWidget {
  @override
  _AppSettingsScreenState createState() => _AppSettingsScreenState();
}

class _AppSettingsScreenState extends State<AppSettingsScreen> {
  final _supabase = Supabase.instance.client;
  bool _isLoading = true;
  
  // Controllers for Time Management
  final TextEditingController _shiftStartController = TextEditingController();
  final TextEditingController _shiftEndController = TextEditingController();
  final TextEditingController _monthlyTargetController = TextEditingController();

  // Settings for Notifications
  bool _emailNotificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    _fetchSettings();
  }

  Future<void> _fetchSettings() async {
    setState(() => _isLoading = true);
    try {
      final response = await _supabase.from('app_settings').select();
      for (var row in response) {
        if (row['setting_key'] == 'time_management') {
          final val = row['setting_value'] as Map<String, dynamic>;
          _shiftStartController.text = val['standard_shift_start'] ?? '09:00';
          _shiftEndController.text = val['standard_shift_end'] ?? '18:00';
          _monthlyTargetController.text = (val['monthly_hours_target'] ?? 160).toString();
        } else if (row['setting_key'] == 'notifications') {
          final val = row['setting_value'] as Map<String, dynamic>;
          _emailNotificationsEnabled = val['email_enabled'] ?? true;
        }
      }
    } catch (e) {
      print('Error fetching app settings: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveSettings() async {
    setState(() => _isLoading = true);
    try {
      await _supabase.from('app_settings').upsert({
        'setting_key': 'time_management',
        'setting_value': {
          'standard_shift_start': _shiftStartController.text,
          'standard_shift_end': _shiftEndController.text,
          'monthly_hours_target': int.tryParse(_monthlyTargetController.text) ?? 160,
        },
      });

      await _supabase.from('app_settings').upsert({
        'setting_key': 'notifications',
        'setting_value': {
          'email_enabled': _emailNotificationsEnabled,
        },
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Settings saved successfully!'), backgroundColor: Colors.green),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save settings: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Global App Settings'), automaticallyImplyLeading: false),
      body: _isLoading
          ? ListSkeleton()
          : SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    elevation: 4,
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.schedule, color: Colors.indigo),
                              SizedBox(width: 8),
                              Text('Time Management Settings', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          Divider(),
                          SizedBox(height: 16),
                          TextFormField(
                            controller: _shiftStartController,
                            decoration: InputDecoration(
                              labelText: 'Standard Shift Start (HH:MM)',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          SizedBox(height: 16),
                          TextFormField(
                            controller: _shiftEndController,
                            decoration: InputDecoration(
                              labelText: 'Standard Shift End (HH:MM)',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          SizedBox(height: 16),
                          TextFormField(
                            controller: _monthlyTargetController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Monthly Hours Target',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  Card(
                    elevation: 4,
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.notifications, color: Colors.indigo),
                              SizedBox(width: 8),
                              Text('Notification Settings', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          Divider(),
                          SwitchListTile(
                            title: Text('Enable Email Notifications'),
                            subtitle: Text('Send emails to employees and team leaders on report updates.'),
                            value: _emailNotificationsEnabled,
                            activeColor: Colors.indigo,
                            onChanged: (val) {
                              setState(() {
                                _emailNotificationsEnabled = val;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 24),
                  Center(
                    child: ElevatedButton.icon(
                      onPressed: _saveSettings,
                      icon: Icon(Icons.save),
                      label: Text('Save Settings', style: TextStyle(fontSize: 18)),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                        backgroundColor: Colors.indigo,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  )
                ],
              ),
            ),
    );
  }
}
