# Backend Deployment Guide

Dieses Dokument beschreibt wie du dein FastAPI-Backend für die CulinaChef iOS App deployest.

## 🎯 Ziel-URLs

```
Development: http://127.0.0.1:8000 (lokal)
Staging:     https://staging-api.culinaai.com (optional)
Production:  https://api.culinaai.com
```

---

## 🚂 Option 1: Railway (Empfohlen)

**Vorteile:**
- ✅ Sehr einfaches Setup
- ✅ Automatisches HTTPS
- ✅ Free Tier verfügbar
- ✅ 1-Click Deployment

### Schritt 1: Railway Account

1. Gehe zu https://railway.app
2. Sign Up mit GitHub
3. Erstelle ein neues Projekt

### Schritt 2: Backend deployen

```bash
# In deinem Backend-Verzeichnis
cd /Users/moritzserrin/CulinaChef/backend

# Railway CLI installieren (optional, aber empfohlen)
npm install -g @railway/cli
# oder: brew install railway

# Login
railway login

# Projekt initialisieren
railway init

# Deployen
railway up
```

**Oder via GitHub:**
1. Push dein Backend zu GitHub
2. In Railway: "Deploy from GitHub repo"
3. Wähle dein Backend-Repository
4. Railway deployed automatisch bei jedem Push

### Schritt 3: Environment Variables setzen

In Railway Dashboard → Variables:

```env
OPENAI_API_KEY=sk-proj-dein-key
SUPABASE_URL=https://ywduddopwudltshxiqyp.supabase.co
SUPABASE_KEY=dein-supabase-key
DATABASE_URL=deine-postgres-url
ENVIRONMENT=production
```

### Schritt 4: Custom Domain

1. Railway Dashboard → Settings → Domains
2. Add Custom Domain: `api.culinaai.com`
3. Railway zeigt CNAME an (z.B. `abc123.up.railway.app`)

### Schritt 5: DNS konfigurieren

Bei deinem Domain-Provider (Namecheap/Cloudflare/etc.):

```dns
Type:  CNAME
Name:  api
Value: deine-app.up.railway.app
TTL:   Auto
```

**Warte 10-30 Minuten für DNS-Propagierung.**

### Schritt 6: SSL prüfen

```bash
curl https://api.culinaai.com/health
# Sollte 200 OK zurückgeben
```

---

## ✈️ Option 2: Fly.io

**Vorteile:**
- ✅ Sehr gutes Preis-Leistungs-Verhältnis
- ✅ Global verteilte Apps
- ✅ Free Tier bis 3 Apps

### Setup

```bash
# Fly CLI installieren
curl -L https://fly.io/install.sh | sh

# Login
fly auth login

# In Backend-Verzeichnis
cd /Users/moritzserrin/CulinaChef/backend

# App erstellen
fly launch
# Name: culinachef-api
# Region: Frankfurt (oder näher zu deinen Usern)

# Environment Variables setzen
fly secrets set OPENAI_API_KEY=sk-proj-...
fly secrets set SUPABASE_URL=https://...
fly secrets set SUPABASE_KEY=...

# Deployen
fly deploy

# Custom Domain
fly certs add api.culinaai.com
```

**DNS Setup:**
```dns
Type:  A
Name:  api
Value: [IP von fly certs show api.culinaai.com]
```

---

## 🎨 Option 3: Render

**Vorteile:**
- ✅ Free Tier verfügbar
- ✅ Sehr einfaches UI
- ✅ Automatische HTTPS

### Setup

1. Gehe zu https://render.com
2. New → Web Service
3. Verbinde GitHub Repository
4. Settings:
   ```
   Build Command:   pip install -r requirements.txt
   Start Command:   uvicorn app.main:app --host 0.0.0.0 --port $PORT
   ```
5. Environment Variables hinzufügen
6. Custom Domain: `api.culinaai.com`
7. DNS: CNAME zu `xyz.onrender.com`

---

## 🔧 Nach dem Deployment

### 1. Health-Check testen

```bash
# Prüfe dass Backend läuft
curl https://api.culinaai.com/health

# Erwartete Response:
# {"status": "ok"}
```

### 2. iOS App aktualisieren

```bash
cd /Users/moritzserrin/CulinaChef/ios

# In Config.swift ist bereits gesetzt:
# case .production:
#     return URL(string: "https://api.culinaai.com")!

# Projekt neu generieren
./gen.sh

# In Xcode: Build & Run
# Wähle Release-Scheme für Production-Test
```

### 3. Finale Tests

1. **Authentication testen:**
   - Sign Up in der App
   - Sign In mit existierendem Account

2. **API-Calls prüfen:**
   - Rezept erstellen
   - Rezept laden
   - OpenAI-Generation testen

3. **Performance checken:**
   - Response-Zeiten < 500ms?
   - Keine Timeouts?

---

## 🔒 Sicherheit Checklist

- [ ] HTTPS aktiviert und funktioniert
- [ ] Environment Variables (nicht im Code!)
- [ ] CORS richtig konfiguriert
- [ ] Rate Limiting aktiviert (gegen Missbrauch)
- [ ] Error Messages nicht zu verbose (keine Secrets leaken)
- [ ] Logging aktiviert (für Debugging)
- [ ] Backup-Strategie für Datenbank

---

## 🐛 Troubleshooting

### "Connection refused"
- Backend läuft auf Port $PORT (Railway/Render setzen das automatisch)
- Firewall erlaubt eingehende Connections

### "SSL Certificate Error"
- Warte 10-30 Min nach DNS-Setup
- Prüfe CNAME ist korrekt gesetzt: `dig api.culinaai.com`

### "Environment Variables nicht gesetzt"
- In Railway/Fly/Render Dashboard prüfen
- Nach Änderung: Re-deploy triggern

### "502 Bad Gateway"
- Backend ist crashed oder startet nicht
- Logs checken: `railway logs` oder im Dashboard

---

## 📊 Monitoring

### Railway
- Dashboard → Metrics
- Logs in Realtime

### Sentry (für Backend)
```bash
pip install sentry-sdk[fastapi]
```

In FastAPI:
```python
import sentry_sdk
sentry_sdk.init(dsn="dein-backend-sentry-dsn")
```

---

## 💰 Kosten-Übersicht

| Plattform | Free Tier | Bezahlt ab | Empfehlung |
|-----------|-----------|------------|------------|
| Railway   | $5 Guthaben | $5/Monat | ⭐ Am einfachsten |
| Fly.io    | 3 Apps free | $0/Monat mit Limits | ⭐ Bestes Preis-Leistung |
| Render    | Free (mit Einschränkungen) | $7/Monat | Gut für Anfänger |

**Empfehlung:** Start mit Railway Free Tier, später zu Fly.io wenn mehr Traffic.

---

## 📞 Support

Bei Fragen oder Problemen:
- Railway: https://railway.app/help
- Fly.io: https://community.fly.io
- Render: https://render.com/docs
