# Publication sur le Play Store — Resi Pro

Application : `africa.resi.app`, libellé « Resi Pro », point d'entrée
`lib/main_prod.dart` (API `https://api.resi.africa`). Cible Android 16
(API 36), minimum Android 7 (API 24).

## Bloquants à lever avant la soumission

Ces points ne sont pas de la configuration : ils demandent une décision ou du
développement.

1. ~~**Suppression de compte.**~~ Levé : Profil → « Supprimer mon compte »
   dans Resi Pro et dans l'app client (`DELETE /auth/account`), page web
   `https://resi.africa/fr/suppression-compte` à déclarer dans « Sécurité des
   données » (champ « URL de suppression du compte »).
2. **Paiement de l'abonnement par Wave dans l'application.** Le forfait
   propriétaire débloque des fonctions de l'application : pour Google, c'est
   un bien numérique, qui doit passer par Google Play Billing (15 % sur les
   abonnements). Un lien de paiement Wave ouvert depuis l'application expose
   à un rejet ou à un retrait ultérieur. Les réservations de séjour, service
   physique, ne sont pas concernées. Options : Play Billing pour
   l'abonnement ; ou abonnement payé hors de l'application (site), sans
   bouton ni lien vers ce paiement dans l'application.
3. **Compte de test pour l'examen.** La connexion passe par un OTP WhatsApp
   ou e-mail que l'examinateur ne recevra pas : prévoir un compte
   propriétaire de démonstration dont la connexion ne demande pas d'OTP, et
   le renseigner dans « Accès à l'application ».
4. **Compte développeur personnel récent** (créé après novembre 2023) :
   test fermé obligatoire — 12 testeurs au moins, inscrits pendant 14 jours
   consécutifs — avant de pouvoir demander l'accès à la production.

## 1. Clé d'envoi (une seule fois)

```powershell
cd mobile/android
& "C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe" -genkeypair -v `
  -keystore upload-keystore.jks -storetype JKS -keyalg RSA -keysize 2048 `
  -validity 10000 -alias upload
Copy-Item key.properties.example key.properties   # puis renseigner les mots de passe
```

`upload-keystore.jks` et `key.properties` sont ignorés par git. **Les
sauvegarder hors de ce PC** (gestionnaire de mots de passe) : avec Play App
Signing, une clé d'envoi perdue se remplace, mais seulement par une demande au
support Google, qui prend plusieurs jours.

Sans `key.properties`, le build release est signé avec la clé debug et un
avertissement Gradle le signale ; le Play Console refuse ce bundle.

## 2. Version

Dans `pubspec.yaml`, `version: <nom>+<code>`. Le code (après le `+`) doit
augmenter à **chaque** envoi au Play Console, test interne compris.

## 3. Build

```powershell
cd mobile
flutter clean
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter build appbundle -t lib/main_prod.dart --release `
  --obfuscate --split-debug-info=build/symbols/<version>
```

Résultat : `build/app/outputs/bundle/release/app-release.aab`.

Garder `build/symbols/<version>` pour chaque version publiée : sans lui, une
trace de plantage obfusquée est illisible (`flutter symbolize`).

Valeurs modifiables au build par `--dart-define` (voir
`lib/core/config/app_config.dart`) : `GOOGLE_SERVER_CLIENT_ID`,
`GOOGLE_PLACES_API_KEY`, `TAWK_PROPERTY_ID`, `SUPPORT_PHONE`,
`SUPPORT_WHATSAPP`, `SUPPORT_EMAIL`, `SUPPORT_WEBSITE`, `SUPPORT_HOURS`.

## 4. Play Console

1. Créer l'application, accepter **Play App Signing** (choix par défaut).
2. Envoyer l'`.aab` en **Test interne** d'abord.
3. **Empreintes SHA-1** — Configuration → Intégrité de l'application →
   Signature de l'application : copier les SHA-1 de la **clé de signature
   de l'application** (celle de Google) et de la **clé d'importation**.
   Les ajouter :
   - dans Firebase → Paramètres du projet → application Android
     `africa.resi.app` ;
   - dans Google Cloud → Identifiants → client OAuth Android.

   Sans celle de Google, la connexion Google échoue (`ApiException: 10`)
   sur toute installation depuis le Play Store, alors qu'elle marche en
   debug. Re-télécharger ensuite `android/app/google-services.json`.

## 5. Fiche et formulaires

- **Règles de confidentialité** : URL publique obligatoire (pièces
  d'identité, position, téléphone, e-mail) —
  `https://resi.africa/fr/confidentialite`.
- **Sécurité des données** — déclarer au moins :
  - nom, e-mail, téléphone, pièce d'identité (numéro, nature, date de
    naissance, nationalité) — compte et réservations ;
  - position précise — adresse du bien ;
  - photos — photos d'annonces et de pièces d'identité ;
  - identifiants d'appareil — jeton de notification ;
  - données envoyées à des tiers : Cloudinary (photos), Wave (paiement),
    Google (Firebase, Places), DUGU (OTP WhatsApp) ;
  - chiffrement en transit : oui ; suppression sur demande : oui
    (dans l'application et par la page web).
- **Classification du contenu**, **public cible** (adultes), catégorie
  « Professionnel » ou « Maison ».
- **Permission de position précise** : justifier par le préremplissage de
  l'adresse au dépôt d'une annonce.
- Visuels : icône 512 × 512, bannière 1024 × 500, au moins deux captures
  téléphone.

## 6. Avant la production

- [ ] API déployée avec les routes de cette version (voir
      `api/docs/mise-en-production.md`).
- [ ] Restreindre la clé Google Places (codée par défaut dans
      `app_config.dart`, donc lisible dans l'APK) : Google Cloud →
      Identifiants → restriction d'API à « Places API », et quota journalier.
- [ ] Installation depuis le test interne sur un vrai téléphone : connexion
      Google, OTP, réservation hors réseau puis synchronisation, scan de
      pièce, notification, rapport PDF.
