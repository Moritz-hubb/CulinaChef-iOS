# Timer-Klingelton einrichten

## So fügst du deinen Klingelton zur App hinzu:

### 1. Datei vorbereiten
- Stelle sicher, dass deine Audio-Datei eines dieser Formate hat: `.mp3`, `.wav`, `.m4a`, `.aiff`, `.caf`, oder `.aac`
- Benenne die Datei um zu einem dieser Namen:
  - `timer_ringtone` (empfohlen)
  - `ringtone`
  - `timer_complete`
  - `timer_sound`

**Beispiel:** Wenn deine Datei `mein_klingelton.mp3` heißt, benenne sie um zu `timer_ringtone.mp3`

### 2. Datei zu Xcode hinzufügen

1. Öffne das Xcode-Projekt
2. Rechtsklick auf den `Sources` Ordner (oder `Resources` Ordner, falls vorhanden)
3. Wähle "Add Files to CulinaChef..."
4. Wähle deine Audio-Datei aus
5. **WICHTIG:** Stelle sicher, dass:
   - ✅ "Copy items if needed" aktiviert ist
   - ✅ "Add to targets: CulinaChef" aktiviert ist
6. Klicke auf "Add"

### 3. Datei im Projekt prüfen

- Die Datei sollte im Project Navigator sichtbar sein
- Stelle sicher, dass sie im "CulinaChef" Target enthalten ist (Target Membership in File Inspector)

### 4. Testen

- Starte die App
- Starte einen Timer
- Wenn der Timer abläuft, sollte dein Klingelton abgespielt werden
- Der Sound läuft endlos, bis du auf "X" (Timer schließen) klickst

## Unterstützte Dateinamen (in dieser Reihenfolge):
1. `timer_ringtone` (wird zuerst gesucht)
2. `ringtone`
3. `timer_complete`
4. `timer_sound`

## Unterstützte Formate:
- `.mp3` (empfohlen)
- `.wav`
- `.m4a`
- `.aiff`
- `.caf`
- `.aac`

Falls keine Datei gefunden wird, wird der Standard-System-Sound (1016) verwendet.

