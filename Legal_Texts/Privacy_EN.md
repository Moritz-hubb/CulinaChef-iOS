# Privacy Policy

for the iOS App "CulinaAI"

**Effective Date:** November 4, 2025  
**Version:** 1.0

---

## 1. Data Controller

**Company:** CulinaAI  
**Represented by:** Moritz Serrin  
**Address:** Sonnenblumenweg 8, 21244 Buchholz, Germany  
**E-mail:** kontakt@culinaai.com  
**Data Protection Contact:** datenschutz@culinaai.com

---

## 2. General Information

Protecting your personal data is important to us. We process personal data exclusively in accordance with the GDPR, the German Federal Data Protection Act (BDSG), and other applicable legal provisions.

**Principles of data processing:**

- **Data minimization:** Only the data necessary for operation are collected.
- **Transparency:** We clearly communicate how your data are used.
- **Security:** TLS encryption and secure data storage.
- **No ads inside the app:** No banners and no ad-network trackers. Apple Search Ads can measure which App Store campaign led to an install. An advertising identifier (IDFA) is not read.

---

## 3. Data Collected

### 3.1 User Account

**Required during registration:**

- Username (3–32 characters)
- E-mail address
- Password, hashed by the sign-in service, not stored in plain text
- Optional: Sign in with Apple

**Purpose:** Account creation and authentication  
**Legal basis:** Art. 6 (1)(b) GDPR – Performance of a contract

### 3.2 Recipe Management

**Stored data:**

- Recipe title, ingredients, instructions
- Nutritional values, cooking time, tags
- Favorites, menu planning
- Ratings (1–5 stars)

**Purpose:** Core functionality – recipe management  
**Storage:** Until deleted by the user

### 3.3 Dietary Preferences

- Allergies (e.g., nuts, gluten)
- Diet types (vegan, vegetarian)
- Taste preferences / dislikes
- Notes (free text)

**Purpose:** Personalized recipe suggestions and filtering

### 3.4 Artificial Intelligence (OpenAI)

We use **OpenAI GPT-4o-mini** for:

- Automated recipe creation
- Answering cooking-related questions

**Data transmitted:**

- Ingredient lists
- Chat messages
- Dietary preferences (context)
- **No personal data are transmitted.**

**Third-party provider:** OpenAI L.L.C.

- **Recipient:** OpenAI L.L.C., USA
- **Legal basis:** Art. 49 (1)(a) GDPR – User consent
- **Storage period:** Up to 30 days at OpenAI

**Important:** AI-generated content is created automatically. The provider assumes no liability for its accuracy, completeness, or health suitability.

**Important Notice Regarding AI-Generated Recipes:**

AI systems can make errors. Please carefully review all AI-generated recipes before preparing them. Especially if you have allergies, intolerances, or special dietary requirements, you should double-check the ingredient list and instructions.

We assume no liability for health consequences arising from the use of AI-generated recipes. The responsibility for reviewing recipes and deciding whether a recipe is suitable for your individual needs lies solely with you.

### 3.5 Payment Processing (Apple)

**Subscription:** € 5.99 per month via Apple In-App Purchase

Processed by Apple:

- Apple ID
- Payment information
- Purchase history

**Note:** We do not receive or store payment data — only transaction confirmations from Apple. For details, please refer to Apple's Privacy Policy.

### 3.6 Error Tracking and Crash Reporting (Sentry)

We use **Sentry** by Functional Software, Inc. to improve app stability.

**Data transmitted during crashes or errors in the released app:**

- Device model and iOS version
- App version and build number
- Technical stack trace
- Time of the error
- Recent actions before the error, including requested addresses without query parameters
- No screenshots and no view hierarchy
- Name and email are not stored as the Sentry user. Device model and text inside an error message can still be personal data.

**Third-party provider:** Functional Software, Inc. (Sentry)

- **Recipient:** Functional Software, Inc., USA
- **Legal basis:** Art. 6 (1)(f) GDPR (legitimate interest in a stable app)
- **Storage period:** 30 days at Sentry
- **Data transfer:** to Functional Software, Inc. in the USA. A data processing agreement is in place. The transfer uses the EU-US Data Privacy Framework and, where that does not apply, the Standard Contractual Clauses in that agreement.

**Purpose:** Detection and resolution of technical errors to improve app stability.

For more information, see: [Sentry Privacy Policy](https://sentry.io/privacy/)

### 3.7 Local Storage

**UserDefaults (non-sensitive):**

- App language
- Onboarding status
- Menu suggestions (cache)

**Keychain (encrypted):**

- Access and refresh tokens
- User ID, e-mail

**Deletion:** Automatically performed by iOS when the app is uninstalled.

---

## 4. Data Transfers to Third Countries

The following service providers may process data outside the European Union:

| Provider | Purpose | Location | Legal Basis |
|----------|---------|----------|-------------|
| **Supabase Pte. Ltd.** | Database and authentication | Ireland (EU) | Art. 6 (1)(b) GDPR |
| **OpenAI Ireland Ltd.** | AI-based recipe generation | USA | Art. 49 (1)(a) GDPR |
| **Apple Inc.** | In-app purchases and subscriptions | USA | Art. 6 (1)(b) GDPR |
| **Functional Software, Inc. (Sentry)** | Crash reports without screenshots | USA | Art. 6 (1)(f) GDPR |
| **RevenueCat, Inc.** | Subscription status and purchase restoration | USA | Art. 6 (1)(b) GDPR |
| **Nest22, Inc. (Superwall)** | Display of the purchase page | USA | Art. 6 (1)(b) GDPR |
| **Railway Corporation** | Operation of the API | USA | Art. 6 (1)(b) GDPR |
| **Vercel Inc.** | Operation of this website | USA | Art. 6 (1)(f) GDPR |

The database for the account and recipes is hosted by Supabase in Ireland (EU). The contracting party is Supabase Pte. Ltd., based in Singapore. A data processing agreement is in place with Supabase Pte. Ltd., OpenAI Ireland Ltd., RevenueCat, Inc., Nest22, Inc. (Superwall), Railway Corporation, Vercel Inc., and Functional Software, Inc. Allergy and intolerance details sent to OpenAI are covered by explicit consent under Art. 9 (2)(a) GDPR. Where these recipients process data outside the EU, the agreements include the European Commission Standard Contractual Clauses. For Functional Software, Inc. the transfer uses the EU-US Data Privacy Framework and, where that does not apply, the Standard Contractual Clauses. OpenAI is additionally covered by consent under Art. 49 (1)(a) GDPR. Apple processes purchases as its own controller.

**Security:** All data transmissions are encrypted via HTTPS/TLS.

---

## 5. Technical and Organizational Measures

We implement the following security measures to protect your data:

- **Encryption:** TLS/HTTPS for all data transfers
- **Password protection:** The password is stored hashed, not in plain text
- **Access control:** Row Level Security (RLS) within the database
- **Token safety:** Secure storage in iOS Keychain
- **Deletion record:** When an account is deleted, only a hash of the user id is stored, for three years
- **Data minimization:** No ad-network trackers and no profiling inside the app. Apple Search Ads can attribute an App Store install to a campaign.
- **Backup strategy:** Daily database backups, kept for 7 days. Backups are for restoring the service after an outage. They are not used to bring back a deleted account.

---

## 6. Your Rights under the GDPR

You have the following rights regarding your personal data:

- **Access (Art. 15):** Receive information about your stored data.
- **Rectification (Art. 16):** Correct inaccurate or incomplete data.
- **Erasure (Art. 17):** Delete your account and associated data.
- **Data portability (Art. 20):** In the app, under Settings, you can download a JSON file. It contains your email, name, username, allergies, diet, taste preferences, dislikes, notes, and recipes.
- **Objection (Art. 21):** Object to specific data processing.
- **Complaint (Art. 77):** Lodge a complaint with a supervisory authority.

**To exercise your rights:**

Contact us at **datenschutz@culinaai.com**.  
We will process your request without undue delay.

---

## 7. Storage Periods

| Data Type | Retention Period | Deletion Method |
|-----------|------------------|-----------------|
| Account, profile, and email | Until you delete the account in the app | Immediately, with the account |
| Recipes, menus, favorites, ratings, photos | Until you delete the account in the app | Immediately, with the account |
| Allergies, diet, taste, dislikes, notes | Until you delete the account in the app | Immediately, with the account |
| Chat messages | Only in memory for the current session | When you close the app. There is no chat copy on the server. |
| Crash reports (Sentry) | 30 days | Released app: no screenshot. Email and user id are not stored as the Sentry user. Device model and short error text can be included. |
| Database backups | 7 days | The backup expires. A deleted account is not restored from it. |
| Deletion record | 3 years | Only a hash of the user id, the time, and that you requested deletion. No name, email, or recipes. Then deleted automatically. |

---

## 8. Protection of Minors

**Age requirement:** Use of the app is permitted for individuals aged **16 years or older**.

Users under 16 must have parental or guardian consent in accordance with Art. 8 GDPR.

---

## 9. No Advertising or Tracking

**We strictly refrain from using:**

- Cookies or similar tracking technologies
- Google Analytics or comparable analytics tools
- Advertising, ad networks, or user profiling
- Social media plugins or external trackers

**✅ Your personal data will never be sold or used for advertising purposes.**

---

## 10. Account Deletion

You can delete your account at any time by following these steps:

1. Open **Settings** in the app.
2. Select **"Delete Account."**
3. Confirm the deletion.

**Deleted data include:**

- User account and authentication data
- All saved recipes, menus, and favorites
- Dietary preferences and personal settings
- Ratings, favorites, and reports
- Recipe photos and locally stored data (e.g. shopping list)

**Important:**

- Apple subscriptions must be cancelled separately in your Apple ID account settings.
- A deletion record remains: only a hash of the user id, the time, and that you requested deletion. No name, email, or recipes. It is kept for 3 years and then deleted.
- A database backup may still contain the account for up to 7 days. Backups are not used to bring a deleted account back.
- Deletion is permanent and irreversible.

---

## 11. Changes to This Privacy Policy

We reserve the right to amend this Privacy Policy in case of legal or technical changes.

The latest version is always available in the app and at **https://culinaai.com/datenschutz**.

Users will be informed of any significant changes within the app.

---

## 12. Contact

**Data protection inquiries:** datenschutz@culinaai.com  
**Technical support:** support@culinaai.com  
**General inquiries:** kontakt@culinaai.com

---

## 13. Applicable Law and Jurisdiction

This Privacy Policy and all related data processing activities are governed exclusively by German law.

**Place of jurisdiction:** Germany.

**Applicable legal framework:**

- **GDPR** – General Data Protection Regulation
- **BDSG** – Federal Data Protection Act
- **TMG** – Telemedia Act
- **UWG** – Act Against Unfair Competition
- **BGB** – German Civil Code

---

**Effective Date:** November 4, 2025  
**Version:** 1.0
