# Datenschutzerklärung
für die iOS-App "CulinaAI"

**Stand:** 04.11.2025  
**Version:** 1.0

---

## 1. Verantwortlicher

**Unternehmen:** CulinaAI  
**Vertreten durch:** Moritz Serrin  
**Adresse:** Sonnenblumenweg 8, 21244 Buchholz, Deutschland  
**E-Mail:** kontakt@culinaai.com  
**Datenschutz:** datenschutz@culinaai.com

---

## 2. Allgemeines

Der Schutz Ihrer personenbezogenen Daten ist uns ein wichtiges Anliegen. Wir verarbeiten personenbezogene Daten ausschließlich im Einklang mit der DSGVO, dem BDSG sowie weiteren einschlägigen Rechtsvorschriften.

**Grundsätze der Datenverarbeitung:**

- **Datenminimierung:** Nur notwendige Daten werden erfasst
- **Transparenz:** Klare Kommunikation über Datennutzung
- **Sicherheit:** TLS-Verschlüsselung und sichere Speicherung
- **Keine Werbung:** Kein Tracking oder Profilbildung

---

## 3. Erhobene Daten

### 3.1 Benutzerkonto

**Erforderlich bei Registrierung:**

- Benutzername (3–32 Zeichen)
- E-Mail-Adresse
- Passwort (mind. 6 Zeichen, bcrypt)
- Optional: Sign in with Apple

**Zweck:** Kontoerstellung und Authentifizierung  
**Rechtsgrundlage:** Art. 6 Abs. 1 lit. b DSGVO (Vertragserfüllung)

### 3.2 Rezeptverwaltung

**Gespeicherte Daten:**

- Rezepttitel, Zutaten, Anleitung
- Nährwerte, Kochzeit, Tags
- Favoriten, Menüplanung
- Bewertungen (1–5 Sterne)

**Zweck:** Hauptfunktion der App – Rezeptverwaltung  
**Speicherung:** Bis zur Löschung durch den Nutzer

### 3.3 Ernährungspräferenzen

- Allergien (z.B. Nüsse, Gluten)
- Ernährungsweisen (vegan, vegetarisch)
- Geschmacksvorlieben / Abneigungen
- Notizen (Freitext)

**Zweck:** Personalisierte Rezeptvorschläge und Filterung

### 3.4 Künstliche Intelligenz (OpenAI)

Wir nutzen OpenAI GPT-4o-mini für:

- Automatische Rezepterstellung
- Beantwortung von Kochfragen

**Übermittelte Daten:**

- Zutatenlisten
- Chat-Nachrichten
- Ernährungspräferenzen (Kontext)
- KEINE personenbezogenen Daten

**Drittanbieter: OpenAI L.L.C.**

- **Empfänger:** OpenAI L.L.C., USA
- **Rechtsgrundlage:** Art. 49 Abs. 1 lit. a DSGVO (Einwilligung)
- **Speicherdauer:** Maximal 30 Tage bei OpenAI

**Wichtig:** KI-generierte Inhalte sind automatisiert erstellt. Es besteht keine Haftung für Richtigkeit, Vollständigkeit oder gesundheitliche Verträglichkeit.

**Wichtiger Hinweis zu KI-generierten Rezepten:**

KI-Systeme können Fehler machen. Bitte überprüfen Sie alle KI-generierten Rezepte sorgfältig, bevor Sie sie zubereiten. Insbesondere bei Allergien, Unverträglichkeiten oder speziellen Ernährungsanforderungen sollten Sie die Zutatenliste und Anweisungen doppelt prüfen.

Wir übernehmen keine Haftung für gesundheitliche Folgen, die durch die Verwendung von KI-generierten Rezepten entstehen. Die Verantwortung für die Überprüfung der Rezepte und die Entscheidung, ob ein Rezept für Ihre individuellen Bedürfnisse geeignet ist, liegt allein bei Ihnen.

### 3.5 Zahlungsabwicklung (Apple)

**Abonnement: 5,99 €/Monat via Apple In-App-Purchase**

Verarbeitet durch Apple:

- Apple-ID
- Zahlungsinformationen
- Kaufhistorie

**Hinweis:** Wir erhalten keine Zahlungsdaten, ausschließlich Transaktionsbestätigungen von Apple. Weitere Informationen finden Sie in der Apple Datenschutzrichtlinie.

### 3.6 Fehlererfassung und Crash Reporting (Sentry)

Zur Verbesserung der App-Stabilität nutzen wir **Sentry** von Functional Software, Inc.

**Übermittelte Daten bei Crashes oder Fehlern:**

- Geräteinformationen (Modell, iOS-Version)
- App-Version und Build-Nummer
- Stack Traces (technische Fehlerprotokolle)
- Zeitstempel des Fehlers
- Screenshots zum Zeitpunkt des Fehlers (optional)
- User-Aktionen vor dem Fehler (Breadcrumbs)
- KEINE personenbezogenen Daten (Namen, E-Mails, etc.)

**Drittanbieter: Functional Software, Inc. (Sentry)**

- **Empfänger:** Functional Software, Inc., USA
- **Rechtsgrundlage:** Art. 6 Abs. 1 lit. f DSGVO (berechtigtes Interesse)
- **Speicherdauer:** 30 Tage bei Sentry
- **Datenübertragung:** EU/USA, DSGVO-konform

**Zweck:** Erkennung und Behebung von technischen Fehlern zur Verbesserung der App-Stabilität.

Weitere Informationen: [Sentry Privacy Policy](https://sentry.io/privacy/)

### 3.7 Lokale Speicherung

**UserDefaults (nicht sensibel):**

- App-Sprache
- Onboarding-Status
- Menüvorschläge (Cache)

**Keychain (verschlüsselt):**

- Access & Refresh Token
- User-ID, E-Mail

**Löschung:** Automatisch bei App-Deinstallation durch iOS

---

## 4. Datenübermittlung in Drittländer

Folgende Drittanbieter verarbeiten Daten außerhalb der EU:

| Anbieter | Zweck | Standort | Rechtsgrundlage |
|----------|-------|----------|-----------------|
| **Supabase Inc.** | Datenbank und Authentifizierung | EU/USA | Art. 6 Abs. 1 lit. b DSGVO |
| **OpenAI L.L.C.** | KI-gestützte Rezeptgenerierung | USA | Art. 49 Abs. 1 lit. a DSGVO |
| **Apple Inc.** | In-App-Käufe und Abonnements | USA | Angemessenheitsbeschluss der EU |
| **Functional Software, Inc. (Sentry)** | Fehlererfassung und Crash Reporting | USA/EU | Art. 6 Abs. 1 lit. f DSGVO |

**Alle Datenübertragungen erfolgen verschlüsselt via HTTPS/TLS.**

---

## 5. Technische und organisatorische Maßnahmen

Zum Schutz Ihrer Daten setzen wir folgende Sicherheitsmaßnahmen ein:

- **Verschlüsselung:** TLS/HTTPS für alle Datenübertragungen
- **Passwort-Schutz:** bcrypt-Hashing mit Salt
- **Zugriffsschutz:** Row Level Security (RLS) in Datenbank
- **Token-Sicherheit:** Sichere Speicherung in iOS Keychain
- **Audit-Logs:** Protokollierung sicherheitsrelevanter Vorgänge
- **Datensparsamkeit:** Kein Tracking, keine Werbung, kein Profiling
- **Backup-Strategie:** Regelmäßige Sicherungen (30-Tage-Aufbewahrung)

---

## 6. Ihre Rechte nach DSGVO

Sie haben folgende Rechte bezüglich Ihrer personenbezogenen Daten:

- **Auskunft (Art. 15):** Übersicht über alle gespeicherten Daten
- **Berichtigung (Art. 16):** Korrektur falscher oder unvollständiger Daten
- **Löschung (Art. 17):** Vollständige Löschung Ihres Kontos in der App
- **Datenportabilität (Art. 20):** Export Ihrer Daten im JSON-Format
- **Widerspruch (Art. 21):** Widerspruch gegen Datenverarbeitung
- **Beschwerde (Art. 77):** Beschwerde bei Aufsichtsbehörde

**Ausübung Ihrer Rechte:**

Zur Ausübung Ihrer Rechte kontaktieren Sie uns bitte per E-Mail: **datenschutz@culinaai.com**

Wir werden Ihre Anfrage unverzüglich bearbeiten.

---

## 7. Speicherdauer

| Datentyp | Speicherdauer | Löschmethode |
|----------|---------------|--------------|
| Benutzerkonto | Bis zur Löschung | Manuell durch Nutzer |
| Rezepte & Favoriten | Bis zur Löschung | Mit Konto |
| Ernährungspräferenzen | Bis zur Löschung | Mit Konto |
| Chat-Nachrichten | Sitzungsdauer | Nach App-Schließen |
| API-Protokolle | 30 Tage | Technische Logs |
| Audit-Protokolle | 3 Jahre | Gesetzliche Pflicht |

---

## 8. Minderjährigenschutz

**Altersanforderung:** Die Nutzung der App ist Personen ab 16 Jahren gestattet. Personen unter 16 Jahren benötigen die Einwilligung eines Erziehungsberechtigten gemäß Art. 8 DSGVO.

---

## 9. Keine Werbung oder Tracking

**Wir verzichten vollständig auf:**

- Cookies oder ähnliche Tracking-Technologien
- Google Analytics oder vergleichbare Analysedienste
- Werbung, Werbenetzwerke oder Profilbildung
- Social-Media-Plugins oder externe Tracker

**✅ Ihre persönlichen Daten werden niemals an Dritte verkauft oder für Werbezwecke verwendet.**

---

## 10. Kontolöschung

Sie können Ihr Konto jederzeit in den Einstellungen vollständig löschen.

**Löschung durchführen:**

1. Öffnen Sie die Einstellungen in der App
2. Wählen Sie 'Konto löschen'
3. Bestätigen Sie die Löschung

**Folgende Daten werden gelöscht:**

- Benutzerkonto und Authentifizierungsdaten
- Alle gespeicherten Rezepte, Menüs und Favoriten
- Ernährungspräferenzen und persönliche Einstellungen
- Bewertungen und Notizen

**Wichtiger Hinweis:**

- Apple-Abonnements müssen separat in der Apple-ID-Verwaltung gekündigt werden.
- Audit-Protokolle der Löschung werden aus rechtlichen Gründen 3 Jahre aufbewahrt (Art. 6 Abs. 1 lit. c DSGVO).
- Die Löschung ist endgültig und kann nicht rückgängig gemacht werden.

---

## 11. Änderungen dieser Datenschutzerklärung

Wir behalten uns vor, diese Datenschutzerklärung bei rechtlichen oder technischen Änderungen anzupassen. Die jeweils aktuelle Version finden Sie in der App sowie unter https://culinaai.com/datenschutz. Bei wesentlichen Änderungen werden Sie innerhalb der App informiert.

---

## 12. Kontakt

**Datenschutzanfragen:** datenschutz@culinaai.com  
**Technischer Support:** support@culinaai.com  
**Allgemeine Anfragen:** kontakt@culinaai.com

---

## 13. Anwendbares Recht und Gerichtsstand

Für diese Datenschutzerklärung und die Datenverarbeitung gilt ausschließlich deutsches Recht. Gerichtsstand ist Deutschland.

**Maßgebliche Rechtsgrundlagen:**

- **DSGVO:** Datenschutz-Grundverordnung
- **BDSG:** Bundesdatenschutzgesetz
- **TMG:** Telemediengesetz
- **UWG:** Gesetz gegen den unlauteren Wettbewerb
- **BGB:** Bürgerliches Gesetzbuch

---

**Stand:** 04. November 2025  
**Version:** 1.0
