import 'dart:io';
// ignore_for_file: avoid_print - Script file
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:avrai/supabase_config.dart' as config;

/// Script to create a user in Supabase
/// 
/// Usage:
///   dart run scripts/create_supabase_user.dart `<email>` `<password>` `[name]`
/// 
/// Example:
///   dart run scripts/create_supabase_user.dart reis@avrai.org avrai "Reis Gordon"
void main(List<String> args) async {
  if (args.length < 2) {
    print('Usage: dart run scripts/create_supabase_user.dart <email> <password> [name]');
    print('');
    print('Example:');
    print('  dart run scripts/create_supabase_user.dart reis@avrai.org avrai "Reis Gordon"');
    exit(1);
  }

  final email = args[0];
  final password = args[1];
  final name = args.length > 2 ? args[2] : email.split('@').first;

  print('');
  print('=' * 60);
  print('Creating Supabase User');
  print('=' * 60);
  print('');
  print('Email: $email');
  print('Name: $name');
  print('Password: ${'*' * password.length}');
  print('');

  // Initialize Supabase
  if (!config.SupabaseConfig.isValid) {
    print('❌ ERROR: Supabase configuration is invalid');
    print('   Please check your SUPABASE_URL and SUPABASE_ANON_KEY');
    print('   Current URL: ${config.SupabaseConfig.url}');
    print('   Current Key: ${config.SupabaseConfig.anonKey.isEmpty ? "NOT SET" : "SET"}');
    exit(1);
  }

  try {
    // Initialize Supabase if not already initialized
    final supabase = Supabase.instance.client;

    print('✅ Connected to Supabase');
    print('   URL: ${config.SupabaseConfig.url}');
    print('');

    // Check if user already exists
    try {
      final existingUser = await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      
      if (existingUser.user != null) {
        print('✅ User already exists and can sign in');
        print('   User ID: ${existingUser.user!.id}');
        print('   Email: ${existingUser.user!.email}');
        print('   Email Confirmed: ${existingUser.user!.emailConfirmedAt != null}');
        print('');
        
        // Update user metadata if name is provided
        if (name.isNotEmpty) {
          await supabase.auth.updateUser(
            UserAttributes(
              data: {'name': name},
            ),
          );
          print('✅ Updated user name to: $name');
        }
        
        print('');
        print('=' * 60);
        print('✅ SUCCESS: User can sign in with these credentials');
        print('=' * 60);
        exit(0);
      }
    } catch (e) {
      // User doesn't exist or wrong password, continue to create
      print('ℹ️  User does not exist or password is incorrect, creating new user...');
      print('');
    }

    // Create new user
    print('Creating new user...');
    final response = await supabase.auth.signUp(
      email: email,
      password: password,
      data: {'name': name},
    );

    if (response.user != null) {
      print('✅ User created successfully!');
      print('   User ID: ${response.user!.id}');
      print('   Email: ${response.user!.email}');
      print('   Email Confirmed: ${response.user!.emailConfirmedAt != null}');
      print('');
      
      if (response.user!.emailConfirmedAt == null) {
        print('⚠️  WARNING: Email confirmation required');
        print('   The user will need to confirm their email before they can sign in.');
        print('   You can confirm the email in the Supabase dashboard:');
        print('   Authentication → Users → Find user → Confirm email');
        print('');
      }
      
      print('');
      print('=' * 60);
      print('✅ SUCCESS: User created');
      print('=' * 60);
      print('');
      print('You can now sign in with:');
      print('  Email: $email');
      print('  Password: $password');
      print('');
    } else {
      print('❌ ERROR: User creation failed - no user returned');
      exit(1);
    }
  } catch (e) {
    print('❌ ERROR: Failed to create user');
    print('   Error: $e');
    print('');
    
    final errorString = e.toString().toLowerCase();
    if (errorString.contains('user already registered') ||
        errorString.contains('email already exists')) {
      print('ℹ️  This email is already registered.');
      print('   Try signing in instead, or use a different email.');
    } else if (errorString.contains('password') && errorString.contains('weak')) {
      print('ℹ️  Password is too weak.');
      print('   Supabase requires stronger passwords.');
    } else if (errorString.contains('rate limit') ||
        errorString.contains('over_email_send_rate_limit')) {
      print('ℹ️  Rate limit exceeded.');
      print('   Wait a few minutes and try again.');
    } else if (errorString.contains('email')) {
      print('ℹ️  Email validation failed.');
      print('   Please check the email format.');
    }
    
    exit(1);
  }
}
