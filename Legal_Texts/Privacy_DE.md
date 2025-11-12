# Datenschutzerklärung
für die iOS-App "CulinaChef (CulinaAI)"

**Stand:** 04.11.2025  
**Version:** 1.0

---

## 1. Verantwortlicher

- **Unternehmen:** CulinaAI
- **Vertreten durch:** Moritz Serrin  
- **Adresse:** 21244 Buchholz, Deutschland
- **E-Mail:** kontakt@culinaai.com
- **Datenschutz:** datenschutz@culinaai.com

---

## 2. Allgemeines

Der Schutz Ihrer personenbezogenen Daten ist uns wichtig. Diese Datenschutzerklärung informiert Sie über die Art, den Umfang und Zweck der Verarbeitung personenbezogener Daten in unserer iOS-App CulinaChef (CulinaAI).

### Grundsätze der Datenverarbeitung:

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

**Drittanbieter:** OpenAI L.L.C.

- **Empfänger:** OpenAI L.L.C., USA
- **Rechtsgrundlage:** Art. 49 Abs. 1 lit. a DSGVO (Einwilligung)
- **Speicherdauer:** Maximal 30 Tage bei OpenAI

**Wichtig:** KI-generierte Inhalte sind automatisiert erstellt. Es besteht keine Haftung für Richtigkeit, Vollständigkeit oder gesundheitliche Verträglichkeit.

### 3.5 Zahlungsabwicklung (Apple)

**Abonnement:** 6,99 €/Monat via Apple In-App-Purchase

**Verarbeitet durch Apple:**

- Apple-ID
- Zahlungsinformationen
- Kaufhistorie

**Hinweis:** Wir erhalten keine Zahlungsdaten, ausschließlich Transaktionsbestätigungen von Apple. Weitere Informationen finden Sie in der Apple Datenschutzrichtlinie.

### 3.6 Lokale Speicherung

**UserDefaults (nicht sensibel):**

- App-Sprache, Dark Mode
- Onboarding-Status
- Menüvorschläge (Cache)

**Keychain (verschlüsselt):**

- Access & Refresh Token
- User-ID, E-Mail

**Löschung:** Automatisch bei App-Deinstallation durch iOS

---

## 4. Datenübermittlung in Drittländer

Folgende Drittanbieter verarbeiten Daten außerhalb der EU:

### Supabase Inc.

- **Zweck:** Datenbank und Authentifizierung
- **Standort:** EU/USA
- **Rechtsgrundlage:** Art. 6 Abs. 1 lit. b DSGVO (Vertragserfüllung)

### OpenAI L.L.C.

- **Zweck:** KI-gestützte Rezeptgenerierung
- **Standort:** USA
- **Rechtsgrundlage:** Art. 49 Abs. 1 lit. a DSGVO (Einwilligung)

### Apple Inc.

- **Zweck:** In-App-Käufe und Abonnements
- **Standort:** USA
- **Rechtsgrundlage:** Angemessenheitsbeschluss der EU-Kommission

**Sicherheit:** Alle Datenübertragungen erfolgen verschlüsselt via HTTPS/TLS.

---

## 5. Technische und organisatorische Maßnahmen

Zum Schutz Ihrer Daten setzen wir folgende Maßnahmen um:

- **Verschlüsselung:** TLS/HTTPS für alle Datenübertragungen
- **Passwort-Schutz:** bcrypt-Hashing mit Salt
- **Zugriffsschutz:** Row Level Security (RLS) in Datenbank
- **Token-Sicherheit:** Sichere Speicherung in iOS Keychain
- **Audit-Logs:** Protokollierung sicherheitsrelevanter Vorgänge
- **Datensparsamkeit:** Kein Tracking, keine Werbung, kein Profiling
- **Backup-Strategie:** Regelmäßige Sicherungen (30-Tage-Aufbewahrung)

---

## 6. Ihre Rechte nach DSGVO

Sie haben folgende Rechte:

- **Auskunft (Art. 15):** Übersicht über alle gespeicherten Daten
- **Berichtigung (Art. 16):** Korrektur falscher oder unvollständiger Daten
- **Löschung (Art. 17):** Vollständige Löschung Ihres Kontos in der App
- **Datenportabilität (Art. 20):** Export Ihrer Daten im JSON-Format
- **Widerspruch (Art. 21):** Widerspruch gegen Datenverarbeitung
- **Beschwerde (Art. 77):** Beschwerde bei Aufsichtsbehörde

**Ausübung Ihrer Rechte:**

Kontakt: datenschutz@culinaai.com

Zur Ausübung Ihrer Rechte kontaktieren Sie uns bitte per E-Mail. Wir werden Ihre Anfrage unverzüglich bearbeiten.

---

## 7. Speicherdauer

| Datentyp | Dauer | Löschmethode |
|----------|-------|--------------|
| Benutzerkonto | Bis zur Löschung | Manuell durch Nutzer |
| Rezepte & Favoriten | Bis zur Löschung | Mit Konto |
| Ernährungspräferenzen | Bis zur Löschung | Mit Konto |
| Chat-Nachrichten | Sitzungsdauer | Nach App-Schließen |
| API-Protokolle | 30 Tage | Technische Logs |
| Audit-Protokolle | 3 Jahre | Gesetzliche Pflicht |

**Hinweis:** Chat-Nachrichten werden nur temporär während der aktiven Sitzung gespeichert und nicht dauerhaft in der Datenbank abgelegt.

---

## 8. Minderjährigenschutz

**Altersanforderung:** Die Nutzung der App ist Personen ab 16 Jahren gestattet. Personen unter 16 Jahren benötigen die Einwilligung eines Erziehungsberechtigten gemäß Art. 8 DSGVO.

---

## 9. Keine Werbung oder Tracking

Wir verzichten vollständig auf:

- Cookies oder ähnliche Tracking-Technologien
- Google Analytics oder vergleichbare Analysedienste
- Werbung, Werbenetzwerke oder Profilbildung
- Social-Media-Plugins oder externe Tracker

**Garantie:** Ihre persönlichen Daten werden niemals an Dritte verkauft oder für Werbezwecke verwendet.

---

## 10. Kontolöschung

Sie können Ihr Konto jederzeit vollständig löschen:

**So gehen Sie vor:**

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

- **DSGVO** – Datenschutz-Grundverordnung
- **BDSG** – Bundesdatenschutzgesetz
- **TMG** – Telemediengesetz
- **UWG** – Gesetz gegen den unlauteren Wettbewerb
- **BGB** – Bürgerliches Gesetzbuch

---

**Stand:** 04. November 2025  
**Version:** 1.0
