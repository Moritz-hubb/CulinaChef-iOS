# Git History Cleanup - Falls API-Keys leaked sind

## ⚠️ Nur ausführen wenn wirklich nötig!

**Status:** ✅ Keine API-Keys in aktueller Git History gefunden (2025-11-12)

Falls in Zukunft versehentlich Secrets committed werden:

## Methode 1: BFG Repo-Cleaner (Empfohlen)

```bash
# 1. BFG installieren
brew install bfg

# 2. Repository klonen (frische Kopie)
cd ~/Desktop
git clone --mirror https://github.com/Moritz-hubb/CulinaChef-iOS.git

# 3. Textdatei mit Secrets erstellen
cat > passwords.txt << 'EOF'
sk-proj-OLD_KEY_HERE
sk-OLD_KEY_HERE
SENTRY_DSN_OLD_HERE
EOF

# 4. BFG ausführen
bfg --replace-text passwords.txt CulinaChef-iOS.git

# 5. Git Garbage Collection
cd CulinaChef-iOS.git
git reflog expire --expire=now --all
git gc --prune=now --aggressive

# 6. Force Push (⚠️ VORSICHT!)
git push --force

# 7. Alle Collaborators müssen neu clonen
cd ~/CulinaChef/ios
git pull --force
```

## Methode 2: git filter-repo (Alternative)

```bash
# Installieren
brew install git-filter-repo

# Repository klonen
cd ~/Desktop
git clone https://github.com/Moritz-hubb/CulinaChef-iOS.git
cd CulinaChef-iOS

# String aus History entfernen
git filter-repo --replace-text <(echo "sk-proj-OLD_KEY==>REMOVED")

# Force Push
git push --force
```

## Nach dem Cleanup

1. **Neue Keys generieren:**
   - OpenAI: https://platform.openai.com/api-keys
   - Sentry: https://sentry.io/settings/projects/

2. **Alle Team-Mitglieder informieren:**
   - Alte Repositories löschen
   - Neu clonen: `git clone https://github.com/Moritz-hubb/CulinaChef-iOS.git`

3. **Keys aktualisieren:**
   - `Configs/Secrets.xcconfig` mit neuen Keys
   - Railway Environment Variables updaten
   - Backend `.env` updaten

## Prüfen ob Keys in History sind

```bash
# Suche nach OpenAI Keys
git log --all -p -S "sk-proj-" --source --all

# Suche nach Sentry DSN
git log --all -p -S "sentry.io" --source --all

# Alle Secrets.xcconfig commits
git log --all --full-history -- "*Secrets.xcconfig"
```

## Verhindern zukünftiger Leaks

1. **git-secrets installieren:**
```bash
brew install git-secrets
cd /Users/moritzserrin/CulinaChef/ios
git secrets --install
git secrets --register-aws
git secrets --add 'sk-proj-[A-Za-z0-9_-]{20,}'
git secrets --add 'sentry\.io/[0-9]+'
```

2. **Pre-commit Hook:**
Verhindert Commits mit Secrets automatisch.
