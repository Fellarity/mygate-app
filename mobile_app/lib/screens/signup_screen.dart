import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../widgets/design_spells.dart';

class SignupScreen extends StatefulWidget {
  final Function(Map<String, dynamic> userProfile) onLoginComplete;

  SignupScreen({required this.onLoginComplete});

  @override
  _SignupScreenState createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _supabase = Supabase.instance.client;
  
  String _employeeId = '';
  String _password = '';
  bool _isLoading = false;

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() => _isLoading = true);

    try {
      // 1. Fetch the user's email using their Employee ID
      // Note: This requires the 'users' table to allow unauthenticated read access 
      // (or at least a secure RPC that returns the email for a given employee code).
      final userQuery = await _supabase
          .from('users')
          .select('email, is_blocked')
          .eq('employee_code', _employeeId.trim())
          .maybeSingle();

      if (userQuery == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Employee ID not found'), backgroundColor: Colors.red),
        );
        return;
      }

      if (userQuery['is_blocked'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Account Suspended'), backgroundColor: Colors.red),
        );
        return;
      }

      final String email = userQuery['email'];

      // 2. Use native Supabase Auth with the retrieved email
      final AuthResponse res = await _supabase.auth.signInWithPassword(
        email: email,
        password: _password,
      );

      if (res.user != null) {
        // Fetch full user profile after successful auth
        final profile = await _supabase.from('users').select().eq('employee_code', _employeeId.trim()).single();
        widget.onLoginComplete(profile);
      }
    } on AuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: Colors.orange.shade900,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Connection Error. Please check your internet.')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Animated gradient background
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.indigo.shade900, Colors.deepPurple.shade600],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ).animate(onPlay: (controller) => controller.repeat(reverse: true))
             .shimmer(duration: 4000.ms, color: Colors.white10),
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: AnimatedGlassCard(
                padding: const EdgeInsets.all(32.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      StaggeredEntry(
                        index: 0,
                        child: Image.asset('assets/images/faith_logo.png', height: 80),
                      ),
                      const SizedBox(height: 16),
                      StaggeredEntry(
                        index: 1,
                        child: Text(
                          'Faith Hours Login',
                          style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.indigo.shade900),
                        ),
                      ),
                      const SizedBox(height: 32),
                      StaggeredEntry(
                        index: 2,
                        child: TextFormField(
                          decoration: const InputDecoration(
                            labelText: 'Employee ID',
                            prefixIcon: Icon(Icons.badge),
                          ),
                          validator: (v) => v!.isEmpty ? 'Required' : null,
                          onSaved: (v) => _employeeId = v!.trim(),
                        ),
                      ),
                      const SizedBox(height: 20),
                      StaggeredEntry(
                        index: 3,
                        child: TextFormField(
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: 'Password',
                            prefixIcon: Icon(Icons.lock),
                          ),
                          validator: (v) => v!.isEmpty ? 'Required' : null,
                          onSaved: (v) => _password = v!,
                        ),
                      ),
                      const SizedBox(height: 32),
                      StaggeredEntry(
                        index: 4,
                        child: SizedBox(
                          width: double.infinity,
                          child: MagneticButton(
                            isLoading: _isLoading,
                            onPressed: _handleLogin,
                            label: const Text('Login', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 16.0,
            right: 16.0,
            child: Text(
              'Developed by ARG',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 12.0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
