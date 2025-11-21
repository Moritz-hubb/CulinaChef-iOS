# Politique de confidentialité

pour l'application iOS "CulinaChef (CulinaAI)"

**Date:** 04.11.2025  
**Version:** 1.0

---

## 1. Responsable

**Entreprise:** CulinaAI  
**Représentée par:** Moritz Serrin  
**Adresse:** Sonnenblumenweg 8, 21244 Buchholz, Allemagne  
**E-mail:** kontakt@culinaai.com  
**Protection des données:** datenschutz@culinaai.com

---

## 2. Généralités

La protection de vos données personnelles est une priorité pour nous. Nous traitons les données personnelles conformément au RGPD, à la loi fédérale allemande sur la protection des données (BDSG) et aux autres réglementations pertinentes.

**Principes de traitement des données:**

- **Minimisation des données:** Seules les données nécessaires sont collectées
- **Transparence:** Communication claire sur l'utilisation des données
- **Sécurité:** Cryptage TLS et stockage sécurisé
- **Pas de publicité:** Pas de suivi ni de profilage

---

## 3. Données collectées

### 3.1 Compte utilisateur

**Données requises lors de l'inscription:**

- Nom d'utilisateur (3–32 caractères)
- Adresse e-mail
- Mot de passe (min. 6 caractères, bcrypt)
- Optionnel: Sign in with Apple

**Objectif:** Création et authentification du compte  
**Base légale:** Art. 6 Abs. 1 lit. b RGPD (exécution du contrat)

### 3.2 Gestion des recettes

**Données stockées:**

- Titre de la recette, ingrédients, instructions
- Valeurs nutritionnelles, temps de cuisson, tags
- Favoris, planification des menus
- Évaluations (1–5 étoiles)

**Objectif:** Fonctionnalité principale de l'application – gestion des recettes  
**Durée de conservation:** Jusqu'à suppression par l'utilisateur

### 3.3 Préférences alimentaires

- Allergies (ex. noix, gluten)
- Types d'alimentation (végétarien, végan)
- Préférences / aversions gustatives
- Notes (texte libre)

**Objectif:** Suggestions de recettes personnalisées et filtrage

### 3.4 Intelligence artificielle (OpenAI)

Nous utilisons OpenAI GPT-4o-mini pour:

- Création automatique de recettes
- Réponses aux questions culinaires

**Données transmises:**

- Listes d'ingrédients
- Messages de chat
- Préférences alimentaires (contexte)
- **AUCUNE donnée personnelle**

**Drittanbieter:** OpenAI L.L.C.

- **Empfänger:** OpenAI L.L.C., USA
- **Rechtsgrundlage:** Art. 49 Abs. 1 lit. a RGPD (consentement)
- **Durée de conservation:** Max. 30 jours chez OpenAI

**Remarque importante:** Les contenus générés par IA sont automatisés. Nous déclinons toute responsabilité pour leur exactitude, intégralité ou adéquation sanitaire.

**Avis important concernant les recettes générées par IA:**

Les systèmes d'IA peuvent commettre des erreurs. Veuillez examiner attentivement toutes les recettes générées par IA avant de les préparer. Surtout si vous avez des allergies, des intolérances ou des exigences alimentaires spéciales, vous devez vérifier deux fois la liste des ingrédients et les instructions.

Nous déclinons toute responsabilité pour les conséquences sanitaires découlant de l'utilisation de recettes générées par IA. La responsabilité de vérifier les recettes et de décider si une recette convient à vos besoins individuels vous incombe uniquement.

### 3.5 Paiement (Apple)

**Abonnement:** 5,99 €/mois via Apple In-App Purchase

Données traitées par Apple:

- Apple ID
- Informations de paiement
- Historique des achats

**Remarque:** Nous ne recevons aucune donnée de paiement, uniquement la confirmation de transaction d'Apple. Pour plus d'informations, veuillez consulter la Politique de Confidentialité d'Apple.

### 3.6 Rapport d'erreurs et crash (Sentry)

Nous utilisons **Sentry** de Functional Software, Inc. pour améliorer la stabilité de l'app.

**Données transmises en cas de crash ou d'erreur:**

- Informations sur l'appareil (modèle, version iOS)
- Version de l'app et numéro de build
- Stack traces (journaux techniques d'erreurs)
- Horodatage de l'erreur
- Capture d'écran au moment de l'erreur (optionnelle)
- Actions utilisateur avant l'erreur (breadcrumbs)
- **AUCUNE donnée personnelle** (noms, e-mails, etc.)

**Drittanbieter:** Functional Software, Inc. (Sentry)

- **Empfänger:** Functional Software, Inc., USA
- **Rechtsgrundlage:** Art. 6 Abs. 1 lit. f RGPD (intérêt légitime)
- **Durée de conservation:** 30 jours chez Sentry
- **Transfert de données:** UE/USA, conforme au RGPD

**Objectif:** Détection et résolution d'erreurs techniques pour améliorer la stabilité de l'app.

Pour plus d'informations: [Politique de Confidentialité de Sentry](https://sentry.io/privacy/)

### 3.7 Stockage local

**UserDefaults (non sensible):**

- Langue de l'app, mode sombre
- Statut d'onboarding
- Suggestions de menus (cache)

**Keychain (chiffré):**

- Tokens d'accès et de rafraîchissement
- ID utilisateur, e-mail

**Suppression:** Automatiquement effectuée par iOS lors de la désinstallation de l'app

---

## 4. Transfert de données hors UE

Les prestataires suivants peuvent traiter des données en dehors de l'Union européenne:

| Prestataire | Objectif | Localisation | Base Légale |
|-------------|-----------|--------------|-------------|
| **Supabase Inc.** | Base de données et authentification | UE/USA | Art. 6 Abs. 1 lit. b RGPD |
| **OpenAI L.L.C.** | Génération de recettes avec IA | USA | Art. 49 Abs. 1 lit. a RGPD |
| **Apple Inc.** | Achats in-app et abonnements | USA | Décision d'adéquation de l'UE |
| **Functional Software, Inc. (Sentry)** | Suivi des erreurs et crash reporting | USA/UE | Art. 6 Abs. 1 lit. f RGPD |

**Toutes les transmissions de données sont chiffrées via HTTPS/TLS.**

---

## 5. Mesures techniques et organisationnelles

Pour protéger vos données, nous mettons en œuvre les mesures de sécurité suivantes:

- **Cryptage:** TLS/HTTPS pour toutes les transmissions de données
- **Protection des mots de passe:** Hachage bcrypt avec sel
- **Contrôle d'accès:** Row Level Security (RLS) dans la base de données
- **Sécurité des tokens:** Stockage sécurisé dans iOS Keychain
- **Journaux d'audit:** Enregistrement des activités pertinentes pour la sécurité
- **Minimisation des données:** Pas de suivi, de publicité ou de profilage
- **Stratégie de sauvegarde:** Sauvegardes régulières chiffrées (rétention de 30 jours)

---

## 6. Vos droits selon le RGPD

Vous disposez des droits suivants concernant vos données personnelles:

- **Accès (Art. 15):** Recevoir des informations sur vos données stockées
- **Rectification (Art. 16):** Corriger des données inexactes ou incomplètes
- **Effacement (Art. 17):** Supprimer votre compte et les données associées
- **Portabilité (Art. 20):** Recevoir vos données dans un format lisible par machine (JSON)
- **Opposition (Art. 21):** Vous opposer à un traitement spécifique de données
- **Plainte (Art. 77):** Déposer une plainte auprès d'une autorité de contrôle

**Pour exercer vos droits:**

Contactez-nous à **datenschutz@culinaai.com**.  
Nous traiterons votre demande sans retard injustifié.

---

## 7. Durée de conservation

| Type de Données | Période de Conservation | Méthode de Suppression |
|-----------------|-------------------------|------------------------|
| Compte utilisateur | Jusqu'à suppression | Manuel par l'utilisateur |
| Recettes et favoris | Jusqu'à suppression | Avec le compte |
| Préférences alimentaires | Jusqu'à suppression | Avec le compte |
| Messages de chat | Durée de session | Supprimés à la fermeture de l'app |
| Journaux API | 30 jours | Suppression des journaux techniques |
| Journaux d'audit | 3 ans | Obligation légale |

---

## 8. Protection des mineurs

**Exigence d'âge:** L'utilisation de l'application est autorisée pour les personnes de **16 ans ou plus**.

Les utilisateurs de moins de 16 ans doivent avoir le consentement des parents ou tuteurs conformément à l'Art. 8 RGPD.

---

## 9. Pas de publicité ni suivi

**Nous nous abstenons complètement d'utiliser:**

- Cookies ou technologies de suivi similaires
- Google Analytics ou outils d'analyse comparables
- Publicité, réseaux publicitaires ou profilage d'utilisateurs
- Plugins de réseaux sociaux ou trackers externes

**✅ Vos données personnelles ne seront jamais vendues ou utilisées à des fins publicitaires.**

---

## 10. Suppression du compte

Vous pouvez supprimer votre compte à tout moment en suivant ces étapes:

1. Ouvrez **Paramètres** dans l'app
2. Sélectionnez **"Supprimer le compte"**
3. Confirmez la suppression

**Les données supprimées incluent:**

- Compte utilisateur et données d'authentification
- Toutes les recettes, menus et favoris sauvegardés
- Préférences alimentaires et paramètres personnels
- Évaluations et notes

**Important:**

- Les abonnements Apple doivent être annulés séparément dans les paramètres de votre compte Apple ID
- Les journaux d'audit liés au processus de suppression sont conservés pendant trois ans (Art. 6 Abs. 1 lit. c RGPD – obligation légale)
- La suppression est permanente et irréversible

---

## 11. Modifications de cette politique de confidentialité

Nous nous réservons le droit de modifier cette Politique de Confidentialité en cas de changements légaux ou techniques.

La version la plus récente est toujours disponible dans l'app et sur **https://culinaai.com/datenschutz**.

Les utilisateurs seront informés de tout changement important dans l'app.

---

## 12. Contact

**Demandes de protection des données:** datenschutz@culinaai.com  
**Support technique:** support@culinaai.com  
**Demandes générales:** kontakt@culinaai.com

---

## 13. Droit applicable et juridiction

Cette Politique de Confidentialité et toutes les activités de traitement de données connexes sont régies exclusivement par le droit allemand.

**Lieu de juridiction:** Allemagne

**Cadre juridique applicable:**

- **RGPD** – Règlement Général sur la Protection des Données
- **BDSG** – Loi fédérale allemande sur la protection des données
- **TMG** – Loi sur les télécommunications
- **UWG** – Loi contre la concurrence déloyale
- **BGB** – Code civil allemand

---

**Date:** 04. Novembre 2025  
**Version:** 1.0
