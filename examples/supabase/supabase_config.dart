/// Example Supabase config. Replace with your project URL and anon key.
class SupabaseConfig {
  static const String url = 'https://your-project.supabase.co';
  static const String anonKey = 'your-anon-key';
  static const String environment = 'example';
  static const bool debug = false;
  static bool get isValid => url.isNotEmpty && anonKey.isNotEmpty && anonKey != 'your-anon-key';
}


