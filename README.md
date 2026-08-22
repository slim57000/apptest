# Habitudes+

Application Flutter de suivi d'habitudes avec un abonnement Premium payant.
Pensée pour être rapide à développer : **aucun backend**, tout est stocké
localement sur l'appareil. **Sortie ciblée : Android en premier** (le
scaffold iOS généré par `flutter create` est présent mais pas la priorité
actuelle, et n'a pas pu être testé faute de Mac/Xcode).

## Fonctionnalités

- Créer des habitudes (nom, emoji, couleur, jours actifs dans la semaine),
  ou partir d'un **modèle prêt à l'emploi** (14 habitudes réparties en 4
  packs thématiques) pour éviter la page blanche du premier lancement —
  voir `lib/models/habit_template.dart` / `lib/screens/templates_screen.dart`.
- Cocher chaque jour ses habitudes, avec calcul automatique du streak
  (série de jours consécutifs).
- **Rappel quotidien** optionnel par habitude (notification locale à une
  heure choisie, uniquement les jours actifs) — voir
  `lib/services/notification_service.dart`.
- **Relance intelligente** : si l'habitude n'est toujours pas cochée 2h
  après le rappel, une deuxième notification (plus discrète) relance
  l'utilisateur. Annulée automatiquement dès que l'habitude est cochée
  (ou complétée automatiquement via le suivi des pas), pour ne jamais
  relancer sur un jour déjà fait — voir `NotificationService.scheduleFollowUp`.
- **Note de journal** optionnelle par jour (réflexion libre sur pourquoi
  une habitude a été tenue/manquée).
- **Jardin virtuel** sur l'accueil qui grandit avec la régularité globale
  (toutes habitudes confondues) et se fane si rien n'a été fait depuis
  hier — voir `lib/widgets/garden_card.dart`.
- **Carte de série partageable** (image générée, façon Stories) pour
  partager sa série sur les réseaux — voir `lib/screens/share_card_screen.dart`.
- Version gratuite : jusqu'à **3 habitudes actives**.
- Version **Premium** (abonnement mensuel/annuel ou achat à vie, via achat
  in-app natif Play Store / App Store) :
  - Habitudes illimitées.
  - Statistiques avancées : meilleure série, taux de complétion sur 30
    jours, graphique de complétion sur 7 jours, et une grille d'activité
    façon "GitHub contributions" sur les 12 dernières semaines
    (`lib/widgets/habit_heatmap.dart`).
  - **Récap hebdo cross-habitudes** : vue d'ensemble de la semaine plutôt
    que de naviguer habitude par habitude (`lib/screens/recap_screen.dart`).
  - **Gel de série** (streak freeze) : si un jour actif a été manqué hier,
    un utilisateur Premium peut le "geler" pour ne pas casser sa série
    (façon Duolingo). Limité à un gel tous les 7 jours par habitude pour
    rester une roue de secours, pas un contournement — voir
    `Habit.canFreezeYesterday` / `Habit.freezeYesterday()` dans
    `lib/models/habit.dart`.
  - **Suivi automatique des pas** (Health Connect / Apple Health) : coche
    automatiquement une habitude si l'objectif de pas du jour est atteint
    — voir la section dédiée plus bas (nécessite un vrai appareil pour
    être testée).
- Petite animation confettis quand une habitude atteint un palier de streak
  (7, 14, 21 jours...).
- **Français et anglais**, avec détection automatique de la langue de
  l'appareil (repli sur le français si ni l'un ni l'autre) et un
  **sélecteur manuel** dans Réglages pour forcer une langue
  indépendamment du système (`lib/providers/locale_provider.dart`).
- Icône d'application personnalisée (flamme sur fond violet, générée dans
  `assets/icon/`) appliquée à Android/iOS/web via `flutter_launcher_icons`
  — plus l'icône Flutter par défaut.
- **Mode sombre** automatique (suit le thème du système, `lib/theme.dart`).
- **Widget écran d'accueil Android interactif** : cocher/décocher une
  habitude directement depuis le widget, sans ouvrir l'app — voir la
  section dédiée plus bas.
- **Défis entre amis** : créer un défi, inviter par code à 6 caractères,
  cocher "j'ai réussi aujourd'hui" et voir le statut de chaque membre —
  fonctionnalité avec un vrai backend (Supabase), voir la section
  dédiée plus bas. Gratuit (pas de mur Premium) pour ne pas freiner
  l'effet réseau.
- **Sauvegarde cloud des habitudes** (Premium) : sauvegarder/restaurer
  toutes ses habitudes (et leur historique) sur le même projet Supabase
  que les défis, pour les récupérer après une réinstallation ou sur un
  nouvel appareil — voir `lib/services/backup_service.dart` et la section
  Supabase plus bas.
- **Publicité** (version gratuite uniquement) : une seule bannière
  discrète en bas de l'accueil, jamais affichée aux abonnés Premium, pas
  d'interstitiel ni de plein écran — voir la section dédiée plus bas.

## Stack technique

- Flutter, sans backend : persistance locale via `shared_preferences`
  (`lib/services/storage_service.dart`).
- `provider` pour l'état de l'application.
- `in_app_purchase` pour l'abonnement Premium — achats natifs Play Store /
  App Store, aucun serveur de paiement à héberger. Voir
  `lib/services/purchase_service.dart` et `lib/providers/premium_provider.dart`.
  Une restauration silencieuse des achats est tentée à chaque lancement
  (en plus du bouton manuel "Restaurer mes achats" du paywall), pour
  resynchroniser le statut Premium après réinstallation/changement
  d'appareil sans action de l'utilisateur.
- `health` pour le suivi automatique des pas (Health Connect / Apple
  Health) — voir `lib/services/health_service.dart`.
- `share_plus` + `path_provider` pour la carte de série partageable.
- `supabase_flutter` pour les deux seules fonctionnalités avec un backend
  (auth anonyme + Postgres + RLS), tout le reste de l'app restant
  local-first :
  - les défis entre amis — `lib/services/challenge_service.dart` ;
  - la sauvegarde cloud des habitudes (Premium) —
    `lib/services/backup_service.dart`.
  Les deux partagent le même projet Supabase et le même
  `supabase/schema.sql`.
- Localisation via le système standard Flutter (`flutter_localizations` +
  `flutter gen-l10n`) : fichiers source dans `lib/l10n/*.arb`, le code
  généré (`app_localizations*.dart`) n'est pas versionné (régénéré
  automatiquement grâce à `generate: true` dans `pubspec.yaml`).
- `flutter_local_notifications` + `timezone` pour les rappels quotidiens
  locaux (aucun serveur de push).
- Design : `google_fonts` (typographie), `flutter_animate`
  (micro-animations), `fl_chart` (graphique de complétion), `confetti`
  (célébration de streak).
- `google_mobile_ads` pour la bannière publicitaire (version gratuite
  uniquement) — voir `lib/widgets/banner_ad_widget.dart` et la section
  dédiée plus bas.

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

## Signer l'app pour publication (release keystore)

Par défaut, `flutter build apk/appbundle --release` signe avec les clés de
**debug** (pratique en développement, mais Play Console refuse ces
builds). Pour signer avec une vraie clé :

1. Générer une clé d'upload (une seule fois, à garder précieusement — sa
   perte complique les mises à jour futures de l'app) :
   ```bash
   keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   ```
   Génère-la **en dehors du dépôt** (ex. dans ton dossier utilisateur), et
   note le mot de passe choisi.
2. Copier `android/key.properties.example` en `android/key.properties`
   (déjà dans `.gitignore`, ne sera jamais commité) et renseigner :
   ```properties
   storePassword=...
   keyPassword=...
   keyAlias=upload
   storeFile=C:/chemin/absolu/vers/upload-keystore.jks
   ```
3. `flutter build appbundle --release` signe désormais automatiquement
   avec cette clé (voir `android/app/build.gradle.kts` : bascule sur les
   clés de debug si `key.properties` est absent, pour ne pas casser
   `flutter run --release` en local).

Au premier envoi sur Play Console, accepter **Play App Signing** (proposé
par défaut) : Google gère la clé de signature finale de l'app, et cette
clé d'upload sert uniquement à authentifier tes envois — recommandé, ça
protège contre la perte de la clé de signature elle-même.

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

## Protection du code / anti-piratage

Pour une app mobile, il n'existe pas de protection totale contre le
piratage : le code tourne sur un appareil que l'attaquant contrôle. Ce qui
est réellement possible, et déjà en place ou documenté ici :

1. **Compilation native (déjà acquis avec Flutter)** — contrairement à un
   `.apk` Java/Kotlin classique, le code Dart est compilé en code machine
   ARM/x64 (AOT), pas en bytecode facilement décompilable. C'est une
   protection de base que Flutter offre déjà, sans rien à faire.
2. **Obfuscation du code Dart** — build à faire pour chaque release :
   ```bash
   flutter build apk --release --obfuscate --split-debug-info=debug-info
   flutter build appbundle --release --obfuscate --split-debug-info=debug-info
   ```
   Renomme les noms de classes/méthodes en identifiants illisibles.
   Conserver le dossier `debug-info/` en lieu sûr **hors du dépôt public**
   (déjà dans `.gitignore`) : nécessaire pour décoder les stack traces de
   crash plus tard, mais permettrait aussi de désobfusquer le code s'il
   fuitait.
3. **Minification/obfuscation Android (R8/ProGuard)** — activée dans
   `android/app/build.gradle.kts` (`isMinifyEnabled`, `isShrinkResources`)
   avec des règles de conservation pour les plugins sensibles à la
   réflexion (`android/app/proguard-rules.pro`). Comme pour les autres
   modifications natives de cette session, **non testée avec un vrai build
   release** faute de SDK Android ici : à vérifier avant publication que
   l'app se lance toujours et que l'achat in-app / les rappels / le suivi
   santé fonctionnent bien une fois minifiés (un plugin mal couvert par
   les règles de conservation peut planter silencieusement en release
   alors qu'il marchait en debug).
4. **Le vrai point faible reste le statut Premium côté client** (voir
   limite ci-dessous) : l'obfuscation ralentit un attaquant qui
   voudrait patcher l'app pour se donner Premium gratuitement, mais ne
   l'empêche pas. La vraie protection serait une vérification serveur des
   reçus d'achat.
5. Non fait ici, à évaluer selon le besoin réel : détection root/jailbreak
   (`safe_device`, `flutter_jailbreak_detection`...) — délibérément pas
   ajoutée, car ça reste un signal faible (beaucoup d'utilisateurs
   légitimes root leur téléphone) et ça revient à ajouter une dépendance
   native de plus qui ne pourrait pas être vérifiée dans cet environnement
   sans SDK Android ; **Play Integrity API** côté Android pour détecter les
   APK modifiés/republiés — nécessiterait une vérification serveur (le
   projet Supabase déjà en place pourrait héberger une Edge Function pour
   ça, mais c'est un chantier à part).

## Limites connues (v1 volontairement simple)

- Le statut Premium est confirmé côté client uniquement (pas de
  vérification serveur des reçus d'achat) : suffisant pour lancer vite,
  mais falsifiable par un utilisateur qui modifierait l'app. Étape
  suivante recommandée : vérification serveur (Cloud Function + webhook
  Play Store) ou un service comme RevenueCat.
- Pas de détection d'annulation/expiration d'abonnement en direct (pas de
  webhook côté store branché) : `isPremium` reste vrai tant qu'aucun
  nouvel événement d'achat n'est reçu par l'app.
- Les rappels programmés (`flutter_local_notifications`) peuvent être
  perdus après un redémarrage de l'appareil (pas de receiver Android natif
  au boot). Ils sont automatiquement reprogrammés à chaque ouverture de
  l'app (`HabitsProvider._load()`), donc l'impact reste limité à "l'app
  n'a pas été rouverte depuis le redémarrage".
- Testé via `flutter analyze` et `flutter test` (scaffold Android/iOS
  généré par `flutter create`, non compilé en APK/IPA faute de SDK Android
  dans cet environnement de développement — build web fait à titre
  d'aperçu visuel uniquement).
- **Suivi automatique des pas (Health Connect / Apple Health) : à tester
  en priorité sur un vrai appareil avant de shipper.** C'est la seule
  fonctionnalité qui touche à des permissions/capacités natives que cet
  environnement ne peut pas exécuter ni vérifier :
  - **Android** : nécessite l'app **Health Connect** installée sur
    l'appareil (préinstallée sur Android 14+, sinon à télécharger sur le
    Play Store). Les permissions Health Connect
    (`android.permission.health.READ_STEPS`) et le queries/activity-alias
    requis sont déjà dans `AndroidManifest.xml`.
  - **iOS** : `NSHealthShareUsageDescription` est dans `Info.plist`, mais
    la capacité **HealthKit** doit encore être activée manuellement dans
    Xcode (onglet Signing & Capabilities → + Capability → HealthKit) —
    étape qui ne peut pas être faite en dehors de Xcode/un Mac.
  - Objectif fixe de 5000 pas/jour pour la v1 (`stepsGoalForAutoComplete`
    dans `lib/services/health_service.dart`), non configurable par
    l'utilisateur.
  - Le plugin `health` requiert **Android 8.0 (API 26) minimum**
    (`minSdk` dans `android/app/build.gradle.kts`) : l'app n'est plus
    installable sur des appareils plus anciens. Couvre la quasi-totalité
    du parc actif en 2026, mais à savoir pour la fiche Play Store.

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

## Widget écran d'accueil (Android, interactif — à tester en priorité sur appareil)

Affiche jusqu'à 4 habitudes du jour + le compteur "faites/prévues". Taper
sur une ligne **coche/décoche l'habitude directement depuis le widget**,
sans ouvrir l'app ; taper ailleurs (en-tête) ouvre l'app. Implémenté avec
uniquement des APIs Android standard (`SharedPreferences` +
`AppWidgetManager` + `RemoteViews.setOnClickPendingIntent` + un
`MethodChannel` maison) plutôt qu'un package tiers, pour rester vérifiable
sans dépendre de détails internes non documentés.

- `lib/services/widget_service.dart` : sérialise les habitudes du jour
  (avec leur `id`) et les envoie côté natif à chaque changement
  (`HabitsProvider._persist()`).
- `android/app/src/main/kotlin/.../MainActivity.kt` : reçoit les données via
  le `MethodChannel` et les écrit dans les `SharedPreferences` du widget.
- `android/app/src/main/kotlin/.../HabitWidgetProvider.kt` : affiche les
  données (`RemoteViews`) et gère le tap sur une ligne, qui envoie un
  broadcast `TOGGLE_HABIT` à lui-même.

**Comment la coche fonctionne sans ouvrir l'app** : `HabitWidgetProvider`
écrit *directement* dans le fichier `SharedPreferences` utilisé par le
plugin Flutter `shared_preferences` (nom de fichier `FlutterSharedPreferences`
et préfixe de clé `flutter.` — comportement documenté et stable de ce
plugin officiel, pas un détail interne non documenté comme aurait pu
l'être un package tiers), en ne modifiant que le champ `completedDates` de
l'habitude ciblée dans le même JSON que produit `Habit.toJson()`. Toute
exception de parsing abandonne sans rien écrire, pour ne jamais risquer de
corrompre les données. Comme l'app peut avoir un état en mémoire différent
de ce qui vient d'être écrit sur disque (si elle était déjà ouverte),
`HabitsProvider.reload()` est appelé au retour au premier plan
(`app.dart`) pour resynchroniser avant tout nouvel enregistrement.

**C'est la fonctionnalité native la plus délicate de l'app à ce stade
(écriture directe dans un fichier partagé avec le moteur Flutter) : à
vérifier en priorité sur un appareil réel avant de shipper** — ajouter le
widget à l'écran d'accueil, taper sur une ligne pour cocher, revenir dans
l'app et confirmer que l'état correspond (streak, statistiques...), puis
refaire le test en ayant l'app ouverte en arrière-plan au moment du tap.
Pas d'équivalent iOS (nécessiterait une extension WidgetKit créée depuis
Xcode, impossible à scaffolder par édition de fichiers seule).

## Configurer les défis entre amis et la sauvegarde cloud (Supabase)

Le code est prêt mais **désactivé tant qu'il n'a pas de projet Supabase** :
sans configuration, l'écran de défis et la section sauvegarde cloud des
réglages affichent juste un message "non configuré" plutôt que de planter
l'app. Les deux fonctionnalités partagent la même configuration Supabase
ci-dessous.

1. Créer un compte et un projet sur [supabase.com](https://supabase.com)
   (gratuit).
2. Dans **Authentication → Providers**, activer **Anonymous Sign-Ins**
   (l'app n'utilise pas d'email/mot de passe, juste un pseudo).
3. Dans **SQL Editor**, coller et exécuter le contenu de
   `supabase/schema.sql` (tables + policies RLS), puis celui de
   `supabase/rls-patch.sql` (correctifs de sécurité : codes d'invitation
   non énumérables, adhésion par fonction serveur, quitter un défi,
   check-ins répétables).
4. Récupérer l'**URL du projet** et la **clé publique anon/publishable**
   (Settings → API), puis lancer l'app avec :
   ```bash
   flutter run --dart-define=SUPABASE_URL=https://xxxx.supabase.co \
               --dart-define=SUPABASE_ANON_KEY=eyJ...
   ```
   (voir `lib/config/supabase_config.dart` — ces valeurs peuvent aussi y
   être codées en dur si vous préférez, la clé anon est conçue pour être
   publique tant que les policies RLS sont correctes).
5. Pour un build de production, passer les mêmes `--dart-define` à
   `flutter build apk` / `flutter build ipa`, ou les injecter via votre
   pipeline CI.

**Non testé en direct** (pas d'accès à un projet Supabase depuis cet
environnement) : à vérifier avec un vrai projet avant de shipper — en
particulier les policies RLS de `supabase/schema.sql`, qui n'ont pas pu
être exécutées contre une vraie base pour confirmer qu'elles autorisent
exactement ce qu'il faut (rejoindre un défi par code, voir les autres
membres, sauvegarder/restaurer uniquement sa propre sauvegarde dans
`habit_backups`, etc.) sans rien laisser d'ouvert en trop.

## Configurer les publicités (AdMob)

Une seule bannière discrète en bas de l'accueil, uniquement pour la
version gratuite (jamais aux abonnés Premium — voir la condition dans
`lib/screens/home_screen.dart`). Pas d'interstitiel, pas de plein écran.

**Par défaut, l'app utilise les ID de test officiels Google**
(`lib/config/ads_config.dart`, `AndroidManifest.xml`, `Info.plist`) : sûrs
à committer, ils affichent de vraies publicités... de démonstration.
**Garder ces ID de test tant que l'app n'est pas prête à publier** —
utiliser un vrai compte AdMob pendant le développement/les tests expose à
une suspension pour "trafic invalide" (clics répétés sur ses propres
pubs).

Avant publication :

1. Créer un compte sur [admob.google.com](https://admob.google.com),
   ajouter l'app (Android, package `com.slim57000.habitudeplus`), créer un
   bloc **bannière**.
2. Récupérer l'**App ID** (format `ca-app-pub-XXXX~YYYY`) et remplacer la
   valeur de test dans `android/app/src/main/AndroidManifest.xml`
   (`com.google.android.gms.ads.APPLICATION_ID`) et, pour iOS,
   `ios/Runner/Info.plist` (`GADApplicationIdentifier`).
3. Récupérer l'**ID d'unité publicitaire bannière** (format
   `ca-app-pub-XXXX/YYYY`, différent de l'App ID) et le passer au build :
   ```bash
   flutter build appbundle --release --dart-define=ADMOB_BANNER_UNIT_ID=ca-app-pub-...
   ```
4. Sur Play Console, section **"Ads"** (App content) : répondre **"Oui"**
   (l'app contient des publicités), et mettre à jour la section **"Data
   safety"** pour déclarer la collecte d'un identifiant publicitaire par
   AdMob (voir `docs/privacy-policy.html`, déjà à jour sur ce point).

**Non testé en direct** (pas de compte AdMob réel ni de SDK Android dans
cet environnement) : à vérifier sur un appareil réel avant de shipper —
en particulier que la bannière se charge, ne s'affiche jamais aux
utilisateurs Premium, et ne casse rien si le chargement échoue (pas de
connexion, ID invalide...).

## Politique de confidentialité (obligatoire pour publier)

`docs/privacy-policy.html` contient une politique de confidentialité
bilingue FR/EN (stockage local, Health Connect, achats intégrés, défis et
sauvegarde cloud via Supabase, contact). Google Play **exige une URL
publique** vers cette page dès que l'app demande des permissions de santé
ou gère un compte — donc avant toute publication.

Pour l'héberger gratuitement via GitHub Pages (à faire une seule fois) :

1. Sur GitHub : Settings → Pages → Source : "Deploy from a branch" →
   branche `main`, dossier `/docs` → Save.
2. Après quelques minutes, la page est disponible à
   `https://slim57000.github.io/apptest/privacy-policy.html`.
3. Cette URL est déjà utilisée dans l'app (`lib/screens/settings_screen.dart`,
   `_privacyPolicyUrl`) et à renseigner telle quelle dans la fiche Play
   Console ("App content" → "Privacy policy").

**Limite connue** : les défis et la sauvegarde cloud créent un compte
anonyme Supabase, mais l'app n'offre pas encore de suppression
en libre-service de ces données (uniquement sur demande par e-mail, comme
indiqué dans la politique). Les règles Google Play sur la suppression de
compte ("Account deletion") peuvent exiger un vrai mécanisme en
libre-service (dans l'app ou via un lien web) selon comment ces
fonctionnalités sont classées à la revue — à vérifier avant publication ;
je peux ajouter un bouton "Supprimer mes données cloud" si besoin.

## Idées pour la suite (différenciation vs. un simple rappel natif)

Toutes les pistes identifiées à ce stade ont été implémentées (relance
intelligente, widget interactif, défis, sauvegarde cloud...). Prochaine
étape naturelle : les tester en conditions réelles (voir les sections
"non testé en direct" ci-dessus) avant d'envisager de nouvelles
fonctionnalités.
