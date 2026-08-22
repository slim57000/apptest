import 'package:flutter/foundation.dart';

/// Identifiants AdMob.
///
/// App ID natif (déjà dans AndroidManifest.xml) :
/// `ca-app-pub-1101565530376274~3544857241`
/// Unité bannière réelle : [realBannerAndroid].
///
/// ⚠️ MODE DEV PAR DÉFAUT ([useRealAds] à `false`) : ce sont les ID de
/// **test officiels Google** qui servent des publicités de démonstration.
/// Ne JAMAIS cliquer sur de vraies pubs depuis ses propres appareils :
/// suspension du compte AdMob pour trafic invalide garantie.
///
/// Pour passer aux vraies annonces (build production OU test encadré) :
/// 1. mettre [useRealAds] à `true`,
/// 2. ajouter le hash de VOS appareils dans [devTestDeviceIds] tant que ce
///    sont eux qui exécutent l'app : ils recevront des annonces estampillées
///    « Annonce de test » même avec l'ID réel (aucun risque de suspension).
///
/// Le hash s'obtient au premier lancement en mode réel :
/// `adb logcat -s Ads` → ligne
/// « Use RequestConfiguration.Builder().setTestDeviceIds(Arrays.asList("XXXX…")) »
class AdsConfig {
  static const realBannerAndroid = 'ca-app-pub-1101565530376274/8605612236';

  /// Basculer sur les vraies annonces. À laisser `false` tant que seuls vos
  /// appareils personnels exécutent l'app sans leurs hashes ci-dessous.
  static const bool useRealAds = false;

  /// Hashes d'appareils de développement (voir doc de classe).
  static const List<String> devTestDeviceIds = [];

  static const _envBannerUnitId =
      String.fromEnvironment('ADMOB_BANNER_UNIT_ID', defaultValue: '');

  static const _testBannerAndroid = 'ca-app-pub-3940256099942544/6300978111';
  static const _testBannerIOS = 'ca-app-pub-3940256099942544/2934735716';

  static String get bannerAdUnitId {
    // Surcharge manuelle (CI / build release) prioritaire sur tout.
    if (_envBannerUnitId.isNotEmpty) return _envBannerUnitId;
    if (!useRealAds) {
      return defaultTargetPlatform == TargetPlatform.iOS ? _testBannerIOS : _testBannerAndroid;
    }
    return realBannerAndroid;
  }
}
