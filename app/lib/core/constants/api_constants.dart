class ApiConstants {
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL', defaultValue: '');
  static const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '');
  static const backendBaseUrl = String.fromEnvironment(
    'BACKEND_URL',
    defaultValue: 'https://leaflens-api.onrender.com',
  );
}
