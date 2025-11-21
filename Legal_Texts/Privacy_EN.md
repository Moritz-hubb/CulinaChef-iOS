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
- **No advertising:** No tracking or profiling.

---

## 3. Data Collected

### 3.1 User Account

**Required during registration:**

- Username (3–32 characters)
- E-mail address
- Password (minimum 6 characters, bcrypt encryption)
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

**Data transmitted during crashes or errors:**

- Device information (model, iOS version)
- App version and build number
- Stack traces (technical error logs)
- Error timestamps
- Screenshots at the time of the error (optional)
- User actions before the error (breadcrumbs)
- **No personal data** (names, e-mails, etc.)

**Third-party provider:** Functional Software, Inc. (Sentry)

- **Recipient:** Functional Software, Inc., USA
- **Legal basis:** Art. 6 (1)(f) GDPR – Legitimate interest
- **Storage period:** 30 days at Sentry
- **Data transfer:** EU/USA, GDPR-compliant

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
| **Supabase Inc.** | Database and authentication | EU / USA | Art. 6 (1)(b) GDPR |
| **OpenAI L.L.C.** | AI-based recipe generation | USA | Art. 49 (1)(a) GDPR |
| **Apple Inc.** | In-app purchases and subscriptions | USA | EU Adequacy Decision |
| **Functional Software, Inc. (Sentry)** | Error tracking and crash reporting | USA / EU | Art. 6 (1)(f) GDPR |

**Security:** All data transmissions are encrypted via HTTPS/TLS.

---

## 5. Technical and Organizational Measures

We implement the following security measures to protect your data:

- **Encryption:** TLS/HTTPS for all data transfers
- **Password protection:** bcrypt hashing with salt
- **Access control:** Row Level Security (RLS) within the database
- **Token safety:** Secure storage in iOS Keychain
- **Audit logs:** Recording of security-relevant activities
- **Data minimization:** No tracking, advertising, or profiling
- **Backup strategy:** Regular encrypted backups (30-day retention)

---

## 6. Your Rights under the GDPR

You have the following rights regarding your personal data:

- **Access (Art. 15):** Receive information about your stored data.
- **Rectification (Art. 16):** Correct inaccurate or incomplete data.
- **Erasure (Art. 17):** Delete your account and associated data.
- **Data portability (Art. 20):** Receive your data in a machine-readable format (JSON).
- **Objection (Art. 21):** Object to specific data processing.
- **Complaint (Art. 77):** Lodge a complaint with a supervisory authority.

**To exercise your rights:**

Contact us at **datenschutz@culinaai.com**.  
We will process your request without undue delay.

---

## 7. Storage Periods

| Data Type | Retention Period | Deletion Method |
|-----------|------------------|-----------------|
| User account | Until deleted | Manual by user |
| Recipes & favorites | Until deleted | With account |
| Dietary preferences | Until deleted | With account |
| Chat messages | Session duration | Deleted when app closes |
| API logs | 30 days | Technical log deletion |
| Audit logs | 3 years | Legal requirement |

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
- Ratings and notes

**Important:**

- Apple subscriptions must be cancelled separately in your Apple ID account settings.
- Audit logs related to the deletion process are retained for three years (Art. 6 (1)(c) GDPR – legal obligation).
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
