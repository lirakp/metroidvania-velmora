# Blutmond (Arbeitstitel) – Spiel-Design

Stand: 2026-11-23 · Quelle der Welt: „Bibel der Welt“ (Claude-Docs-Artifact) + Karten von Ascheron und Velmora.
Markierung: **[Team]** = von euch entschieden · **[Vorschlag]** = meine Entscheidung, korrigierbar.

## 1. Absicht

Ein 2D-Pixel-Art-Metroidvania, in dem man die eigene Welt (Velmora) erkundet. Hobbyprojekt, als Windows-Programm über GitHub herunterladbar. **[Team]**
Hollow Knight dient als Vorbild für Aufbau und Techniken (Räume, Karten kaufen/finden, Fähigkeiten öffnen Wege), nicht für das Grafikniveau. **[Team]**
Kämpfe sind rundenbasiert auf einem eigenen Kampfplatz. **[Team]**

### Ziele
- Die Welt der Bibel spielbar machen: Orte, Fraktionen, Tribut, Dungeon-Regeln, Monster.
- Ein vollständiger, spielbarer Ausschnitt (Vertical Slice) zuerst, dann wachsen.
- Düstere Stimmung, ab 18. **[Team]**

### Nicht-Ziele
- Kein Hollow-Knight-Grafikniveau, keine handgezeichnete Animation. **[Team]**
- Keine Lust-/Sex-Inhalte als Fokus; Lust nur als abgeschwächte Todsünde (z. B. Tribut). **[Team]**
- Kein Verkauf, kein Multiplayer, keine anderen Plattformen als Windows. **[Vorschlag]**

### Anti-Ziele (wäre ein Fehlschlag, auch wenn es läuft)
- Die Welt fühlt sich wie generische Fantasy an, statt wie die Bibel.
- Kampf und Erkundung fühlen sich wie zwei getrennte Spiele an.
- Das Projekt wird so groß, dass nie etwas Spielbares fertig wird.

## 2. Ansätze (Technik)

| Ansatz | Vorteile | Nachteile |
|---|---|---|
| **Godot 4 (GDScript)** – gewählt | Kostenlos, Räume = Szenen (Laden pro Raum eingebaut), TileMaps, direkter Windows-Export, Textdateien (gut versionierbar) | Weniger fertige Assets als Unity |
| Unity | Riesiger Asset-Store | Lizenzregeln, schwer, viel Binärkram im Repo |
| Eigener Stack (z. B. Phaser + Electron) | Volle Kontrolle | Raumladen, Kamera, Export alles selbst bauen |

Entscheidung: **Godot 4** (aktuelle stabile 4.x). **[Vorschlag, vom Team an mich übergeben]**

## 3. Geschichte und Rahmen

- **Zeit:** Eine Zeit, die in der Zeitleiste nicht steht. Der König der Ewigkeit setzt auf Velmora seinen Schlachtplan durch: Der Dämonenkönig (SS) ist in der Welt, der Blutmond ist dauerhaft, alle Physischen Dungeons sind Blut-Dungeons, der Schrei beim Störenfried-Bruch wird täglich länger. **[Team]**
- **Ziel:** Den König der Ewigkeit besiegen. Das braucht viele Schritte, wie in der Bibel (u. a. Dämonenkönig zuerst töten → König fällt von SS+ auf SS; endgültiger Tod nur im Erinnerungs-Dungeon mit seinen Erinnerungen an die Tochter). Diese Schritte bilden das Rückgrat des Metroidvania. **[Team]**
- **Figuren:** Warschick (m) oder Lira (w), Geschwister, beide Halbelfen (Mensch + Elf). Die nicht gewählte Figur begleitet als Gefährte durch Tutorial und Story. **[Team]**
- **Drei Enden:** **[Team]**
  1. Beide Könige selbst besiegen.
  2. Das Geschwister opfern, um nicht selbst gegen den König der Ewigkeit oder den Dämonenkönig kämpfen zu müssen.
  3. Pakt mit der Verlorenen Königin: Sie kämpft mit gegen beide Könige und erfährt dabei ihre Verwandtschaft.
- **Startort:** Hohenmark (Kornburg) im Norden Velmoras. Nah an der Fähre nach Ascheron, Kornkammer = viele Menschen = früh sichtbare Folgen des Blutmonds. **[Vorschlag]**
- **Offen:** siehe Abschnitt 11.

## 4. Erkundung (Metroidvania)

- **Räume:** Jeder Raum ist eine eigene Godot-Szene; beim Wechsel über einen Übergang wird nur der neue Raum geladen. **[Team-Prinzip, Umsetzung Vorschlag]**
- **Karte:** Unbekannte Gebiete sind leer. Gebietskarten kauft man beim Kartografen (Konsortium-Händler) oder findet sie; erkundete Räume trägt man an Rastorten ein. **[Team: kaufen/finden; Eintragen an Rastorten Vorschlag]**
- **Bewegungsfähigkeiten aus den Kampfstilen** (öffnen neue Wege) **[Vorschlag]**:
  | Fähigkeit | Herkunft | Funktion |
  |---|---|---|
  | Federfall | Windfalken | Doppelsprung, Sturz abbremsen |
  | Felssprung | Glutpirscher | Dash nach vorn, durchbricht brüchigen Stein |
  | Lianenzug | Schattenwürmer | Greifhaken an Ranken-Punkten |
  | Spiegeleis | Hydroforellen | Wasser/Wasserfälle gefrieren → begehbar |
  | Nebelhaut | Brüllkröten | Schleichen: Gegner bemerken einen nicht, Gas-/Geruchsfallen |
  | Blitzschritt | Faultiere | Sehr schneller Sprint über einstürzende Böden |
  | Lichtfunke/Bannlicht | Kirche (Licht) | Erinnerungs-/Schattenbarrieren auflösen |
- **Geschwister-Befehle:** Man kann das Geschwister zu markierten Punkten im Raum schicken (Druckplatte halten, zweiten Hebel gleichzeitig ziehen, Kette sichern). Außerhalb von Story-Abschnitten ist man immer zu zweit. **[Team]**
- **Allein-Abschnitte:** An bestimmten Story-Punkten ist man allein (Geschwister entführt, in Erinnerungsschleife o. ä.). Dann gibt es keine Geschwister-Befehle und im Kampf nur eine Figur. **[Team]**

## 5. Dungeons

- Dungeon-Typen nach Bibel: Physisch (wegen Blutmond fast alle Blut-Dungeons: viele Gegner, kaum Rastorte), Dorn (Fallen alle paar Schritte, viel Beute), Erinnerung (tarnt sich als D/C, Endrätsel, Schleifen). **[Bibel]**
- **Einweg-Schwelle:** Beim Betreten verschwindet der Ausgang, raus nur durch Endboss/Endrätsel oder Tod. **[Bibel]**
- **Wiederbetreten:** Ab Spielmitte gibt es über eine Quest der Fee der zeitlosen Wünsche ein Item, mit dem man gelöste Dungeons erneut betreten kann (für verpasste Wege/Beute). Preis der Fee: eine Erinnerung (z. B. ein Eintrag im Tagebuch/Bestiarium wird gelöscht). **[Team: Item + Quest; Preis Vorschlag]**
- **Erinnerungsschleifen** als Rätselräume: aktive Schleife = eingreifen, inaktive = still stehen bleiben (Eingabe-Disziplin); Störenfried-Bruch = Lähmung + Schaden. **[Vorschlag nach Bibel]**

## 6. Kampf

### Auslösen **[Team, Detail Vorschlag]**
- Gegner laufen sichtbar durch die Räume und haben eigene Muster.
- **Erstschlag (wie Expedition 33):** Trifft man einen Gegner mit dem Feldschlag, beginnt der Kampf mit Vorteil: Gegner betäubt in Runde 1, Spieler handelt zuerst.
- **Überfall:** Berührt der Gegner einen zuerst, beginnt der Gegner.
- Mit Nebelhaut kann man Gegnern ausweichen.

### Kampfplatz **[Team]**
- Eigener Kampfbildschirm (Seitenansicht), Hintergrund passend zum Raum. Links die zwei Geschwister, rechts 1–4 Gegner.

### Ablauf **[Vorschlag]**
- **Zugreihenfolge:** Leiste mit den nächsten Zügen, sortiert nach Tempo.
- **Aktionen:** Angriff · Technik (Kampfstil) · Zauber · Gegenstand · Verteidigen · Fliehen (nicht in Dungeons/Bosskämpfen).
- **Zwei Manaflüsse:** Halbelfen haben einen C-Fluss (Mensch) und einen S-Fluss (Elf), als zwei getrennte Mana-Leisten. Ein Zauber aus einem Fluss nutzt dessen Rang; ein kombinierter Zauber richtet sich nach dem schwächeren Fluss (Bibel). Siegelringe und später evtl. das Dornen-Tattoo heben den schwächeren Fluss an und schalten höhere Zauberstufen frei.
- **Elemente:** Neun Elemente, Schwächen aus dem Bestiarium; Gegensätze ergeben Bruchklang (stark, aber Rückschlag auf den Zaubernden).
- **Tribut:** Ausrüstung ab Rang A gibt starke Boni und fordert pro Runde oder pro Einsatz einen Preis: Blut = LP, Körperwärme = Status „Unterkühlt“ (Tempo sinkt), Ausdauer = weniger Technikpunkte, Mana = Mana-Leiste, Haut/Fleisch = Max-LP sinken bis zur Rast, Sinne = Treffergenauigkeit, Gift = Gift selbst nehmen oder Wahnvorstellung. Zwei-Attribute-Regel: ab drei verschiedenen Tribut-Arten steigen die Kosten deutlich. Berserker-Gegner nach Bibel.
- **Ränge:** D–SS als Stufenbänder für Spieler, Gegner und Ausrüstung. Werte (LP, Angriff, Abwehr, Tempo, Mana C/S) lege ich in einer Datentabelle fest und balanciere sie.
- **Niederlage:** Siehe Abschnitt 7.

## 7. Speichern und Tod **[Team, Details Vorschlag]**

- Speichern nur in Gildenhallen oder an Dungeon-Rastorten.
- Dort legt man eine Seelenplakette ab; nach dem Tod erwacht man an der zuletzt benutzten Plakette.
- Zusätzliche Plaketten erbeutet man von toten Abenteurern; maximal 5 Rückkehrpunkte. Eine neue, darüber hinaus, ersetzt die älteste. **[Vorschlag]**
- Strafe beim Tod: Die Gilde bucht sofort 10 % Blutsteuer auf euer Geld (Bibel: „die schnellste Abteilung der Gilde“). Stirbt man im Dungeon, läuft dessen Frist weiter. **[Vorschlag]**

## 8. Grafik, Ton, Inhalt

- **Auflösung:** 480 × 270 Pixel intern, ganzzahlig auf 1920 × 1080 hochskaliert. Kacheln 16 × 16, Figuren etwa 16 × 32. **[Vorschlag]**
- **Palette:** Eigene, düstere Palette mit 32 Farben: kalte Grau-, Moos- und Schieferblau-Töne, Blutmond-Rot als einzige starke Akzentfarbe, warmes Gold nur für Licht, Kirche und Beute. **[Vorschlag]**
- **Figurendesign:** Warschick und Lira mit spitzen Halbelfenohren, gleiche Mantelfarbe als Geschwister-Merkmal; Designvorschläge folgen als Bild. **[Vorschlag]**
- **Grafik-Erstellung:** Platzhalter-Pixelart erzeuge ich per Code (einheitlich, aber schlicht). Für schönere Grafik später eigene Zeichnungen oder freie Asset-Pakete mit passender Lizenz. **[Vorschlag]**
- **Ton:** Für den Anfang freie Sounds und Musik (CC0) oder keine. **[Vorschlag]**
- **Sprache:** Deutsch. **[Vorschlag]**
- **Inhalt:** ab 18; Gewalt und Horror der Erinnerungs-Dungeons ja, Sklaverei als Teil der Welt ja, Lust nur abgeschwächt. **[Team]**

## 9. Erster Meilenstein: Vertical Slice **[Vorschlag]**

Ein kleiner, aber vollständiger Ausschnitt, der alle Kernsysteme einmal zeigt:
- Startgebiet bei Kornburg (ca. 12–15 Räume) + ein Blut-Dungeon (ca. 8–10 Räume) mit Endboss.
- Figurenwahl Warschick/Lira, Geschwister folgt und lässt sich zu Punkten schicken (ein Rätsel).
- Eine Bewegungsfähigkeit (Federfall), die einen vorher unerreichbaren Weg öffnet.
- Rundenkampf mit Erstschlag/Überfall, 4–6 Gegnertypen aus dem Bestiarium (Rang D–C), ein Boss.
- Gildenhalle mit Seelenplakette, ein Dungeon-Rastort, Tod und Wiedererwachen, eine gefundene zweite Plakette.
- Kartenkauf beim Kartografen, Kartenansicht.
- Ein Ausrüstungsstück mit Tribut (zum Zeigen der Mechanik).
- Speichern/Laden, Hauptmenü, Windows-Export.

## 10. Repository und Veröffentlichung **[Vorschlag]**

- Das Git-Repo `lirakp/metroidvania-velmora`, Godot-Projekt im Ordner `game/`, Dokumente in `docs/`.
- Windows-Build als ZIP über GitHub Releases. Repo ist angebunden.
- Spieldaten (Gegner, Zauber, Ausrüstung) als Tabellen (JSON/CSV) aus der Bibel übernommen, damit man Werte ohne Code ändern kann.

## 11. Offene Punkte für das Team

1. **Der Graue Brunnen liegt laut Bibel auf Ascheron** (Grenze zu den Erstarrten Landen), und nur dort kann der König der Ewigkeit endgültig sterben. Das Spiel spielt auf Velmora. Möglichkeiten: (a) Das Finale führt per Fähre nach Ascheron, (b) die Fee lässt den Erinnerungs-Dungeon auf Velmora erscheinen (Dungeons entstehen überall), (c) es gibt einen zweiten Erinnerungs-Dungeon mit diesen Erinnerungen. Mein Vorschlag: (b), es passt zur Regel „Dungeons entstehen überall und zufällig“ und hält das Spiel auf einem Kontinent.
2. Später (nicht für den Slice nötig): Reihenfolge der großen Story-Schritte bis zum König.

## 12. Was dem Bauenden überlassen ist

Konkrete Zahlenwerte und Balancing, Raum-Layouts, Gegner-KI-Muster, UI-Gestaltung im Rahmen der Palette, Code-Aufbau in Godot, Platzhalter-Grafik und -Sound.
