# Share Extension (optional)

Damit „Teilen → CulinaChef“ direkt aus TikTok/YouTube funktioniert, im Xcode-Projekt ein **Share Extension**-Target anlegen:

1. **File → New → Target → Share Extension** (z. B. Name `CulinaShare`).
2. **App Groups** für Haupt-App und Extension aktivieren (z. B. `group.app.culinachef`) – in beiden Targets dieselbe Gruppe.
3. In der Extension `ShareViewController` (siehe Vorlage `ShareViewController.swift` in diesem Ordner): `extensionContext`-Items lesen (`public.url`, `public.plain-text`), URL in die **App Group** schreiben, dann die Haupt-App per **URL Scheme** öffnen, z. B. `culinachef://import?url=ENCODED`.
4. In der **Haupt-App** `onOpenURL` / `application(_:open:options:)` abfangen, `pendingImportURL` setzen und `SocialRecipeImportView` mit vorausgefüllter URL zeigen (oder direkt `importRecipeFromSocialURL` starten).

Ohne Xcode-Projektdatei im Repo kann die Extension hier nur als **Vorlage** liegen; die in-App-Variante (**Meine Rezepte → Aus Social Media**) ist vollständig nutzbar.
