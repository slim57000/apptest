/// Identifiants du projet Supabase pour les défis entre amis.
///
/// À remplir après avoir créé un projet sur https://supabase.com (gratuit)
/// et exécuté `supabase/schema.sql` dans son éditeur SQL — voir le README
/// ("Configurer les défis entre amis") pour la procédure complète.
///
/// Laissés vides, les défis affichent un message "non configuré" au lieu
/// de planter l'app : aucune des autres fonctionnalités n'en dépend.
class SupabaseConfig {
  static const url = String.fromEnvironment('SUPABASE_URL', defaultValue: '');
  static const anonKey = String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '');

  static bool get isConfigured => url.isNotEmpty && anonKey.isNotEmpty;
}
