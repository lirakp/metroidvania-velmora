# Der Südweg nach Eichenmark – Entwurf

Stand 2026-11-26. Nächster Story-Abschnitt nach Kornburg und dem Blut-Dungeon. Rund 50 neue Räume.

## Absicht

Das Spiel soll deutlich größer werden (Nutzer: „ca. 50 Räume … um das Spiel schon etwas größer zu machen“), mit mehr
Wald, Landschaft und Dungeons. Wir stehen am Anfang des Spiels: Der Abschnitt ist ein früher Schritt auf dem langen Weg
zum König der Ewigkeit, nicht die Spielmitte. Die Fee der zeitlosen Wünsche kommt ausdrücklich **noch nicht** vor.

Erzählerischer Faden (meine Wahl, folgt dem Intro): Hadra sagt im Intro „Im Süden hat man den Dämonenkönig gesehen“.
Nach dem Blut-Dungeon schickt die Gilde die Geschwister südwärts. Südlich von Hohenmark liegt laut Bibel **Eichenmark**
(Mitte Velmoras, dichte Wälder, Holz und Jagd). Am Ende des Abschnitts finden sie eine erste echte Spur des
Dämonenkönigs – ohne Kampf gegen ihn.

## Ziele

1. Etwa 50 neue Räume in vier Teilen:
   - **Südweg** (~8): Hügel, Felder, Hohlweg, ein Fuhrleute-Rastplatz (Rastort zum Speichern).
   - **Eichenmark-Wald** (~16): dichter Wald, viele Wege nach hinten (hohle Bäume, Höhleneingänge, Durchgänge),
     Sammelstellen, darin das **Baumkronen-Dorf** (~4 der 16): Holzfäller-Dorf oben in den Bäumen.
   - **Wurzelhöhle** (~10): Höhlensystem unter dem Wald (kein Einweg-Dungeon), verbindet Waldteile, führt zum Dorn-Dungeon.
   - **Dorn-Dungeon** (~16): Labyrinth wie der Blut-Dungeon (Einweg-Schwelle, Rastort innen, Boss). Rang D–C.
2. **Wandsprung** (Entscheidung des Nutzers): neue Bewegungsfähigkeit als Belohnung des Dorn-Bosses. An Wänden
   rutschen und von ihnen abspringen; dadurch Wege nach oben.
3. **Abschnitte, die erst mit Wandsprung aufgehen** (Nutzer: „Abschnitte, die man nur durch den Weg nach oben
   freischaltet … versteckte Pfade“): in den neuen Gebieten und einige wenige in Kornburg und im Blut-Dungeon
   (Beute, Abkürzungen), damit sich die Rückkehr lohnt.
4. **Baumkronen-Dorf** (Entscheidung des Nutzers: Variante A): erreichbar über einen **versteckten Weg nach oben mit
   Leitern und Seilen** – schwer zu finden, aber **ohne** Wandsprung. Es ist Rastplatz und Laden auf dem Weg.
   Mit Wandsprung kommen später eine Abkürzung und ein Geheimversteck im Dorf dazu.
5. **Leitern und Seile** als neue Kletter-Kacheln (Grafik `level/leiter.png`: leiter, seil, kette).
6. **Item-Benutz-Animationen** aus dem Grafik-Repo (`characters/held/items/`): Essen/Trinken beim Benutzen von
   Vorräten (Feld und Kampf), Pflücken/Sicheln/Aufheben beim Ernten. Im Kampf ersetzt die Animation die bisherige
   Angriffsanimation beim Gegenstand (offener Punkt aus dem letzten Review).
7. **Innenräume aus dem Grafik-Repo** (`level/innenraeume/`) ersetzen die selbst gezeichneten Ladenräume, wo es ein
   passendes Gegenstück gibt (CLAUDE.md: Grafik unverändert übernehmen); neue Innenräume (Dorf) nutzen sie ebenfalls.
8. **Neue Gegner** aus dem Bestiarium der Bibel (Lebensraum Wald/Höhle/Hügel, Rang D–C), Sprites aus
   `monster/sprites/`; ein Dorn-Boss (Rang B, wie der Blutwolf-Alpha ein starker normaler Gegner mit Boss-Merkmal).

## Nicht-Ziele

- Keine Fee, kein Nebelhain, keine Überfahrt nach Ascheron, keine Enden, kein Kampf gegen den Dämonenkönig.
- Kein neues Kampfsystem, keine neuen Ränge über C in Läden.
- Keine Tageszeit.

## Anti-Ziele

- Der Hauptweg darf nie Wandsprung voraussetzen, bevor man ihn hat; kein Festsitzen (Einweg-Dungeon muss immer
  lösbar sein, wie beim Blut-Dungeon).
- Räume dürfen nicht wie Kopien wirken: jeder Raum hat etwas Eigenes (Form, Weg nach hinten, Sammelstelle, Gegner,
  Aussicht, kleines Rätsel mit dem Geschwister).
- Versteckte Pfade müssen fair sein: ein Hinweis in der Welt (Lücke im Laub, Seilende, anderes Gras), keine
  unsichtbaren Wände, durch die man zufällig fallen muss.

## Rahmen

- CLAUDE.md: direkt auf main, Tests grün vor jedem Push, Räume nur über `tools/gen_rooms.py`, Grafik unverändert über
  `tools/import_cosy.py`, Spieltexte Deutsch, Inhalte passend zur Bibel.
- Raumformat bleibt 30×17 Kacheln. Ausgänge oben/unten (T/B) unterstützt der Raumwechsel bereits; senkrechte
  Abschnitte entstehen aus übereinander liegenden Räumen.
- Türen nach hinten/vorne (`richtung=hinten|vorne`) erscheinen auf der Karte als Vogelperspektive (hinten = oben).

## Ansätze

- **Oberwelt von Hand (gewählt):** Südweg, Wald, Dorf und Höhle werden Raum für Raum in `gen_rooms.py` entworfen –
  volle Kontrolle über versteckte Pfade und Wandsprung-Stellen.
- **Dungeon über Grundriss (gewählt):** Der Dorn-Dungeon entsteht wie der Blut-Dungeon aus einem Raster
  (Vogelperspektive, seitliche Ausgänge und Öffnungen nach hinten), Karte inklusive.
- **Zufällig erzeugte Räume (verworfen):** Versteckte Pfade lassen sich nicht gezielt setzen, Räume wirken beliebig.

## Eckpunkte (meine Wahl, korrigierbar)

- **Zugang:** Der Südweg beginnt am Stadttor im Süden Kornburgs (Tür „nach vorne“ = Süden auf der Karte, z. B. aus
  stadt_03). Er öffnet sich erst, wenn der Blut-Dungeon gelöst ist (Wache lässt durch, Hadra gibt den Auftrag).
- **Gebiete und Karten:** neue Gebiete `suedweg`, `eichenmark`, `wurzelhoehle`, `dorndungeon`. Im Baumkronen-Dorf
  verkauft ein Kartograf die Karten von Südweg/Eichenmark/Höhle; die Dungeon-Karte liegt im Dungeon (wie beim
  Blut-Dungeon).
- **Dorf:** Name im Ton der Bibel (z. B. „Kronhain“), Rastort mit Schrein (Speichern, Plakette), Händler (Sammelgut,
  Vorräte), ein paar arbeitende Bewohner (Holzfäller, Gärtnerin …), Dialoge über Eichenmark und das Gerücht aus dem
  Süden.
- **Wandsprung-Zahlen:** Rutschen an der Wand mit gedrosselter Fallgeschwindigkeit, Absprung schräg weg von der Wand;
  damit überwindet man einen senkrechten Schacht beliebiger Höhe zwischen zwei Wänden und eine einzelne Wand bis
  ca. 4 Kacheln über dem normalen Sprung. Genaue Werte legt der Bauende fest, der Erreichbarkeitstest bildet sie ab.
- **Erreichbarkeitstest:** kennt Leitern/Seile und Wandsprung. Für jeden Raum gilt: Hauptpunkte ohne Wandsprung
  erreichbar; als „wandsprung“ markierte Punkte nur mit Wandsprung.
- **Spur des Dämonenkönigs:** nach dem Dorn-Boss eine Szene (verbrannte Lichtung, Klauenspuren, ein sterbender Späher
  oder eine Botschaft) – Text im Ton der Bibel, Lust/Gewalt gedämpft.

## Dem Bauenden überlassen

- Genaue Raumaufteilung, Namen der Räume und Orte, Gegnerauswahl aus dem Bestiarium (passend zu Lebensraum und Rang),
  Dialogtexte, Platzierung der Sammelstellen und Geheimnisse.
- Ob einzelne Innenräume aus dem Grafik-Repo die bestehenden (Gilde, Kartograf) ersetzen.
- Technische Umsetzung von Kletter-Kacheln und Wandsprung im Spieler.
