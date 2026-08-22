import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/app_localizations.dart';
import '../widgets/app_logo.dart';

/// Écran Mentions légales / CGU
class LegalScreen extends StatelessWidget {
  final bool isPrivacyPolicy;

  const LegalScreen({super.key, this.isPrivacyPolicy = false});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final title = isPrivacyPolicy ? l10n.privacyPolicyTitle : l10n.legalTitle;

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Center(child: AppLogo(size: 48)),
          const SizedBox(height: 16),
          Text(
            title,
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            isPrivacyPolicy
                ? l10n.privacyPolicyLastUpdated('${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}')
                : l10n.legalLastUpdated('${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}'),
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          if (isPrivacyPolicy) ..._privacyPolicySections(l10n, context)
          else ..._legalSections(l10n, context),
          const SizedBox(height: 32),
          Center(
            child: TextButton.icon(
              icon: const Icon(Icons.email_outlined),
              label: Text(l10n.contactEmail),
              onPressed: () => _launchEmail(context),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _privacyPolicySections(AppLocalizations l10n, BuildContext context) => [
        _Section(title: l10n.privacyDataController, children: [
          _Paragraph(l10n.privacyDataControllerDesc),
        ]),
        _Section(title: l10n.privacyDataCollected, children: [
          _Paragraph(l10n.privacyDataCollectedDesc),
          _BulletList(l10n.privacyDataTypes),
        ]),
        _Section(title: l10n.privacyDataUsage, children: [
          _Paragraph(l10n.privacyDataUsageDesc),
          _BulletList(l10n.privacyUsagePurposes),
        ]),
        _Section(title: l10n.privacyDataSharing, children: [
          _Paragraph(l10n.privacyDataSharingDesc),
          _BulletList(l10n.privacySharingCases),
        ]),
        _Section(title: l10n.privacyDataRetention, children: [
          _Paragraph(l10n.privacyDataRetentionDesc),
        ]),
        _Section(title: l10n.privacyUserRights, children: [
          _Paragraph(l10n.privacyUserRightsDesc),
          _BulletList(l10n.privacyRightsList),
        ]),
        _Section(title: l10n.privacySecurity, children: [
          _Paragraph(l10n.privacySecurityDesc),
        ]),
        _Section(title: l10n.privacyThirdParty, children: [
          _Paragraph(l10n.privacyThirdPartyDesc),
        ]),
        _Section(title: l10n.privacyChildren, children: [
          _Paragraph(l10n.privacyChildrenDesc),
        ]),
        _Section(title: l10n.privacyChanges, children: [
          _Paragraph(l10n.privacyChangesDesc),
        ]),
        _Section(title: l10n.privacyContact, children: [
          _Paragraph(l10n.privacyContactDesc),
        ]),
      ];

  List<Widget> _legalSections(AppLocalizations l10n, BuildContext context) => [
        _Section(title: l10n.legalAcceptance, children: [
          _Paragraph(l10n.legalAcceptanceDesc),
        ]),
        _Section(title: l10n.legalServiceDescription, children: [
          _Paragraph(l10n.legalServiceDescriptionDesc),
        ]),
        _Section(title: l10n.legalUserAccount, children: [
          _Paragraph(l10n.legalUserAccountDesc),
        ]),
        _Section(title: l10n.legalPremiumSubscription, children: [
          _Paragraph(l10n.legalPremiumSubscriptionDesc),
          _BulletList(l10n.legalSubscriptionDetails),
        ]),
        _Section(title: l10n.legalUserContent, children: [
          _Paragraph(l10n.legalUserContentDesc),
        ]),
        _Section(title: l10n.legalProhibited, children: [
          _Paragraph(l10n.legalProhibitedDesc),
          _BulletList(l10n.legalProhibitedList),
        ]),
        _Section(title: l10n.legalIntellectualProperty, children: [
          _Paragraph(l10n.legalIntellectualPropertyDesc),
        ]),
        _Section(title: l10n.legalDisclaimer, children: [
          _Paragraph(l10n.legalDisclaimerDesc),
        ]),
        _Section(title: l10n.legalLiability, children: [
          _Paragraph(l10n.legalLiabilityDesc),
        ]),
        _Section(title: l10n.legalTermination, children: [
          _Paragraph(l10n.legalTerminationDesc),
        ]),
        _Section(title: l10n.legalChanges, children: [
          _Paragraph(l10n.legalChangesDesc),
        ]),
        _Section(title: l10n.legalGoverningLaw, children: [
          _Paragraph(l10n.legalGoverningLawDesc),
        ]),
        _Section(title: l10n.legalContact, children: [
          _Paragraph(l10n.legalContactDesc),
        ]),
      ];

  Future<void> _launchEmail(BuildContext context) async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'contact@rampedigitale.fr',
      query: 'subject=${Uri.encodeComponent('Habitude+ - ${isPrivacyPolicy ? 'Confidentialité' : 'CGU'}')}&body=${Uri.encodeComponent('Bonjour,\n\n')}', 
    );
    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    }
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _Section({required this.title, required this.children});

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          ...children,
          const SizedBox(height: 16),
        ],
      );
}

class _Paragraph extends StatelessWidget {
  final String text;

  const _Paragraph(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Text(text, style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.5)),
      );
}

class _BulletList extends StatelessWidget {
  final String items;

  const _BulletList(this.items);

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        // Les listes sont stockées comme une chaîne "a|b|c" dans les ARB :
        // le format ARB de Flutter ne supporte pas les tableaux comme
        // valeur de ressource, uniquement des chaînes.
        children: items.split('|').map((item) => Padding(
              padding: const EdgeInsets.only(left: 16, bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('• ', style: Theme.of(context).textTheme.bodyMedium),
                  Expanded(child: Text(item, style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.5))),
                ],
              ),
            )).toList(),
      );
}