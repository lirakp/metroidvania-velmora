# Blutmond – ein Metroidvania aus Velmora

2D-Pixel-Art-Metroidvania mit rundenbasierten Kämpfen. Die Welt stammt aus unserer „Bibel der Welt“:
Der König der Ewigkeit setzt auf Velmora seinen Schlachtplan durch, der Blutmond geht nicht mehr unter.
Ihr spielt die Halbelfen-Geschwister **Warschick** oder **Lira**, das andere Geschwister begleitet euch.

> **Ab 18 Jahren.** Düstere Welt, Gewalt, Horror. Hobbyprojekt, Prototyp.

## Herunterladen und spielen (Windows)

1. Unter **Releases** die Datei `Blutmond-windows.zip` herunterladen.
2. Entpacken, `Blutmond.exe` starten (`Blutmond.pck` muss daneben liegen).
3. Windows warnt evtl. vor einer unbekannten App: „Weitere Informationen“ → „Trotzdem ausführen“.

Spielstände liegen unter `%APPDATA%\Godot\app_userdata\Blutmond\save1.json`.

## Steuerung

| Aktion | Tastatur | Gamepad |
|---|---|---|
| Laufen | A / D oder ← / → | Stick, Steuerkreuz |
| Springen (in der Luft erneut: Federfall) | Leertaste | A |
| Feldschlag (Erstschlag) | J | X |
| Geschwister schicken / zurückrufen | K | Y |
| Interagieren (Rastort, Kartograf) | W oder ↑ | Steuerkreuz hoch |
| Karte | M | Select/Back |
| Menüs | ↑ ↓ Enter, Esc zurück | Steuerkreuz, A, B |

## Was im Prototyp steckt

- Kornburg (Gildenhalle, Stadt, Kornfelder, Mühle) und ein Blut-Dungeon mit dem Blutwolf-Alpha als Boss
- Rundenkampf auf eigenem Kampfplatz: Erstschlag/Überfall, zwei Manaflüsse der Halbelfen, Tribut der Ausrüstung
- Seelenplaketten (höchstens 5) als Rückkehrpunkte, Speichern nur an Gildenhalle und Rastort, 10 % Blutsteuer beim Tod
- Einweg-Dungeons, Karten beim Kartografen, Geschwister-Rätsel mit Druckplatten, Federfall

## Selbst bauen (Linux)

```bash
bash tools/setup_godot.sh      # Godot 4.3 + Exportvorlagen nach tools/bin/
tools/run_tests.sh             # alle Tests
python3 tools/gen_art.py       # Platzhalter-Grafik neu erzeugen
python3 tools/gen_rooms.py     # Räume neu erzeugen
bash tools/build_windows.sh    # → build/Blutmond-windows.zip
```

Projektaufbau: `game/` (Godot-Projekt), `game/core/` (Spiellogik, getestet), `game/data/` (Gegner, Zauber,
Ausrüstung, Dialoge, Räume), `docs/` (Spiel-Design und Bauplan).
