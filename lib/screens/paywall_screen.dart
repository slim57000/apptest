import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../providers/premium_provider.dart';
import '../services/purchase_service.dart';

/// Écran d'abonnement Premium : liste les offres récupérées depuis l'App
/// Store / Play Store, lance l'achat et propose la restauration d'achat.
class PaywallScreen extends StatelessWidget {
  const PaywallScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final premium = context.watch<PremiumProvider>();

    return Scaffold(
      appBar: AppBar(title: Text(l10n.paywallTitle)),
      body: premium.loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Center(child: Icon(Icons.workspace_premium, size: 56, color: Colors.amber)),
                const SizedBox(height: 12),
                Text(
                  premium.isPremium ? l10n.youArePremium : l10n.goPremium,
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(l10n.paywallDescription, textAlign: TextAlign.center),
                const SizedBox(height: 24),
                if (premium.isPremium) _ActivePremiumCard(isLifetime: premium.isLifetime),
                if (!premium.storeAvailable) const _StoreUnavailableCard(),
                if (premium.storeAvailable && premium.queryError != null)
                  _MessageCard(message: premium.queryError!, isError: true),
                if (premium.error != null) _MessageCard(message: premium.error!, isError: true),
                // Les offres et leurs tarifs restent affichées même quand
                // le Premium est actif (utile en test avec forcePremium) ;
                // seul le bouton d'achat est désactivé.
                if (premium.storeAvailable)
                  ...premium.products.map(
                    (product) => _PlanCard(
                      product: product,
                      pending: premium.purchasePending,
                      canBuy: !premium.isPremium,
                      onTap: () => premium.buy(product),
                    ),
                  ),
                const SizedBox(height: 16),
                Center(
                  child: TextButton(
                    onPressed: premium.purchasePending ? null : () => premium.restore(),
                    child: Text(l10n.restorePurchases),
                  ),
                ),
              ],
            ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final ProductDetails product;
  final bool pending;
  final bool canBuy;
  final VoidCallback onTap;

  const _PlanCard({
    required this.product,
    required this.pending,
    required this.canBuy,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    Widget icon;
    final String title;
    final String description;
    switch (product.id) {
      case PremiumProductIds.monthly:
        icon = const Icon(Icons.calendar_month, size: 32, color: Color(0xFF2563EB));
        title = l10n.monthlyPlan;
        description = l10n.monthlyPlanDescription;
        break;
      case PremiumProductIds.yearly:
        icon = const Icon(Icons.calendar_today, size: 32, color: Color(0xFF2563EB));
        title = l10n.yearlyPlan;
        description = l10n.yearlyPlanDescription;
        break;
      case PremiumProductIds.lifetime:
        icon = Image.asset(
          'assets/icon/lifetime_premium.png',
          width: 32,
          height: 32,
        );
        title = l10n.lifetimePlan;
        description = l10n.lifetimePlanDescription;
        break;
      default:
        icon = const Icon(Icons.event_repeat, size: 32, color: Color(0xFF2563EB));
        title = product.title;
        // Les descriptions localisées ci-dessus couvrent tous les produits
        // déclarés dans PremiumProductIds ; celle du store (product.description)
        // ne sert que de repli pour un produit non prévu par l'app, et n'est
        // traduite que dans la langue configurée sur la fiche du store.
        description = product.description;
    }
    final isLifetime = product.id == PremiumProductIds.lifetime;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: isLifetime ? Colors.amber.withValues(alpha: 0.12) : null,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            icon,
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 14),
            if (pending)
              const SizedBox(width: 24, height: 24, child: CircularProgressIndicator())
            else if (!canBuy)
              Text(
                product.price,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              )
            else
              FilledButton(onPressed: onTap, child: Text(product.price)),
          ],
        ),
      ),
    );
  }
}

class _ActivePremiumCard extends StatelessWidget {
  final bool isLifetime;

  const _ActivePremiumCard({required this.isLifetime});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      color: Colors.amber.withValues(alpha: 0.15),
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 36),
            const SizedBox(height: 10),
            Text(
              isLifetime ? l10n.lifetimeActive : l10n.activeSubscription,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            if (!isLifetime) ...[
              const SizedBox(height: 4),
              Text(
                l10n.manageSubscriptionHint,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StoreUnavailableCard extends StatelessWidget {
  const _StoreUnavailableCard();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      color: Colors.orange.withValues(alpha: 0.15),
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(l10n.storeUnavailable, textAlign: TextAlign.center),
      ),
    );
  }
}

class _MessageCard extends StatelessWidget {
  final String message;
  final bool isError;

  const _MessageCard({required this.message, this.isError = false});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: (isError ? Colors.red : Colors.grey).withValues(alpha: 0.1),
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(message, textAlign: TextAlign.center, style: TextStyle(color: isError ? Colors.red : null)),
      ),
    );
  }
}
