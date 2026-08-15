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
                const Icon(Icons.workspace_premium, size: 56, color: Colors.amber),
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
                if (premium.storeAvailable && !premium.isPremium)
                  ...premium.products.map(
                    (product) => _PlanCard(
                      product: product,
                      pending: premium.purchasePending,
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
  final VoidCallback onTap;

  const _PlanCard({required this.product, required this.pending, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final IconData icon;
    final String title;
    switch (product.id) {
      case PremiumProductIds.yearly:
        icon = Icons.calendar_month;
        title = l10n.yearlyPlan;
        break;
      case PremiumProductIds.lifetime:
        icon = Icons.all_inclusive;
        title = l10n.lifetimePlan;
        break;
      default:
        icon = Icons.event_repeat;
        title = l10n.monthlyPlan;
    }
    final isLifetime = product.id == PremiumProductIds.lifetime;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: isLifetime ? Colors.amber.withValues(alpha: 0.12) : null,
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(product.description),
        trailing: pending
            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator())
            : FilledButton(onPressed: onTap, child: Text(product.price)),
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
      child: ListTile(
        leading: const Icon(Icons.check_circle, color: Colors.green),
        title: Text(isLifetime ? l10n.lifetimeActive : l10n.activeSubscription),
        subtitle: isLifetime ? null : Text(l10n.manageSubscriptionHint),
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
        child: Text(l10n.storeUnavailable),
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
        child: Text(message, style: TextStyle(color: isError ? Colors.red : null)),
      ),
    );
  }
}
