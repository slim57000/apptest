import 'package:flutter/foundation.dart';

/// Identifiants AdMob. Par défaut, les ID de **test officiels Google**
/// (sûrs à committer, affichent des publicités de démonstration, à garder
/// tant que l'app n'est pas publiée -- utiliser de vrais ID en dehors des
/// tests expose à une suspension du compte AdMob pour trafic invalide).
///
/// À remplacer par un vrai ID d'unité publicitaire via
/// `--dart-define=ADMOB_BANNER_UNIT_ID=...` avant publication (voir le
/// README, "Configurer les publicités"). L'App ID (différent de l'ID
/// d'unité publicitaire) se configure séparément, côté natif, dans
/// `AndroidManifest.xml` / `Info.plist`.
class AdsConfig {
  static const _envBannerUnitId = String.fromEnvironment('ADMOB_BANNER_UNIT_ID', defaultValue: '');

  static const _testBannerAndroid = 'ca-app-pub-3940256099942544/6300978111';
  static const _testBannerIOS = 'ca-app-pub-3940256099942544/2934735716';

  static String get bannerAdUnitId {
    if (_envBannerUnitId.isNotEmpty) return _envBannerUnitId;
    return defaultTargetPlatform == TargetPlatform.iOS ? _testBannerIOS : _testBannerAndroid;
  }
}
