# Arbeitsweise im Projekt Blutmond

- **Direkt auf `main` arbeiten:** Änderungen werden direkt auf `main` committet und gepusht, ohne Feature-Branch
  und ohne Pull Request (Wunsch des Teams, 2026-11-26).
- Vor jedem Push: `tools/run_tests.sh` muss grün sein.
- Spieltexte auf Deutsch, Code-Bezeichner auf Englisch.
- Räume nicht von Hand ändern, sondern in `tools/gen_rooms.py` (danach `python3 tools/gen_rooms.py`).
- Grafik aus dem Grafik-Repo lirakp/aniamtion unverändert übernehmen: `python3 tools/import_cosy.py ../aniamtion`.
- Veröffentlichen: Release-Notizen nach `docs/releases/<version>.md`, dann Workflow „Release bauen“ mit der Version starten.
- Welt und Regeln: „Bibel der Welt“ (Claude-Docs-Artifact) – Spielinhalte müssen dazu passen.
