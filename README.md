# Habitude+

Application Flutter (iOS + Android) de suivi d'habitudes avec un abonnement
Premium payant. Pensée pour être rapide à développer : **aucun backend**,
tout est stocké localement sur l'appareil.

## Fonctionnalités

- Créer des habitudes (nom, emoji, couleur, jours actifs dans la semaine).
- Cocher chaque jour ses habitudes, avec calcul automatique du streak
  (série de jours consécutifs).
- Version gratuite : jusqu'à **3 habitudes actives**.
- Version **Premium** (abonnement mensuel ou annuel, via achat in-app natif
  App Store / Play Store) :
  - Habitudes illimitées.
  - Statistiques avancées : meilleure série, taux de complétion sur 30
    jours, graphique de complétion sur 7 jours.
- Petite animation confettis quand une habitude atteint un palier de streak
  (7, 14, 21 jours...).

## Stack technique

- Flutter (iOS + Android), sans backend : persistance locale via
  `shared_preferences` (`lib/services/storage_service.dart`).
- `provider` pour l'état de l'application.
- `in_app_purchase` pour l'abonnement Premium — achats natifs App Store /
  Play Store, aucun serveur de paiement à héberger. Voir
  `lib/services/purchase_service.dart` et `lib/providers/premium_provider.dart`.
- Design : `google_fonts` (typographie), `flutter_animate`
  (micro-animations), `fl_chart` (graphique de complétion), `confetti`
  (célébration de streak).

## Mise en route

```bash
flutter pub get
flutter run
```

Aucune configuration Firebase ni compte requis pour l'essentiel de l'app.

## Configurer l'abonnement Premium (App Store / Play Store)

Le code de l'abonnement est prêt, mais les **produits d'abonnement doivent
être créés côté store** avant de pouvoir tester un achat réel :

- **Google Play Console** → votre application → Monétisation → Produits →
  Abonnements → créer deux abonnements avec exactement ces IDs :
  - `habitude_premium_mensuel`
  - `habitude_premium_annuel`
- **App Store Connect** → votre application → Fonctionnalités de l'app →
  Achats intégrés → créer un groupe d'abonnements avec les deux mêmes IDs
  de produit.
- Les IDs sont centralisés dans `SubscriptionProductIds`
  (`lib/services/purchase_service.dart`) si vous voulez les renommer.
- Sur Android, testez avec un compte "testeur" ajouté dans Play Console.
  Sur iOS, testez avec un compte Sandbox App Store Connect (nécessite un
  Mac/Xcode — la plateforme iOS n'a pas été testée dans cet environnement,
  seul le scaffold `ios/` généré par `flutter create` est présent).

## Structure du code

```
lib/
  models/       # Habit (logique de streak / taux de complétion)
  services/     # StorageService (persistance locale), PurchaseService
  providers/    # HabitsProvider, PremiumProvider (état app)
  screens/      # home, add_habit, habit_detail, paywall, settings
  widgets/      # HabitCard
  theme.dart    # thème Material 3 + palettes couleurs/emojis
```

## Limites connues (v1 volontairement simple)

- Le statut Premium est confirmé côté client uniquement (pas de
  vérification serveur des reçus d'achat) : suffisant pour lancer vite,
  mais falsifiable par un utilisateur qui modifierait l'app. Étape
  suivante recommandée : vérification serveur (Cloud Function + webhook
  Play/App Store) ou un service comme RevenueCat.
- Pas de détection d'annulation/expiration d'abonnement en direct (pas de
  webhook côté store branché) : `isPremium` reste vrai tant qu'aucun
  nouvel événement d'achat n'est reçu par l'app.
- Pas de sauvegarde cloud : les habitudes vivent uniquement sur l'appareil
  (désinstaller l'app supprime les données). Une sauvegarde
  cloud/multi-appareil serait un bon argument Premium additionnel.
- Testé via `flutter analyze` et `flutter test` (scaffold Android/iOS
  généré par `flutter create`, non compilé en APK/IPA faute de SDK Android
  dans cet environnement de développement).
