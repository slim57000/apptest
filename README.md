# Habitude+

Application Flutter de suivi d'habitudes avec un abonnement Premium payant.
Pensée pour être rapide à développer : **aucun backend**, tout est stocké
localement sur l'appareil. **Sortie ciblée : Android en premier** (le
scaffold iOS généré par `flutter create` est présent mais pas la priorité
actuelle, et n'a pas pu être testé faute de Mac/Xcode).

## Fonctionnalités

- Créer des habitudes (nom, emoji, couleur, jours actifs dans la semaine).
- Cocher chaque jour ses habitudes, avec calcul automatique du streak
  (série de jours consécutifs).
- **Rappel quotidien** optionnel par habitude (notification locale à une
  heure choisie, uniquement les jours actifs) — voir
  `lib/services/notification_service.dart`.
- Version gratuite : jusqu'à **3 habitudes actives**.
- Version **Premium** (abonnement mensuel/annuel ou achat à vie, via achat
  in-app natif Play Store / App Store) :
  - Habitudes illimitées.
  - Statistiques avancées : meilleure série, taux de complétion sur 30
    jours, graphique de complétion sur 7 jours.
  - **Gel de série** (streak freeze) : si un jour actif a été manqué hier,
    un utilisateur Premium peut le "geler" pour ne pas casser sa série
    (façon Duolingo). Limité à un gel tous les 7 jours par habitude pour
    rester une roue de secours, pas un contournement — voir
    `Habit.canFreezeYesterday` / `Habit.freezeYesterday()` dans
    `lib/models/habit.dart`.
- Petite animation confettis quand une habitude atteint un palier de streak
  (7, 14, 21 jours...).
- **Français et anglais**, avec repli automatique sur le français si la
  langue de l'appareil n'est ni l'un ni l'autre.
- Icône d'application personnalisée (flamme sur fond violet, générée dans
  `assets/icon/`) appliquée à Android/iOS/web via `flutter_launcher_icons`
  — plus l'icône Flutter par défaut.

## Stack technique

- Flutter, sans backend : persistance locale via `shared_preferences`
  (`lib/services/storage_service.dart`).
- `provider` pour l'état de l'application.
- `in_app_purchase` pour l'abonnement Premium — achats natifs Play Store /
  App Store, aucun serveur de paiement à héberger. Voir
  `lib/services/purchase_service.dart` et `lib/providers/premium_provider.dart`.
- Localisation via le système standard Flutter (`flutter_localizations` +
  `flutter gen-l10n`) : fichiers source dans `lib/l10n/*.arb`, le code
  généré (`app_localizations*.dart`) n'est pas versionné (régénéré
  automatiquement grâce à `generate: true` dans `pubspec.yaml`).
- `flutter_local_notifications` + `timezone` pour les rappels quotidiens
  locaux (aucun serveur de push).
- Design : `google_fonts` (typographie), `flutter_animate`
  (micro-animations), `fl_chart` (graphique de complétion), `confetti`
  (célébration de streak).

## Mise en route

```bash
flutter pub get
flutter run
```

Aucune configuration Firebase ni compte requis pour l'essentiel de l'app.

## Ajouter/modifier une langue

Éditer `lib/l10n/app_fr.arb` (fichier modèle) et `lib/l10n/app_en.arb`, puis
`flutter gen-l10n` (ou simplement relancer l'app, `generate: true` régénère
le code automatiquement). Pour ajouter une langue : dupliquer un fichier
`app_XX.arb`, traduire les valeurs, et l'ajouter à `supportedLocales` sera
automatique au prochain build.

## Configurer l'abonnement Premium (Play Store / App Store)

Le code est prêt pour 3 produits Premium, mais ils doivent être **créés
côté store** avant de pouvoir tester un achat réel. Prix conseillés
(fourchette basse du marché des habit trackers, à ajuster librement — le
code affiche simplement `product.price` tel que configuré côté store) :

| Produit | ID | Type | Prix conseillé |
|---|---|---|---|
| Mensuel | `habitude_premium_mensuel` | Abonnement | 3,99 € |
| Annuel | `habitude_premium_annuel` | Abonnement | 24,99 € (~2,08 €/mois) |
| À vie | `habitude_premium_a_vie` | Achat unique (non-consommable) | 39,99 € |

- **Google Play Console** (priorité actuelle) → votre application →
  Monétisation → Produits :
  - Sous **Abonnements** : créer `habitude_premium_mensuel` et
    `habitude_premium_annuel`.
  - Sous **Produits gérés** (achats intégrés classiques, pas abonnements) :
    créer `habitude_premium_a_vie`.
- **App Store Connect** (plus tard, si sortie iOS) → votre application →
  Fonctionnalités de l'app → Achats intégrés : un groupe d'abonnements
  pour les deux premiers IDs, et un achat **non-consommable** pour le
  troisième.
- Les IDs sont centralisés dans `PremiumProductIds`
  (`lib/services/purchase_service.dart`) si vous voulez les renommer.
- Sur Android, testez avec un compte "testeur" ajouté dans Play Console
  (les achats sur émulateur/APK non signé release échoueront).
- L'achat à vie convertit les utilisateurs allergiques aux abonnements qui,
  sinon, n'achèteraient rien : bon complément même à prix plus élevé qu'un
  an d'abonnement, car il n'y a pas de risque de désabonnement/remboursement
  récurrent à gérer.

## Structure du code

```
lib/
  l10n/         # app_fr.arb / app_en.arb (source), code généré non versionné
  models/       # Habit (logique de streak / gel / taux de complétion)
  services/     # StorageService, PurchaseService, NotificationService
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
  Play Store) ou un service comme RevenueCat.
- Pas de détection d'annulation/expiration d'abonnement en direct (pas de
  webhook côté store branché) : `isPremium` reste vrai tant qu'aucun
  nouvel événement d'achat n'est reçu par l'app.
- Pas de sauvegarde cloud : les habitudes vivent uniquement sur l'appareil
  (désinstaller l'app supprime les données). Une sauvegarde
  cloud/multi-appareil serait un bon argument Premium additionnel.
- Les rappels programmés (`flutter_local_notifications`) peuvent être
  perdus après un redémarrage de l'appareil (pas de receiver Android natif
  au boot). Ils sont automatiquement reprogrammés à chaque ouverture de
  l'app (`HabitsProvider._load()`), donc l'impact reste limité à "l'app
  n'a pas été rouverte depuis le redémarrage".
- Testé via `flutter analyze` et `flutter test` (scaffold Android/iOS
  généré par `flutter create`, non compilé en APK/IPA faute de SDK Android
  dans cet environnement de développement — build web fait à titre
  d'aperçu visuel uniquement).

## Régénérer l'icône de l'app

L'icône actuelle est le glyphe couleur 🔥 de la police Noto Color Emoji
(Google, licence SIL Open Font License) sur un fond dégradé violet — choix
volontairement littéral pour rester immédiatement reconnaissable comme
"flamme/série" à toutes les tailles, plutôt qu'une forme dessinée à la main
plus stylisée mais ambiguë en petit format.

Pour remplacer par un autre visuel : remplacer `assets/icon/icon.png`
(icône pleine, 1024×1024) et `assets/icon/icon_foreground.png` (calque
transparent pour l'icône adaptative Android, motif centré dans les 66% du
canevas pour éviter le rognage), puis :

```bash
dart run flutter_launcher_icons
```

## Idées pour la suite (différenciation vs. un simple rappel natif)

- Vue calendrier "heatmap" par habitude (façon GitHub contributions).
- Widget écran d'accueil.
- Défis/groupes entre amis (accountability sociale).
- Rappels intelligents (relance si toujours pas fait à une heure donnée,
  pas juste un rappel statique).
