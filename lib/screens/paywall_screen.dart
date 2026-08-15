import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:provider/provider.dart';

import '../providers/premium_provider.dart';
import '../services/purchase_service.dart';

/// Écran d'abonnement Premium : liste les offres récupérées depuis l'App
/// Store / Play Store, lance l'achat et propose la restauration d'achat.
class PaywallScreen extends StatelessWidget {
  const PaywallScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final premium = context.watch<PremiumProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Habitude+ Premium')),
      body: premium.loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Icon(Icons.workspace_premium, size: 56, color: Colors.amber),
                const SizedBox(height: 12),
                Text(
                  premium.isPremium ? 'Vous êtes Premium' : 'Passez Premium',
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  "Habitudes illimitées, statistiques avancées (meilleure "
                  "série, taux de complétion) et graphiques.",
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                if (premium.isPremium) const _ActivePremiumCard(),
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
                    child: const Text('Restaurer mes achats'),
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
    final isYearly = product.id == SubscriptionProductIds.yearly;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Icon(isYearly ? Icons.calendar_month : Icons.event_repeat),
        title: Text(isYearly ? 'Abonnement annuel' : 'Abonnement mensuel'),
        subtitle: Text(product.description),
        trailing: pending
            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator())
            : FilledButton(onPressed: onTap, child: Text(product.price)),
      ),
    );
  }
}

class _ActivePremiumCard extends StatelessWidget {
  const _ActivePremiumCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.amber.withValues(alpha: 0.15),
      margin: const EdgeInsets.only(bottom: 16),
      child: const ListTile(
        leading: Icon(Icons.check_circle, color: Colors.green),
        title: Text('Abonnement actif'),
        subtitle: Text(
          "Gérez ou annulez votre abonnement depuis les réglages de "
          "l'App Store / Google Play de votre téléphone.",
        ),
      ),
    );
  }
}

class _StoreUnavailableCard extends StatelessWidget {
  const _StoreUnavailableCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.orange.withValues(alpha: 0.15),
      margin: const EdgeInsets.only(bottom: 16),
      child: const Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          "Le magasin d'applications n'est pas disponible sur cet appareil "
          "(simulateur, ou app installée hors Play Store / App Store). "
          "Testez sur un appareil réel connecté à un compte de test.",
        ),
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
