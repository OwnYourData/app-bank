# Kontoentwicklung

Mit der OwnYourData Kontoentwicklungs-App können eigene Kontodaten gesammelt und ausgewertet werden.  


## Installation

Die App kann gratis über den offiziellen OwnYourData SAM (Store for Algorithms) installiert werden. Wähle dazu in der PIA App-Liste "Plugin installieren" und wähle "Kontoentwicklung" (ID: eu.ownyourdata.bank) aus.

Die Kontoentwicklungs-App benötigt das Shiny-Host-Service (ebenfalls verfügbar am OwnYourData SAM, ID: eu.ownyourdata.shinyhost) und Docker installiert.


## Verwendung

Banken bieten oft nur eine begrenzte Anzahl an gespeicherten Buchungszeilen. Mit der Kontoentwicklungs-App erhalten sie eine unbeschränkte Historie über alle Einnahmen und Ausgaben. Diese Historie kann sich auch über mehrere Konten erstrecken und dadurch kann die Vermögensentwicklung über die Zeit dargestellt werden. Das umfasst folgende Funktionen:

* Importfunktion für diese Banken: Bawag/Easybank, Erste Group, ING-DiBa
* Darstellung der Kontoentwicklung in Form eines Liniendiagrams (ähnlich zu Aktienkursen)
* Einschränkung der Darstellung auf ein bestimmtes Zeitfenster
* monatliches Erinnerungsmail zum Upload des Kontoexports


## Für Entwickler  

Diese App wurde in [R](https://cran.r-project.org/) entwickelt und verwendet [Shiny](http://shiny.rstudio.com/). Zur Ausführung wird entweder das OwnYourData Shiny Service benötigt (siehe oben: Installation) oder es existiert ein bereits installierter Shiny Server. Wird ein eigener Shiny Server betrieben, kann in der PIA App-Liste mit "Register a new Plugin" das Manifest base64-encodiert hinzugefügt werden (angegeben am Beginn der Datei `server.R`) und in der App unter Konfiguration müssen die Parameter URL, App-Key und App-Secret selbst gesetzt werden.


## Verbessere die Kontoentwicklungs-App

1. Fork it!
2. erstelle einen Feature Branch: `git checkout -b my-new-feature`
3. Commit deine Änderungen: `git commit -am 'Add some feature'`
4. Push in den Branch: `git push origin my-new-feature`
5. Sende einen Pull Request

## Lizenz

MIT Lizenz 2016 - Own Your Data