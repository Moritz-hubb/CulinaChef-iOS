# Widget-Logs erscheinen nicht in Haupt-App Console

## Problem: Widget-Logs in separatem Prozess

**WICHTIG:** Widget Extensions laufen in einem **separaten Prozess** von der Haupt-App. Deshalb erscheinen Widget-Logs **nicht** in der Xcode Console der Haupt-App!

## Lösung 1: Console.app verwenden (Empfohlen)

1. **Öffne Console.app** (Programme → Dienstprogramme)
2. **Wähle deinen Simulator** in der linken Sidebar
3. **Filtere nach:** `com.moritzserrin.culinachef.widget`
4. **Oder suche nach:** `[Widget]`

**Du solltest jetzt alle Widget-Logs sehen!**

## Lösung 2: Terminal log stream

**Im Terminal (während Simulator läuft):**

```bash
# Alle Widget-Logs in Echtzeit
xcrun simctl spawn booted log stream --predicate 'subsystem == "com.moritzserrin.culinachef.widget"'

# Oder alle CulinaChef-Logs (App + Widget)
xcrun simctl spawn booted log stream --predicate 'subsystem contains "culinachef"'
```

## Lösung 3: Xcode Console für Widget Extension

**Wenn du das Widget Extension Scheme ausführst:**

1. **Wähle Scheme "CulinaChefTimerWidget"**
2. **Führe es aus** (⌘R)
3. **Öffne Debug Area** (⇧⌘Y)
4. **Console Tab** öffnen
5. **Widget-Logs sollten jetzt erscheinen!**

**Aber:** Wenn du die Haupt-App ausführst, siehst du keine Widget-Logs in der Xcode Console.

## Wichtig: SSL Pinning Fehler beheben

**Bevor du Widget-Logs sehen kannst, muss der SSL Pinning Fehler behoben werden!**

Die App crasht wegen fehlender Zertifikate. Führe aus:

```bash
cd ios
./scripts/download_ssl_certificates.sh
```

Oder lade die Zertifikate manuell herunter und platziere sie in:
- `ios/supabase.cer`
- `ios/backend.cer`

## Debug-Workflow:

1. **Zuerst:** SSL-Zertifikate herunterladen
2. **Dann:** Haupt-App ausführen (sollte nicht mehr crashen)
3. **Dann:** Widget Extension Scheme ausführen
4. **Öffne Console.app** oder **Terminal log stream**
5. **Prüfe Widget-Logs**

## Erwartete Widget-Logs:

```
[Widget] CulinaChefTimerWidget initialized with kind: CulinaChefTimerWidget
[Widget] getTimeline() called - context.isPreview: false
[Widget] loadTimers() called, appGroupID: group.com.moritzserrin.culinachef
[Widget] loadTimers() UserDefaults accessed successfully
[Widget] loadTimers() Found 2 timer entries in UserDefaults
[Widget] TimerWidgetEntryView rendering - family: Medium, timers: 2
```

## Zusammenfassung:

✅ **Widget-Logs laufen in separatem Prozess**
✅ **Verwende Console.app oder Terminal log stream**
✅ **Oder führe Widget Extension Scheme aus**
✅ **Behebe zuerst SSL Pinning Fehler**

