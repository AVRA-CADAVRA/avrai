#!/usr/bin/env dart
/// Create the local-llm-models storage bucket via Supabase
/// 
/// This script uses curl to execute SQL via Supabase Management API
/// 
/// Usage:
///   SUPABASE_ACCESS_TOKEN=<token> dart run scripts/create_storage_bucket.dart
/// 
/// Or get token from: https://supabase.com/dashboard/account/tokens

import 'dart:io';
import 'dart:convert';

Future<void> main() async {
  final accessToken = Platform.environment['SUPABASE_ACCESS_TOKEN'];
  final projectRef = 'nfzlwgbvezwwrutqpedy';

  if (accessToken == null || accessToken.isEmpty) {
    print('❌ SUPABASE_ACCESS_TOKEN environment variable is required');
    print('');
    print('Get your access token from:');
    print('  https://supabase.com/dashboard/account/tokens');
    print('');
    print('Then run:');
    print('  SUPABASE_ACCESS_TOKEN=<token> dart run scripts/create_storage_bucket.dart');
    exit(1);
  }

  print('📦 Creating storage bucket: local-llm-models');
  print('   Project: $projectRef\n');

  // Read the SQL migration file
  final sqlFile = File('supabase/migrations/064_local_llm_models_bucket_v1.sql');
  if (!await sqlFile.exists()) {
    print('❌ Migration file not found: ${sqlFile.path}');
    exit(1);
  }

  final sql = await sqlFile.readAsString();

  // Execute SQL via Supabase Management API
  try {
    final apiUrl = 'https://api.supabase.com/v1/projects/$projectRef/database/query';
    
    final client = HttpClient();
    final request = await client.postUrl(Uri.parse(apiUrl));
    request.headers.set('Authorization', 'Bearer $accessToken');
    request.headers.set('Content-Type', 'application/json');
    request.write(jsonEncode({
      'query': sql,
    }));

    final response = await request.close();
    final statusCode = response.statusCode;
    final body = await response.transform(utf8.decoder).join();

    client.close();

    if (statusCode >= 200 && statusCode < 300) {
      print('✅ Bucket and policies created successfully!');
      print('');
      print('Verify in Supabase Dashboard:');
      print('  https://supabase.com/dashboard/project/$projectRef/storage/buckets');
    } else {
      print('⚠️  Response status: $statusCode');
      print('   Response: ${body.length > 200 ? "${body.substring(0, 200)}..." : body}');
      print('');
      print('Alternative: Run the SQL manually in Supabase Dashboard → SQL Editor');
      print('  File: supabase/migrations/064_local_llm_models_bucket_v1.sql');
    }
  } catch (e) {
    print('❌ Error: $e');
    print('');
    print('Alternative: Run the SQL manually in Supabase Dashboard → SQL Editor');
    print('  1. Go to: https://supabase.com/dashboard/project/$projectRef/editor');
    print('  2. Click SQL Editor');
    print('  3. Paste SQL from: supabase/migrations/064_local_llm_models_bucket_v1.sql');
    exit(1);
  }
}
