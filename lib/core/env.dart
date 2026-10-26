/// Configuração recebida por --dart-define. Nenhuma credencial é embutida.
///
/// flutter run --dart-define=SUPABASE_URL=https://xyz.supabase.co \
///             --dart-define=SUPABASE_PUBLISHABLE_KEY=sb_publishable_...
///
/// (SUPABASE_ANON_KEY também é aceito para projetos com chave "anon" legada.)
/// Nunca use a chave service_role no aplicativo.
class AppEnv {
  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const String _publishableKey = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');
  static const String _anonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  static String get supabaseKey => _publishableKey.isNotEmpty ? _publishableKey : _anonKey;

  static bool get hasSupabase => supabaseUrl.isNotEmpty && supabaseKey.isNotEmpty;
}
