# global constants available to the app
# last update:2016-12-28

# constants required for every App
appName <- 'bank'
appTitle <- 'Kontoentwicklung'
app_id <- 'eu.ownyourdata.bank'

# definition of data structure
currRepoSelect <- ''
appRepos <- list(Kontobewegungen = 'eu.ownyourdata.bank',
                 Verlauf         = 'eu.ownyourdata.bank.log')
appStruct <- list(
        Kontobewegungen = list(
                fields      = c('date', 'value', 'description'),
                fieldKey    = 'date',
                fieldTypes  = c('date', 'double', 'string'),
                fieldInits  = c('empty', 'zero', 'empty'),
                fieldTitles = c('Datum', 'Betrag', 'Beschreibung'),
                fieldWidths = c(100, 80, 600)),
        Verlauf = list(
                fields      = c('date', 'description'),
                fieldKey    = 'date',
                fieldTypes  = c('date', 'string'),
                fieldInits  = c('empty', 'empty'),
                fieldTitles = c('Datum', 'Text'),
                fieldWidths = c(150, 450)))

# Version information
currVersion <- "0.5.3"
verHistory <- data.frame(rbind(
        c(version = "0.5.3",
          text    = "Verwendung von Listennamen in neuem Datentresor"),
        c(version = "0.5.2",
          text    = "Erinnerung zum Hochladen des Kontoauszugs durch Kalendereintrag"),
        c(version = "0.5.1",
          text    = "überarbeitete Chart-Visualisierung"),
        c(version = "0.5.0",
          text    = "dynamischer Kontoimport, UI Update (OYD Template)"),
        c(version = "0.4.0",
          text    = "Kontoimport für IngDiBa und Erste Group hinzugefügt"),
        c(version = "0.3.0",
          text    = "erstes Release")
))

# App specific constants
Einnahmen <- c(descFilter='',
               valFilter='>',
               valFilterValue='0')
Ausgaben <- c(descFilter='',
              valFilter='<',
              valFilterValue='0')
Bankomat <- c(descFilter='bankomat',
              valFilter='not',
              valFilterValue='')
Supermärkte <- c(descFilter='Spar|Merkur|Billa|Hofer',
                 valFilter='not',
                 valFilterValue='')
staticGroupConfigList <- data.frame(rbind(Einnahmen, Ausgaben, Bankomat, Supermärkte))
staticGroupConfigUiList <- rownames(staticGroupConfigList)

grpConfigList <- data.frame()
grpConfigUiList <- vector()
