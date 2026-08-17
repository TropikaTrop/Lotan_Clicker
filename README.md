# Lotan Clicker 2.0

A Godot 4.6 incremental/clicker game.

## Play it as a phone app (no app store)

The `docs/` folder contains a self-contained Web/PWA export of the game. Once this repo
is hosted with GitHub Pages (Settings → Pages → Deploy from branch → `main` / `docs`),
open the Pages URL on a phone browser and use **"Add to Home Screen"**
(Chrome/Android) or **Share → Add to Home Screen** (Safari/iOS). It installs a
launcher icon and opens full-screen, landscape-locked, with no browser chrome —
no Play Store / App Store submission involved.

You can also just share the Pages link phone-to-phone (text, chat, QR code, etc.)
instead of installing it — it runs directly in any mobile browser.

## Rebuilding the web export

Open the project in Godot 4.6.1, then:

```
godot --headless --export-release "Web" docs/index.html
```

The `Web` export preset (in `export_presets.cfg`) is configured with the Progressive
Web App option enabled, so re-exporting regenerates the manifest, service worker, and
icons into `docs/` automatically.
