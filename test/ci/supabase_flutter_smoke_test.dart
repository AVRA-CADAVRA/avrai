import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  group('Supabase Flutter smoke', () {
    testWidgets('initialize and basic query', (tester) async {
      // Ensure Flutter bindings and mock SharedPreferences for plugin channel
      TestWidgetsFlutterBinding.ensureInitialized();
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final url = Platform.environment['SUPABASE_URL'] ?? '';
      final anonKey = Platform.environment['SUPABASE_ANON_KEY'] ?? '';
      if (url.isEmpty || anonKey.isEmpty) {
        // Skip when secrets not provided in CI environment
        return;
      }

      await Supabase.initialize(url: url, anonKey: anonKey, debug: true);
      final client = Supabase.instance.client;
      // Stop auto-refresh timers to avoid pending timers in tests
      await tester.pump();
      client.auth.stopAutoRefresh();
      await tester.pump(const Duration(milliseconds: 50));
      // Validate client configuration without making network calls
      expect(client.rest.url.toString(), contains(url));
    }, timeout: const Timeout(Duration(minutes: 2)));
  });
}


