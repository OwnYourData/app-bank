# basic reactive functions for accessing PIA
# last update: 2016-10-29

currApp <- reactive({
        input$p2next
        input$disconnectPIA
        app <- vector()
        piaMsg <- ''
        pia_url <- piaUrl
        app_key <- appKey
        app_secret <- appSecret
        if(is.null(pia_url) |
           is.null(app_key) | 
           is.null(app_secret)) {
                piaMsg <- paste0('Es sind keine oder nur unvollständige Verbindungsdaten vorhanden. Wähle im Menü ',
                                 icon('gear'),
                                 ' rechts oben "Konfiguration" und trage die Verbindungsdaten zu deinem Datentresor ein!')
        } else {
                if((nchar(pia_url) > 0) & 
                   (nchar(app_key) > 0) & 
                   (nchar(app_secret) > 0)) {
                        app <- setupApp(pia_url, app_key, app_secret)
                        if(length(app) == 0){
                                piaMsg <- paste0('Die angegebenen Verbindungsdaten zum Datentresor sind nicht korrekt oder er kann derzeit nicht erreicht werden. Öffne deinen Datentresor und überprüfe hier im Menü ',
                                                 icon('gear'),
                                                 ' rechts oben "Konfiguration" die Verbindungsdaten.')
                        } else {
                                if(is.na(app[['token']])){
                                        piaMsg <- paste0('Die angegebenen Verbindungsdaten zum Datentresor sind nicht korrekt oder er kann derzeit nicht erreicht werden. Öffne deinen Datentresor und überprüfe hier im Menü ',
                                                         icon('gear'),
                                                         ' rechts oben "Konfiguration" die Verbindungsdaten.')
                                }
                        }
                } else {
                        piaMsg <- paste0('Es sind keine oder nur unvollständige Verbindungsdaten vorhanden. Wähle im Menü ',
                                         icon('gear'),
                                         ' rechts oben "Konfiguration" und überprüfe die Verbindungsdaten zum Datentresor!')
                }
        }
        
        mailConfigMsg <- paste0('Derzeit sind noch keine Verbindungsdaten zum Versenden und Empfangen von Emails konfiguriert. Wähle im Menü ',
                                icon('gear'),
                                ' rechts oben "Konfiguration" und überprüfe die Eingaben!')
        
        if(nchar(piaMsg) > 0){
                createAlert(session, 'piaStatus', alertId = 'myPiaStatus',
                            style = 'danger', append = FALSE,
                            title = 'Verbindung zum Datentresor',
                            content = piaMsg)
                createAlert(session, 'mailConfigStatus', 
                            alertId = 'myMailConfigStatus',
                            style = 'warning', append = FALSE,
                            title = 'Fehlende Email Konfiguration',
                            content = mailConfigMsg)
                app <- vector()
        } else {
                closeAlert(session, 'myPiaStatus')
                
                # set alert for missing email config
                url <- itemsUrl(app[['url']], schedulerEmailConfigKey)
                data <- list(server=input$modalMailerAddress,
                             port=input$modalMailerPort,
                             user=input$modalMailerUser,
                             pwd=input$modalMailerPassword)
                mailConfig <- readItems(app, url)
                if(nrow(mailConfig) == 0){
                        createAlert(session, 'mailConfigStatus', 
                                    alertId = 'myMailConfigStatus',
                                    style = 'warning', append = FALSE,
                                    title = 'Fehlende Email Konfiguration',
                                    content = mailConfigMsg)
                }
        }
        app
})

currData <- reactive({
        # list any input controls that effect currData
        input$modalPiaUrl
        input$modalPiaId
        input$modalPiaSecret
        
        app <- currApp()
        if(length(app) > 0) {
                url <- itemsUrl(app[['url']], 
                                paste0(app[['app_key']]))
                readItems(app, url)
        } else {
                data.frame()
        }
})

currDataDateSelectTimestamp <- reactive({
        closeAlert(session, 'myDataStatus')
        data <- currData()
        if(nrow(data) > 0){
                mymin <- as.Date(input$dateRange[1], '%d.%m.%Y')
                mymax <- as.Date(input$dateRange[2], '%d.%m.%Y')
                if(mymax > mymin){
                        daterange <- seq(mymin, mymax, 'days')
                        data$dat <- as.Date(as.POSIXct(data$time/1000, origin='1970-01-01'))
                        data <- data[data$dat %in% daterange, ]
                        if(nrow(data) > 0){
                                data
                        } else {
                                createAlert(session, 'dataStatus', alertId = 'myDataStatus',
                                            style = 'warning', append = FALSE,
                                            title = 'Keine Daten im gewählten Zeitfenster',
                                            content = 'Für das ausgewählte Zeitfenster sind keine Daten vorhanden.')
                                data.frame()
                        }
                } else {
                        createAlert(session, 'dataStatus', alertId = 'myDataStatus',
                                    style = 'warning', append = FALSE,
                                    title = 'Ungültiges Zeitfenster',
                                    content = 'Im ausgewählten Zeitfenster liegt das End-Datum vor dem Beginn-Datum. Korriege die Eingabe!')
                        data.frame()
                }
        } else {
                createAlert(session, 'dataStatus', alertId = 'myDataStatus',
                            style = 'warning', append = FALSE,
                            title = 'Keine Website-Daten im Datentresor vorhanden',
                            content = 'Derzeit sind noch keine Website-Daten im Datentresor gespeichert. Wechsle zu "Datenquellen" und installiere das passende Plugin für deinen Browser!')
                data.frame()
        }
})
