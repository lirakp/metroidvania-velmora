# Läden, Auftragsbrett, Waldstück und Sammeln – Entwurf

Stand 2026-11-26. Baut auf dem Unterdorf (dorf_01..03) und der Gildenhalle Kornburg auf.

## Absicht

Der Spieler soll einen Kreislauf außerhalb der Dungeons haben: in Kornfeldern und Wald sammeln und kämpfen,
Aufträge am Brett der Gilde erfüllen oder Waren verkaufen, und das Silber in Vorräte und bessere Ausrüstung
stecken. Gesammeltes soll einen eigenen Nutzen haben (Wahl B des Nutzers): Beeren und Heilkraut heilen etwas,
der Bäcker backt aus Weizen Brot, das stärker heilt. Kein vollständiges Handwerks- oder Kochsystem.

## Ziele

1. Drei Läden im Unterdorf sind über ihre Tür betretbar (eigener Innenraum mit Ladeninhaber): Kaufen und Verkaufen.
2. Auftragsbrett in der Gildenhalle mit zufälligen Aufträgen von Dorfbewohnern und der Gilde.
3. Ein Waldstück rechts von kornfeld_08 (schließt die bisherige Sackgasse rechts vom Portal).
4. Sammelstellen: Weizen auf den Kornfeldern; Beeren, Pilze und Heilkraut im Wald.
5. Vorräte sind im Kampf (Menüpunkt „Gegenstand“, bisher gesperrt) und im Pausenmenü benutzbar.

## Nicht-Ziele

- Kein Rezept- oder Herstellungssystem außer „Bäcker backt Brot aus Weizen“.
- Taverne und offene Schmiede bleiben geschlossen (der Wirt sagt das schon im Spiel).
- Keine Tageszeit, keine zeitgesteuerte Erneuerung.
- Keine neue Ausrüstung über Rang C hinaus in Läden (Bibel: weltliche Schmiede D–B, Dungeon-Ware erst später).

## Anti-Ziele

- Sammeln darf nicht zum Warten an einer Stelle verleiten (deshalb Erneuerung nur beim Rasten).
- Läden dürfen die Dungeon-Beute nicht entwerten (kein Tribut-Gerät, nichts ab Rang A zu kaufen).
- Keine Inhalte gegen die Bibel: Währung Silber (Gold für große Summen), Gilde zahlt mit Blutsteuer-Humor,
  Konsortium hält die Waage.

## Ansätze (entschieden)

- **Waldstück:** rechts von kornfeld_08 (gewählt) statt Abzweig aus einem mittleren Kornfeld – schließt die
  Sackgasse, ein Abzweig wäre nur ein Umweg.
- **Erneuerung von Aufträgen und Sammelstellen:** beim Rasten an einem Schrein/Rastort (gewählt) statt nach Zeit –
  es gibt wegen des ewigen Blutmonds keinen Tageswechsel, und Rasten setzt ohnehin die Welt zurück.
- **Läden:** echte Innenräume über die vorhandenen Gebäudetüren (wie Kartograf/Gilde), weil der Nutzer
  „betreten“ wollte.

## Gegenstände (neue Datei `game/data/items.json`)

Stapelbare Vorräte und Waren, getrennt von der Ausrüstung. Zahlen sind meine Wahl und dürfen später justiert werden.

| id | Name | Wirkung | Kauf | Verkauf | Herkunft |
|---|---|---|---|---|---|
| weizen | Weizen | – (Zutat) | – | 1 | Kornfelder |
| beeren_rot | Waldbeeren | +8 LP | – | 2 | Wald |
| blaubeeren | Blaubeeren | +8 LP | – | 2 | Wald |
| pilz | Waldpilz | +5 Mana (nur im Kampf) | – | 2 | Wald |
| leuchtpilz | Leuchtpilz | +15 Mana (nur im Kampf) | – | 6 | Wald (selten) |
| manablume | Manablume | +10 Mana (nur im Kampf) | – | 5 | Wald (selten) |
| heilkraut | Heilkraut | +15 LP | – | 4 | Wald |
| apfel | Apfel | +10 LP | 4 | 2 | Bäckerei, Apfelbaum im Kornfeld |
| brot | Brot | +30 LP | 12 | 5 | Bäckerei, oder backen lassen |
| heil_klein | Kleiner Heiltrank | +50 LP | 30 | 12 | Alchemie |
| mana_klein | Kleiner Manatrank | +25 Mana | 30 | 12 | Alchemie |
| monsterkern_D | Monsterkern (D) | – | – | 15 | Beute (Gegner Rang D) |
| monsterkern_C | Monsterkern (C) | – | – | 35 | Beute (Gegner Rang C) |

- `GameState.items: Dictionary` (id → Anzahl). Ausrüstung bleibt in `inventory`. Speicherstand: neues Feld mit
  Vorgabe `{}`, alte Stände laden weiter.
- Wirkungen: `heal_hp`, `heal_mana`. Wirkt auf eine gewählte Figur der Gruppe.
- Mana (meine Wahl): Mana wird heute nicht zwischen Kämpfen gespeichert, jeder Kampf beginnt voll. Daher wirken
  Mana-Vorräte nur im Kampf und füllen beide Flüsse (C und S) um den Wert auf. Im Pausenmenü sind sie ausgegraut.
- Gift gibt es im Kampfsystem noch nicht, daher kein Gegengift in diesem Schritt (meine Wahl).
- Beute: Jeder besiegte normale Gegner lässt mit 50 % einen Monsterkern seines Rangs fallen (D oder C; Kampfende-
  Meldung nennt ihn). Bosse immer einen. Der Kern-Auftrag verlangt Kerne (D); C-Kerne zählen dafür mit.
- Icons aus dem Grafik-Repo: Sammelgut aus `welt/sammeln/icons_sammeln.png` (über `sammeln.json`), übrige aus
  `icons/` (`essen_kraeuter`, `traenke`, `beute`, über `icons.json`).

## Läden

Innenräume (neuer Hintergrund je Laden, im Stil von innen_haus) mit Ladeninhaber hinter einem Tresen. Tür vorne
wie beim Kartografen; Gebäudetür im Dorf öffnet sich wie bei der Gilde.

| Gebäude (Raum) | Inhaber | verkauft | kauft an | Besonderes |
|---|---|---|---|---|
| Bäckerei (dorf_02) → `laden_baeckerei` | Bäcker Jonte | Brot, Apfel | Weizen, Beeren | „Backen lassen“: 3 Weizen + 2 Silber → 1 Brot |
| Alchemie (dorf_03) → `laden_alchemie` | Alchemistin (neu, Name: Veska) | Heil-, Manatrank | Heilkraut, Pilze, Leuchtpilze, Manablumen, Beeren | – |
| Waffenschmiede (dorf_01) → `laden_waffen` | Schmied Borin (zieht von draußen nach drinnen um; draußen arbeitet dann ein Geselle) | Kurzschwert, Eichenstab, Streitkolben, Lederharnisch, Siegelring (C) | eigene Ausrüstung (nicht angelegt) | – |

- Ankauf: Ein Laden kauft nur seine Warengruppe. Die Händlerin am Marktstand (draußen, nicht betretbar) kauft
  alles Sammelbare und Monsterkerne – zu 70 % des Verkaufswerts. Monsterkerne kauft auch Gildenmeisterin Hadra
  zum vollen Wert.
- Ausrüstungspreise (meine Wahl): D 40, C 90 Silber; Ankauf zum halben Preis.
- Ladenfenster: Kopf „Kaufen / Verkaufen / (Backen lassen) / Zurück“, dann Liste mit Icon, Name, Preis, Bestand;
  Silberstand oben. Baut auf dem vorhandenen ChoiceMenu und den Holzrahmen aus `ui/` auf. Kaufen mit Mengenwahl
  ist nicht nötig: jeder Druck kauft ein Stück, das Fenster bleibt offen.

## Auftragsbrett

- Entität `auftragsbrett` in der Gildenhalle (Grafik `welt/dorf/gildenbrett.png`, animiert). [W] öffnet es.
- Bis zu 3 Angebote, höchstens 3 angenommene Aufträge gleichzeitig. Angebote werden aus Vorlagen gewürfelt
  (fester Seed aus einem Zähler im Spielstand, damit Tests deterministisch bleiben).
- Neu gewürfelt wird beim Rasten an einem Schrein/Rastort (nur offene Angebote; angenommene bleiben).
- Auftragsarten:
  - **Liefern** (Dorfbewohner): „Bäcker Jonte braucht 5 Weizen“, „Ilwen braucht 3 Heilkraut“,
    „Veska braucht 4 Waldpilze“, „Fennick will 6 Waldbeeren für Beerenwein“, „Rufus will 2 Brote“.
  - **Jagen** (Gilde): „Besiegt 3 Goblins“, „2 Grünschleime“, „2 Riesenspinnen im Wald“.
  - **Kerne** (Gilde): „Bringt 3 Monsterkerne (D)“.
- Abgabe am Brett: Liefern und Kerne nehmen die Gegenstände aus dem Vorrat; Jagen zählt Siege ab Annahme.
- Lohn in Silber nach Aufwand (Liefern: ca. 3× Verkaufswert, Jagen 10 je Gegner, Kerne 20 je Kern), bei
  Gilden-Aufträgen abzüglich 10 % Blutsteuer, die im Text genannt wird. Banner `ui/banner_auftrag_erledigt.png`.

## Waldstück

- Neue Räume `wald_01..wald_03` rechts von kornfeld_08 (kornfeld_08 bekommt Ausgang R2). Gebiet `kornburg`
  (die Karte des Kartografen deckt es mit ab), neues Biom `wald` mit eigener Tönung in `stimmung.json`
  (dunkler und grüner als kornfeld), Hintergrund aus `dorf_nacht` mit der Waldebene vorn, Terrain `wiese`.
- Bäume, Tannen, Büsche (`props/`), Ast-Plattformen (`plattformen.png`: ast) für etwas Höhe.
- Gegner: Riesenspinnen, Grünschleime, Goblins; die Lichtung in wald_03 bewacht eine Gruppe aus zwei
  Riesenspinnen (kein Boss – der Blutwolf-Alpha bleibt der Dungeon-Boss).
- wald_03 endet an einer Lichtung (Sackgasse mit Lohn: viele Sammelstellen, ein Leuchtpilz-Ring, eine Truhe).
  Weiter geht es dort später.

## Sammelstellen

- Grafik: `welt/sammeln/<art>.png` aus dem Grafik-Repo (20×32-Zellen; Zeilen idle 6, ernten 6, leer 1,
  nachwachsen 5; 8 fps; Bodenpunkt y 31). Leuchtende Arten bekommen ein kleines Licht.
- Entität `sammeln <art> x,y [anzahl=n]`. In diesem Schritt genutzt: weizen, apfel (Kornfelder);
  beeren_rot, blaubeeren, pilz, leuchtpilz, heilkraut, manablume (Wald).
- Davorstellen und [W] drücken erntet: Ernte-Animation, dann Meldung „+2 Waldbeeren“; die Stelle bleibt leer.
- Merker `geerntet:<raum>:<index>`; Rasten löscht diese Merker. Betritt man den Raum danach, spielt die Stelle
  einmal „nachwachsen“ und steht wieder voll da.
- Verteilung: je Kornfeld 1–2 Weizenstellen, je Waldraum 2–4 Stellen.

## Gegner kehren beim Rasten zurück (Entscheidung des Nutzers: A)

- Rasten an einem Schrein oder Rastort löscht die Merker `defeated:<raum>:<i>` aller normalen Gegner in Räumen,
  die nicht zu einem Dungeon gehören. Bosse und Dungeon-Gegner bleiben besiegt.
- Damit bleiben Jagd- und Kern-Aufträge dauerhaft erfüllbar; alte Spielstände bekommen ihre Kornfeld-Gegner nach
  dem nächsten Rasten zurück.

## Gegenstand im Kampf und im Pausenmenü

- Kampf: „Gegenstand“ wird freigeschaltet, sobald es einen benutzbaren Vorrat gibt. Liste mit Anzahl, dann
  Zielwahl (eigene Gruppe). Kostet den Zug.
- Pausenmenü bekommt „Vorräte“: gleiche Liste, Zielwahl, wirkt sofort.

## Grafik

- Alles, was das Grafik-Repo hat, wird unverändert über `tools/import_cosy.py` übernommen.
- Der Freund des Nutzers ergänzt gerade Grafik (mindestens Beeren und Weizen). Was danach noch fehlt
  (vermutlich Ladeninnenräume, Sammelpflanzen im abgeernteten Zustand), zeichne ich in `tools/art/` im Stil der
  vorhandenen Innenräume. Vor dem Bauen prüfe ich, was neu im Grafik-Repo ist.

## Dem Bauenden überlassen

- Genaue Raumaufteilung, Positionen, Dialogtexte der neuen Figuren (im Ton der vorhandenen, passend zur Bibel).
- Aufbau des Ladenfensters im Detail, solange es mit Tastatur bedienbar ist wie die übrigen Menüs.
- Testaufteilung (TDD, `tools/run_tests.sh` grün vor jedem Push, direkt auf main).
