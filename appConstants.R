# constants for every App
appName <- 'bank'
appTitle <- 'Kontoentwicklung'
app_id <- 'eu.ownyourdata.bank'

appFields <- c('date', 'value', 'description')
appFieldTypes <- c('date', 'double', 'string')
appFieldInits <- c('today', 'zero', 'empty')
appFieldKey <- 'date'
appFieldsDisplay <- c('Datum', 'Betrag', 'Beschreibung')

# Version information
currVersion <- "0.5.0"
verHistory <- data.frame(rbind(
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
