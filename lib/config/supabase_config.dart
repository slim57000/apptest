/// Identifiants du projet Supabase pour les défis entre amis.
///
/// Projet : https://supabase.com/dashboard/project/kcjunokemdnrvhkhahsl
///
/// La clé ci-dessous est la clé **publishable/anon** (publique par design) :
/// la sécurité est assurée par les policies RLS de `supabase/schema.sql`.
/// Ne JAMAIS mettre ici la clé `service_role` (secrète).
///
/// Ces valeurs restent surchargeables par `--dart-define` (utile en CI pour
/// pointer vers un projet de test) ; à défaut, ce sont elles qui servent.
class SupabaseConfig {
  static const url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://kcjunokemdnrvhkhahsl.supabase.co',
  );
  static const anonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'sb_publishable_OFR8wC9telLsRqwEgbeMxg_Yn8KRJNY',
  );

  static bool get isConfigured => url.isNotEmpty && anonKey.isNotEmpty;
}
