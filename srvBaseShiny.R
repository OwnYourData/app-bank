# basic reactive functions for accessing PIA
# last update:2016-08-24

currApp <- reactive({
        app <- vector()
        piaMsg <- ''
        pia_url <- input$store$pia_url
        app_key <- input$store$app_key
        app_secret <- input$store$app_secret
        if(is.null(pia_url) |
           is.null(app_key) | 
           is.null(app_secret)) {
                piaMsg <- 'Es sind keine Verbindungsdaten eingerichtet. Wähle im Menü rechts oben "Konfiguration" und trage die Verbindungsdaten zu deiner PIA ein!'
        } else {
                if((nchar(pia_url) > 0) & 
                   (nchar(app_key) > 0) & 
                   (nchar(app_secret) > 0)) {
                        app <- setupApp(pia_url, app_key, app_secret)
                        if(is.na(app[['token']])){
                                piaMsg <- 'Die angegebenen Verbindungsdaten zur PIA sind nicht korrekt oder die PIA kann derzeit nicht erreicht werden. Öffne deine PIA und überprüfe hier im Menü rechts oben "Konfiguration" die PIA-Verbindungsdaten.'
                        }
                } else {
                        piaMsg <- 'Es sind keine oder nur unvollständige Verbindungsdaten vorhanden. Wähle im Menü rechts oben "Konfiguration" und überprüfe die Verbindungsdaten zu deiner PIA!'
                }
        }
        if(nchar(piaMsg) > 0){
                createAlert(session, 'piaStatus', alertId = 'myPiaStatus',
                            style = 'danger', append = FALSE,
                            title = 'PIA Verbindung',
                            content = piaMsg)
                app <- vector()
        } else {
                closeAlert(session, 'piaStatus')
        }
        app
})

currData <- reactive({
        app <- currApp()
        if(length(app) > 0) {
                url <- itemsUrl(app[['url']], 
                                paste0(app[['app_key']]))
                piaData <- readItems(app, url)
        } else {
                piaData <- data.frame()
        }
        piaData
})

saveDateItem <- function(app, date, url, value){
        if(!is.null(date) & 
           (length(all.equal(app, logical(0)))>1) &
           !is.na(app[['token']])){
                piaData <- currData()
                existData <- piaData[piaData$date == date, ]
                existData <- existData[complete.cases(existData), ]
                data <- list(date=date, 
                             value=value)
                if (nrow(existData) > 0) {
                        if(is.na(value) | is.null(value) | value == 'NA'){
                                deleteItem(app, url, existData$id)
                        } else {
                                updateItem(app, url, data, existData$id)
                        }
                } else {
                        if(!is.na(value) & !is.null(value) & value != 'NA' & nchar(as.character(value))>2){
                                writeItem(app, url, data)
                        }
                }
        }                
}
