// Supabase Configuration
// Replace these values with your actual Supabase project credentials

// Central runtime configuration for Supabase.
// Values are sourced from compile-time environment where possible to avoid committing secrets.

class SupabaseConfig {
  // Prefer passing credentials via --dart-define for builds/dev runs
  // e.g., --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
  // 
  // Development defaults (from scripts/run_app.sh):
  // These are used if --dart-define flags are not provided
  static const String url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://nfzlwgbvezwwrutqpedy.supabase.co',
  );
  static const String anonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5memx3Z2J2ZXp3d3J1dHFwZWR5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjM1MDU5MDUsImV4cCI6MjA3OTA4MTkwNX0.TimlFKPLvhF7NU1JmaiMVbkq0KxSJoiMlyhA8YIUef0',
  );
  static const String serviceRoleKey = String.fromEnvironment('SUPABASE_SERVICE_ROLE_KEY', defaultValue: '');

  static const String environment = String.fromEnvironment('ENVIRONMENT', defaultValue: 'development');
  static const bool debug = bool.fromEnvironment('SUPABASE_DEBUG', defaultValue: false);

  // Optional: commonly used bucket names
  static const String userAvatarsBucket = 'user-avatars';
  static const String spotImagesBucket = 'spot-images';
  static const String listImagesBucket = 'list-images';

  static bool get isValid => url.isNotEmpty && anonKey.isNotEmpty;
}

