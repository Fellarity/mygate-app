/// Faith Hours App Configuration
///
/// Centralizes Supabase connection settings. Values can be overridden
/// at build time using --dart-define:
///
/// ```bash
/// flutter build apk \
///   --dart-define=SUPABASE_URL=https://your-url.com \
///   --dart-define=SUPABASE_ANON_KEY=your-key
/// ```
class AppConfig {
  AppConfig._();

  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://rmvidmvgwtrqhwbnoyku.supabase.co',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJtdmlkbXZnd3RycWh3Ym5veWt1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODQ2MzQxMzQsImV4cCI6MjEwMDIxMDEzNH0.0UBbsuNPZJrwovG1CJUwSYvmGWwA2i3btp28rbK1G9w',
  );
}
