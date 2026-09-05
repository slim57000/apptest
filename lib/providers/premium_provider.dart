import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/purchase_service.dart';

/// Statut Premium de l'utilisateur, dérivé des achats in-app. Persisté
/// localement (pas de compte / backend) : `isPremium` reste vrai tant
/// qu'aucune vérification serveur ne vient le contredire — voir le README
/// pour les limites de cette approche « v1 rapide ».
class PremiumProvider extends ChangeNotifier {
  static const _prefsKey = 'is_premium_v1';
  static const _productIdPrefsKey = 'premium_product_id_v1';

  /// [DEV] Force le statut Premium sans passer par la boutique (les produits
  /// in-app ne sont pas encore publiés sur Play Console / App Store Connect).
  /// ⚠️ À repasser à `false` avant toute mise en production.
  static const bool forcePremium = false;

  final PurchaseService _purchaseService;

  bool _isPremium = forcePremium;
  String? _premiumProductId;
  bool _loading = true;
  bool _purchasePending = false;
  String? _error;

  PremiumProvider(this._purchaseService) {
    _init();
  }

  bool get isPremium => _isPremium;
  bool get isLifetime => _premiumProductId == PremiumProductIds.lifetime;
  bool get loading => _loading;
  bool get purchasePending => _purchasePending;
  bool get storeAvailable => _purchaseService.isAvailable;
  String? get error => _error;
  String? get queryError => _purchaseService.queryError;
  List<ProductDetails> get products => _purchaseService.products;

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    _isPremium = forcePremium || (prefs.getBool(_prefsKey) ?? false);
    _premiumProductId = prefs.getString(_productIdPrefsKey);
    notifyListeners();

    await _purchaseService.init(
      onPurchaseUpdate: (purchase) => _setPremium(purchase.productID),
      onError: (message) {
        _error = message;
        _purchasePending = false;
        notifyListeners();
      },
    );
    _loading = false;
    notifyListeners();

    // Restauration silencieuse au lancement (nouvel appareil, réinstall,
    // stockage local effacé...) : sans spinner ni carte d'erreur, l'échec
    // est invisible pour l'utilisateur qui n'a rien demandé explicitement.
    // Le bouton "Restaurer mes achats" du paywall reste le chemin manuel.
    if (_purchaseService.isAvailable) {
      unawaited(_purchaseService.restorePurchases().catchError((_) {}));
    }
  }

  Future<void> buy(ProductDetails product) async {
    _error = null;
    _purchasePending = true;
    notifyListeners();
    try {
      await _purchaseService.buy(product);
    } catch (e) {
      _error = e.toString();
      _purchasePending = false;
      notifyListeners();
    }
  }

  Future<void> restore() async {
    _error = null;
    _purchasePending = true;
    notifyListeners();
    try {
      await _purchaseService.restorePurchases();
    } catch (e) {
      _error = e.toString();
    } finally {
      _purchasePending = false;
      notifyListeners();
    }
  }

  Future<void> _setPremium(String productId) async {
    _isPremium = true;
    _premiumProductId = productId;
    _purchasePending = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsKey, true);
    await prefs.setString(_productIdPrefsKey, productId);
    notifyListeners();
  }

  /// [DEBUG UNIQUEMENT] Active/désactive le Premium localement sans achat,
  /// pour tester les fonctionnalités Premium en développement. Un no-op en
  /// dehors de `flutter run` (kDebugMode) : absent des builds release, donc
  /// jamais un moyen de débloquer le Premium gratuitement pour un vrai
  /// utilisateur.
  Future<void> debugSetPremium(bool value) async {
    if (!kDebugMode) return;
    _isPremium = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsKey, value);
    if (!value) await prefs.remove(_productIdPrefsKey);
    notifyListeners();
  }

  @override
  void dispose() {
    _purchaseService.dispose();
    super.dispose();
  }
}
