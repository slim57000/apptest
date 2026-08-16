# Règles ProGuard/R8 additionnelles pour le build release. Le plugin
# Gradle Flutter ajoute déjà ses propres règles pour le moteur Flutter ;
# celles-ci couvrent les plugins natifs utilisés par l'app qui reposent
# sur de la réflexion ou de la (dé)sérialisation.
#
# Non testé avec un vrai build release faute de SDK Android dans
# l'environnement de développement (voir le README) : à vérifier avant
# publication (l'app doit se lancer et l'achat in-app / les rappels /
# le suivi santé doivent continuer à fonctionner en release).

# Play Billing (in_app_purchase)
-keep class com.android.billingclient.** { *; }
-dontwarn com.android.billingclient.**

# Health Connect (suivi automatique des pas)
-keep class androidx.health.connect.** { *; }
-dontwarn androidx.health.connect.**

# flutter_local_notifications sérialise les rappels programmés
-keep class com.dexterous.** { *; }
-keep class * implements java.io.Serializable { *; }

# Supabase (auth, base de données, websocket temps réel)
-keep class io.github.jan.supabase.** { *; }
-dontwarn io.github.jan.supabase.**

# Dépendances transitives optionnelles de certains clients réseau —
# avertissements sans impact si les classes ne sont pas présentes.
-dontwarn org.bouncycastle.**
-dontwarn org.conscrypt.**
-dontwarn org.openjsse.**
