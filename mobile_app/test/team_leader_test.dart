import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  test('Type Cast Test', () async {
    final supabase = SupabaseClient('https://faithhours.duckdns.org', 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJyb2xlIjoiYW5vbiIsImlzcyI6InN1cGFiYXNlIiwiaWF0IjoxNzgyMjM2MTcyLCJleHAiOjE5Mzk5MTYxNzJ9.IkHhCCuumK67c9-uQM_TuiLn6SHvp_pcOTGDFl11V1Y');
    
    try {
      var query = supabase.from('users').select();
      query = query.eq('team_leader', 'FA-046');
      final response = await query.order('name');
      final employees = List<Map<String, dynamic>>.from(response);
      print('Type cast successful, length: ${employees.length}');
    } catch (e, stack) {
      print('Error occurred: $e');
    }
  });
}
