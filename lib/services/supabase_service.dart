// lib/services/supabase_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static const String supabaseUrl = 'https://majhcpcjojkzzfadhgwc.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1hamhjcGNqb2prenpmYWRoZ3djIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjA5Mjk3MjksImV4cCI6MjA3NjUwNTcyOX0.YOP4HYTTEEEMgRBILE1hhSWm9qhP9cpv2w4boa1zGKU';

  static final SupabaseClient client = Supabase.instance.client;

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
  }
}
