/// Configurações de ambiente e conexão com o Supabase.
///
/// Os valores padrão estão pré-configurados com o projeto Supabase,
/// mas ainda podem ser sobrescritos via --dart-define se necessário.
class AppEnv {
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://juunvlqdpqwycidjpvvs.supabase.co',
  );

  static const String _publishableKey = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');

  static const String _anonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imp1dW52bHFkcHF3eWNpZGpwdnZzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTMwMTAwNDMsImV4cCI6MjEwODU4NjA0M30.ZilfTmgs7Dz8NStH1m-pc3mLjeQ3Ueiua6aMxDL_ii0',
  );

  static String get supabaseKey => _publishableKey.isNotEmpty ? _publishableKey : _anonKey;

  static bool get hasSupabase => supabaseUrl.isNotEmpty && supabaseKey.isNotEmpty;
}
