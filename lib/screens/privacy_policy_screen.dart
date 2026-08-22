import 'package:flutter/material.dart';

/// Politique de confidentialité affichée directement dans l'app (au lieu
/// d'un lien externe vers `docs/privacy-policy.html`, hébergé sur GitHub
/// Pages). Contenu bilingue statique, choisi selon la langue de l'app.
///
/// Garder ce texte synchronisé avec `docs/privacy-policy.html`, qui reste
/// la version de référence utilisée pour la déclaration Play Console.
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  static const _sectionsFr = <_Section>[
    _Section(
      'Résumé',
      '• La majorité des données (habitudes, historique, notes, réglages) '
          'reste uniquement sur votre appareil.\n'
          '• Publicité limitée à une seule bannière discrète, uniquement pour '
          'les utilisateurs gratuits (jamais pour les abonnés Premium).\n'
          '• Deux fonctionnalités optionnelles (défis entre amis, sauvegarde '
          'cloud) utilisent un compte anonyme pour synchroniser des données '
          'entre appareils ou avec des amis.',
    ),
    _Section(
      "Données stockées uniquement sur l'appareil",
      'Vos habitudes, leur historique de complétion, vos notes de journal, vos '
          'statistiques et vos préférences (langue, rappels) sont stockées '
          'localement sur votre appareil. Elles ne sont transmises à aucun '
          'serveur, sauf si vous activez une des fonctionnalités optionnelles '
          "ci-dessous. Désinstaller l'application supprime ces données.",
    ),
    _Section(
      'Suivi des pas (Health Connect / Apple Health)',
      'Si vous activez le suivi automatique des pas sur une habitude, '
          "l'application lit votre nombre de pas du jour via Health Connect "
          '(Android) ou Apple Health (iOS), uniquement pour comparer ce nombre '
          "à un objectif et cocher automatiquement l'habitude. Cette donnée "
          "n'est ni stockée au-delà du nécessaire, ni transmise à un serveur.",
    ),
    _Section(
      'Notifications',
      'Les rappels et relances sont des notifications programmées localement '
          "sur votre appareil. Aucune donnée n'est envoyée à un serveur pour "
          'les déclencher.',
    ),
    _Section(
      'Achats intégrés (abonnement Premium)',
      'Les achats (abonnement mensuel/annuel ou accès à vie) sont gérés '
          "entièrement par Google Play / l'App Store. L'application ne "
          'collecte et ne stocke aucune information de paiement ; elle reçoit '
          "uniquement une confirmation du statut de l'achat de la part du "
          'store, pour débloquer les fonctionnalités Premium.',
    ),
    _Section(
      'Publicité (version gratuite uniquement)',
      'Les utilisateurs de la version gratuite voient une seule bannière '
          'publicitaire discrète (jamais de plein écran, jamais '
          "d'interstitiel), fournie par Google AdMob. Les abonnés Premium ne "
          'voient aucune publicité. Google AdMob peut utiliser un identifiant '
          'publicitaire de votre appareil pour choisir les publicités '
          'affichées. Sur iOS, votre autorisation est demandée séparément '
          '(App Tracking Transparency) avant toute personnalisation '
          'publicitaire liée au suivi entre apps.',
    ),
    _Section(
      'Défis entre amis et sauvegarde cloud (fonctionnalités optionnelles)',
      'Si vous utilisez les défis entre amis ou la sauvegarde cloud de vos '
          "habitudes, l'application crée un compte anonyme (aucune adresse "
          'e-mail ni mot de passe demandé) sur notre infrastructure Supabase, '
          'afin de partager votre pseudonyme et votre statut du jour avec les '
          'autres membres du même défi, et/ou stocker une copie de vos '
          'habitudes pour les restaurer après une réinstallation ou sur un '
          'nouvel appareil. Ces données ne sont ni vendues ni partagées à des '
          "tiers, et ne servent à aucune publicité.",
    ),
    _Section(
      'Suppression des données',
      "Désinstaller l'application supprime toutes les données stockées "
          'localement. Pour demander la suppression des données associées à '
          'votre compte anonyme (défis, sauvegarde cloud), contactez-nous à '
          "l'adresse ci-dessous en précisant que vous souhaitez la "
          'suppression de vos données Habitude+.',
    ),
    _Section(
      'Enfants',
      "Habitude+ ne cible pas les enfants et ne collecte pas sciemment de "
          'données concernant des enfants.',
    ),
    _Section(
      'Contact',
      'Pour toute question sur cette politique ou vos données : '
          'florent.neyret@gmail.com',
    ),
  ];

  static const _sectionsEn = <_Section>[
    _Section(
      'Summary',
      '• Most data (habits, history, notes, settings) stays on your device '
          'only.\n'
          '• Advertising limited to a single, discreet banner, shown only to '
          'free-tier users (never to Premium subscribers).\n'
          '• Two optional features (friend challenges, cloud backup) use an '
          'anonymous account to sync data across devices or with friends.',
    ),
    _Section(
      'Data stored on-device only',
      'Your habits, completion history, journal notes, statistics and '
          'preferences (language, reminders) are stored locally on your '
          'device. They are not sent to any server unless you enable one of '
          'the optional features below. Uninstalling the app deletes this '
          'data.',
    ),
    _Section(
      'Step tracking (Health Connect / Apple Health)',
      'If you enable automatic step tracking on a habit, the app reads your '
          'step count for the day via Health Connect (Android) or Apple '
          'Health (iOS), solely to compare it to a goal and auto-complete the '
          "habit. This data is not stored beyond what's needed, and is never "
          'sent to a server.',
    ),
    _Section(
      'Notifications',
      'Reminders and follow-up nudges are notifications scheduled locally on '
          'your device. No data is sent to a server to trigger them.',
    ),
    _Section(
      'In-app purchases (Premium subscription)',
      'Purchases (monthly/yearly subscription or lifetime access) are '
          'handled entirely by Google Play / the App Store. The app does not '
          'collect or store any payment information; it only receives a '
          'purchase-status confirmation from the store to unlock Premium '
          'features.',
    ),
    _Section(
      'Advertising (free tier only)',
      'Free-tier users see a single, discreet banner ad (never full-screen, '
          'never an interstitial), served by Google AdMob. Premium '
          'subscribers see no ads at all. Google AdMob may use a device '
          'advertising identifier to select which ads are shown. On iOS, '
          'your permission is requested separately (App Tracking '
          'Transparency) before any cross-app tracking-based '
          'personalization.',
    ),
    _Section(
      'Friend challenges and cloud backup (optional features)',
      'If you use friend challenges or cloud backup, the app creates an '
          'anonymous account (no email or password required) on our Supabase '
          'infrastructure, to share the display name you choose and your '
          'status for the day with other members of the same challenge, '
          "and/or store a copy of your habits so they can be restored after "
          'a reinstall or on a new device. This data is never sold or shared '
          'with third parties, and is never used for advertising.',
    ),
    _Section(
      'Data deletion',
      'Uninstalling the app deletes all locally stored data. To request '
          'deletion of data tied to your anonymous account (challenges, '
          'cloud backup), contact us at the address below stating you\'d '
          'like your Habitude+ data deleted.',
    ),
    _Section(
      'Children',
      'Habitude+ is not directed at children and does not knowingly collect '
          'data from children.',
    ),
    _Section(
      'Contact',
      'For any question about this policy or your data: '
          'florent.neyret@gmail.com',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isFrench = Localizations.localeOf(context).languageCode == 'fr';
    final sections = isFrench ? _sectionsFr : _sectionsEn;
    final title = isFrench
        ? 'Habitude+ — Politique de confidentialité'
        : 'Habitude+ — Privacy Policy';
    final updated = isFrench
        ? 'Dernière mise à jour : 18 août 2026'
        : 'Last updated: August 18, 2026';

    return Scaffold(
      appBar: AppBar(
        title: Text(isFrench ? 'Politique de confidentialité' : 'Privacy Policy'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(
            updated,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: Theme.of(context).hintColor),
          ),
          const SizedBox(height: 20),
          for (final section in sections) ...[
            Text(section.heading, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(section.body, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 20),
          ],
        ],
      ),
    );
  }
}

class _Section {
  final String heading;
  final String body;

  const _Section(this.heading, this.body);
}
