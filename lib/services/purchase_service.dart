import 'dart:async';

import 'package:in_app_purchase/in_app_purchase.dart';

/// Identifiants des abonnements à créer dans App Store Connect et Google
/// Play Console (mêmes IDs des deux côtés pour simplifier le code).
class SubscriptionProductIds {
  static const monthly = 'habitude_premium_mensuel';
  static const yearly = 'habitude_premium_annuel';

  static const all = {monthly, yearly};
}

/// Fine wrapper autour de `in_app_purchase` : interroge les stores, lance
/// un achat et relaie les mises à jour (y compris la restauration). Ne
/// connaît rien de la persistance locale — c'est le rôle de [PremiumProvider].
class PurchaseService {
  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  bool isAvailable = false;
  List<ProductDetails> products = [];
  String? queryError;

  Future<void> init({
    required void Function(PurchaseDetails purchase) onPurchaseUpdate,
    required void Function(String message) onError,
  }) async {
    isAvailable = await _iap.isAvailable();
    if (!isAvailable) return;

    _subscription = _iap.purchaseStream.listen(
      (purchases) => _handleUpdates(purchases, onPurchaseUpdate, onError),
      onError: (Object error) => onError(error.toString()),
    );

    final response = await _iap.queryProductDetails(SubscriptionProductIds.all);
    if (response.error != null) {
      queryError = response.error!.message;
    } else if (response.notFoundIDs.isNotEmpty) {
      queryError = 'Produits introuvables côté store : '
          '${response.notFoundIDs.join(', ')}. Vérifiez leur configuration '
          'dans App Store Connect / Play Console.';
    }
    products = response.productDetails;
  }

  Future<void> buy(ProductDetails product) {
    final purchaseParam = PurchaseParam(productDetails: product);
    return _iap.buyNonConsumable(purchaseParam: purchaseParam);
  }

  Future<void> restorePurchases() => _iap.restorePurchases();

  Future<void> _handleUpdates(
    List<PurchaseDetails> purchases,
    void Function(PurchaseDetails purchase) onPurchaseUpdate,
    void Function(String message) onError,
  ) async {
    for (final purchase in purchases) {
      switch (purchase.status) {
        case PurchaseStatus.pending:
          break;
        case PurchaseStatus.error:
          onError(purchase.error?.message ?? 'Achat échoué.');
          break;
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          if (SubscriptionProductIds.all.contains(purchase.productID)) {
            onPurchaseUpdate(purchase);
          }
          break;
        case PurchaseStatus.canceled:
          break;
      }
      if (purchase.pendingCompletePurchase) {
        await _iap.completePurchase(purchase);
      }
    }
  }

  void dispose() {
    _subscription?.cancel();
  }
}
