# Informativa sulla privacy

per l'app iOS "CulinaAI"

**Data:** 04.11.2025  
**Versione:** 1.0

---

## 1. Titolare del trattamento

**Azienda:** CulinaAI  
**Rappresentata da:** Moritz Serrin  
**Indirizzo:** Sonnenblumenweg 8, 21244 Buchholz, Germania  
**E-mail:** kontakt@culinaai.com  
**Privacy:** datenschutz@culinaai.com

---

## 2. Informazioni generali

La protezione dei dati personali è una priorità per noi. Trattiamo i dati personali esclusivamente conformemente al GDPR, alla legge federale tedesca sulla protezione dei dati (BDSG) e ad altre normative applicabili.

**Principi di trattamento dei dati:**

- **Minimizzazione:** Raccogliamo solo i dati necessari
- **Trasparenza:** Comunicazione chiara sull'uso dei dati
- **Sicurezza:** Crittografia TLS e archiviazione sicura
- **Nessuna pubblicità:** Niente tracciamento o profilazione

---

## 3. Dati raccolti

### 3.1 Account utente

**Dati richiesti alla registrazione:**

- Nome utente (3–32 caratteri)
- Indirizzo e-mail
- Password (min. 6 caratteri, bcrypt)
- Opzionale: Sign in with Apple

**Scopo:** Creazione e autenticazione account  
**Base legale:** Art. 6 Abs. 1 lit. b GDPR (esecuzione contratto)

### 3.2 Gestione ricette

**Dati memorizzati:**

- Titolo ricetta, ingredienti, istruzioni
- Valori nutrizionali, tempi, tag
- Preferiti, pianificazione menu
- Valutazioni (1–5 stelle)

**Scopo:** Funzione principale dell'app – gestione ricette  
**Conservazione:** Fino a cancellazione da parte dell'utente

### 3.3 Preferenze alimentari

- Allergie (es. noci, glutine)
- Tipologia di alimentazione (vegano, vegetariano)
- Preferenze o avversioni
- Note (testo libero)

**Scopo:** Suggerimenti ricette personalizzati e filtri

### 3.4 Intelligenza artificiale (OpenAI)

Utilizziamo OpenAI GPT-4o-mini per:

- Creazione automatica di ricette
- Risposte a domande di cucina

**Dati trasmessi:**

- Liste ingredienti
- Messaggi chat
- Preferenze alimentari (contesto)
- **NESSUN dato personale**

**Fornitore terzo:** OpenAI L.L.C.

- **Destinatario:** OpenAI L.L.C., USA
- **Base legale:** Art. 49 Abs. 1 lit. a GDPR (consenso)
- **Durata conservazione:** Max 30 giorni presso OpenAI

**Nota importante:** I contenuti generati dall'IA sono automatizzati. Non ci assumiamo responsabilità per la loro accuratezza, completezza o idoneità sanitaria.

**Avviso importante sulle ricette generate dall'IA:**

I sistemi di IA possono commettere errori. Si prega di rivedere attentamente tutte le ricette generate dall'IA prima di prepararle. Soprattutto se si hanno allergie, intolleranze o requisiti dietetici speciali, si dovrebbe verificare due volte l'elenco degli ingredienti e le istruzioni.

Non ci assumiamo responsabilità per le conseguenze sanitarie derivanti dall'uso di ricette generate dall'IA. La responsabilità di rivedere le ricette e decidere se una ricetta è adatta alle proprie esigenze individuali spetta esclusivamente a voi.

### 3.5 Pagamenti (Apple)

**Abbonamento:** 5,99 €/mese tramite Apple In-App Purchase

Dati trattati da Apple:

- Apple ID
- Informazioni di pagamento
- Storico acquisti

**Nota:** Non riceviamo dati di pagamento, solo conferma transazione da Apple. Per maggiori informazioni, consultare l'Informativa sulla Privacy di Apple.

### 3.6 Report errori e crash (Sentry)

Usiamo **Sentry** di Functional Software, Inc. per migliorare la stabilità dell'app.

**Dati trasmessi in caso di crash o errore:**

- Informazioni dispositivo (modello, versione iOS)
- Versione app e numero di build
- Stack trace (log tecnici degli errori)
- Timestamp dell'errore
- Screenshot al momento dell'errore (opzionale)
- Azioni utente prima dell'errore (breadcrumbs)
- **NESSUN dato personale** (nomi, e-mail, ecc.)

**Fornitore terzo:** Functional Software, Inc. (Sentry)

- **Destinatario:** Functional Software, Inc., USA
- **Base legale:** Art. 6 Abs. 1 lit. f GDPR (interesse legittimo)
- **Durata conservazione:** 30 giorni presso Sentry
- **Trasferimento dati:** UE/USA, conforme al GDPR

**Scopo:** Rilevamento e risoluzione di errori tecnici per migliorare la stabilità dell'app.

Per maggiori informazioni: [Informativa sulla Privacy di Sentry](https://sentry.io/privacy/)

### 3.7 Archiviazione locale

**UserDefaults (non sensibile):**

- Lingua app, modalità scura
- Stato onboarding
- Cache suggerimenti menu

**Keychain (crittografato):**

- Token di accesso e aggiornamento
- ID utente, e-mail

**Cancellazione:** Eseguita automaticamente da iOS alla disinstallazione dell'app

---

## 4. Trasferimento dati verso Paesi terzi

I seguenti fornitori possono elaborare dati al di fuori dell'Unione Europea:

| Fornitore | Scopo | Ubicazione | Base Legale |
|-----------|-------|------------|-------------|
| **Supabase Inc.** | Database e autenticazione | UE/USA | Art. 6 Abs. 1 lit. b GDPR |
| **OpenAI L.L.C.** | Generazione ricette con IA | USA | Art. 49 Abs. 1 lit. a GDPR |
| **Apple Inc.** | Acquisti in-app e abbonamenti | USA | Decisione di adeguatezza dell'UE |
| **Functional Software, Inc. (Sentry)** | Monitoraggio errori e crash reporting | USA/UE | Art. 6 Abs. 1 lit. f GDPR |

**Tutti i trasferimenti di dati sono crittografati via HTTPS/TLS.**

---

## 5. Misure tecniche e organizzative

Per proteggere i vostri dati, implementiamo le seguenti misure di sicurezza:

- **Crittografia:** TLS/HTTPS per tutti i trasferimenti di dati
- **Protezione password:** Hash bcrypt con salt
- **Controllo accessi:** Row Level Security (RLS) nel database
- **Sicurezza token:** Archiviazione sicura in iOS Keychain
- **Log di audit:** Registrazione di attività rilevanti per la sicurezza
- **Minimizzazione dati:** Nessun tracciamento, pubblicità o profilazione
- **Strategia backup:** Backup regolari crittografati (conservazione 30 giorni)

---

## 6. Diritti secondo GDPR

Avete i seguenti diritti riguardo ai vostri dati personali:

- **Accesso (Art. 15):** Ricevere informazioni sui vostri dati memorizzati
- **Rettifica (Art. 16):** Correggere dati inesatti o incompleti
- **Cancellazione (Art. 17):** Eliminare il vostro account e i dati associati
- **Portabilità (Art. 20):** Ricevere i vostri dati in formato leggibile da macchina (JSON)
- **Opposizione (Art. 21):** Opporsi a un trattamento specifico di dati
- **Reclamo (Art. 77):** Presentare un reclamo a un'autorità di controllo

**Per esercitare i vostri diritti:**

Contattateci a **datenschutz@culinaai.com**.  
Elaboreremo la vostra richiesta senza ritardo ingiustificato.

---

## 7. Durata conservazione

| Tipo di Dati | Periodo di Conservazione | Metodo di Eliminazione |
|--------------|---------------------------|------------------------|
| Account utente | Fino a cancellazione | Manuale da parte dell'utente |
| Ricette e preferiti | Fino a cancellazione | Con l'account |
| Preferenze alimentari | Fino a cancellazione | Con l'account |
| Messaggi chat | Durata sessione | Eliminati alla chiusura dell'app |
| Log API | 30 giorni | Eliminazione log tecnici |
| Log di audit | 3 anni | Requisito legale |

---

## 8. Protezione minori

**Requisito di età:** L'uso dell'app è consentito a persone di **16 anni o più**.

Gli utenti di età inferiore a 16 anni devono avere il consenso dei genitori o tutori conformemente all'Art. 8 GDPR.

---

## 9. Nessuna pubblicità o tracciamento

**Ci asteniamo completamente dall'usare:**

- Cookie o tecnologie di tracciamento simili
- Google Analytics o strumenti di analisi comparabili
- Pubblicità, reti pubblicitarie o profilazione utenti
- Plugin di social media o tracker esterni

**✅ I vostri dati personali non saranno mai venduti o utilizzati a fini pubblicitari.**

---

## 10. Cancellazione account

Potete eliminare il vostro account in qualsiasi momento seguendo questi passaggi:

1. Aprite **Impostazioni** nell'app
2. Selezionate **"Elimina account"**
3. Confermate la cancellazione

**I dati eliminati includono:**

- Account utente e dati di autenticazione
- Tutte le ricette, menu e preferiti salvati
- Preferenze alimentari e impostazioni personali
- Valutazioni e note

**Importante:**

- Gli abbonamenti Apple devono essere annullati separatamente nelle impostazioni del vostro account Apple ID
- I log di audit relativi al processo di cancellazione sono conservati per tre anni (Art. 6 Abs. 1 lit. c GDPR – obbligo legale)
- La cancellazione è permanente e irreversibile

---

## 11. Modifiche all'informativa sulla privacy

Ci riserviamo il diritto di modificare questa Informativa sulla Privacy in caso di modifiche legali o tecniche.

La versione più recente è sempre disponibile nell'app e su **https://culinaai.com/datenschutz**.

Gli utenti saranno informati di eventuali modifiche significative nell'app.

---

## 12. Contatti

**Richieste di protezione dati:** datenschutz@culinaai.com  
**Supporto tecnico:** support@culinaai.com  
**Richieste generali:** kontakt@culinaai.com

---

## 13. Legge applicabile e foro competente

Questa Informativa sulla Privacy e tutte le attività di trattamento dei dati correlate sono disciplinate esclusivamente dalla legge tedesca.

**Foro competente:** Germania

**Quadro giuridico applicabile:**

- **GDPR** – Regolamento Generale sulla Protezione dei Dati
- **BDSG** – Legge federale tedesca sulla protezione dei dati
- **TMG** – Legge sui servizi di media telematici
- **UWG** – Legge contro la concorrenza sleale
- **BGB** – Codice civile tedesco

---

**Data:** 04. Novembre 2025  
**Versione:** 1.0
