# functions for handling the initial dialog when starting the app
# last update: 2016-07-27

observe({
        session$sendCustomMessage(type='setPiaUrl',
                                  input$store$pia_url)
        urlParams <- parseQueryString(session$clientData$url_search)
        urlParamExist <- FALSE
        if(is.null(urlParams[['PIA_URL']])){
                piaUrl <<- input$store$pia_url
        } else {
                piaUrl <<- urlParams[['PIA_URL']]
                urlParamExist <- TRUE
        }
        if(is.null(urlParams[['APP_KEY']])){
                appKey <<- input$store$app_key
        } else {
                appKey <<- urlParams[['APP_KEY']]
                urlParamExist <- TRUE
        }
        if(is.null(urlParams[['APP_SECRET']])){
                appSecret <<- input$store$app_secret
        } else {
                appSecret <<- urlParams[['APP_SECRET']]
                urlParamExist <- TRUE
        }
        
        app <- setupApp(piaUrl, appKey, appSecret)
        if(urlParamExist){
                if((input$store$pia_url == urlParams[['PIA_URL']]) &
                   (input$store$app_key == urlParams[['APP_KEY']]) &
                   (input$store$app_secret == urlParams[['APP_SECRET']])){
                        
                } else {
                        updateStore(session, "pia_url", piaUrl)
                        updateStore(session, "app_key", appKey)
                        updateStore(session, "app_secret", appSecret)
                        createAlert(session, 'urlStatus', alertId = 'myUrlStatus',
                                    style = 'info', append = FALSE,
                                    title = 'Verbindung zu neuem Datentresor',
                                    content = 'Beim Öffnen wurden neue Verbindungsdaten zum Datentresor übergeben und gespeichert.')
                }
        } else {
                closeAlert(session, 'myUrlStatus')
        }
        if(length(all.equal(app, logical(0)))>1){
                closeAlert(session, 'myPiaStatus')
                updateTextInput(session, 'modalPiaUrl', value=piaUrl)
                updateTextInput(session, 'modalPiaId', value=appKey)
                updateTextInput(session, 'modalPiaSecret', value=appSecret)
                output$currentToken <- renderUI({
                        HTML(paste0('<strong>aktueller Token:</strong><br>',
                                    app[['token']],
                                    '<br><br>'))
                })
                piaMailConfig <- getPiaEmailConfig(app)
                if(!is.null(nrow(piaMailConfig))){
                        updateTextInput(session, 'modalMailerAddress', value=as.character(piaMailConfig$server))
                        updateNumericInput(session, 'modalMailerPort', value=as.numeric(as.character(piaMailConfig$port)))
                        updateTextInput(session, 'modalMailerUser', value=as.character(piaMailConfig$user))
                        updateTextInput(session, 'modalMailerPassword', value=as.character(piaMailConfig$pwd))
                }        
        } else {
                updateTextInput(session, 'modalPiaUrl', value=piaUrl)
                updateTextInput(session, 'modalPiaId', value=appKey)
                updateTextInput(session, 'modalPiaSecret', value=appSecret)
                output$currentToken <- renderText('')
        }
})

output$connectError <- renderUI({
        pia_url <- input$modalPiaUrl
        app_key <- input$modalPiaId
        app_secret <- input$modalPiaSecret
        auth_url <- paste0(pia_url, '/oauth/token')
        # reduce response timeout to 30s to avoid hanging app
        # https://curl.haxx.se/libcurl/c/CURLOPT_CONNECTTIMEOUT.html
        optTimeout <- curlOptions(connecttimeout = 30)
        response <- tryCatch(
                postForm(auth_url,
                         client_id     = app_key,
                         client_secret = app_secret,
                         grant_type    = 'client_credentials',
                         .opts         = optTimeout),
                error = function(e) { return(as.character(e)) })
        if (is.na(response)) {
                'Error: no response'
        } else {
                if(jsonlite::validate(response)){
                        ''
                } else {
                        if(grepl('error', response, ignore.case = TRUE)){
                                response
                        } else {
                                paste('Error:', response)
                        }
                }
        }
})

observeEvent(input$p1next, ({
        updateCollapse(session, 'collapse',
                       open = 'PIA',
                       style = list(
                               "Willkommen" = 'info',
                               'PIA' = 'primary',
                               'Email' = 'info',
                               'Fertig' = 'info'))
}))

observeEvent(input$p2prev, ({
        updateCollapse(session, 'collapse',
                       open = 'Willkommen',
                       style = list(
                               "Willkommen" = 'primary',
                               'PIA' = 'info',
                               'Email' = 'info',
                               'Fertig' = 'info'))
}))

observeEvent(input$disconnectPIA, {
        updateStore(session, 'pia_url', NA)
        updateStore(session, 'app_key', NA)
        updateStore(session, 'app_secret', NA)
        updateTextInput(session, 'modalPiaSecret', value='')
        updateTextInput(session, 'modalPiaId', value='')
        updateTextInput(session, 'modalPiaUrl', value='')
        piaUrl <<- ''
        appKey <<- ''
        appSecret <<- ''
        createAlert(session, 'piaStatus', alertId = 'myPiaStatus', 
                    style = 'danger', append = FALSE,
                    title = 'PIA Verbindung',
                    content = paste0('Es sind keine oder nur unvollständige Verbindungsdaten vorhanden. Wähle im Menü ',
                                     icon('gear'),
                                     ' rechts oben "Konfiguration" und überprüfe die Verbindungsdaten zu deiner PIA!'))
})

observeEvent(input$p2next, ({
        updateStore(session, "pia_url", isolate(input$modalPiaUrl))
        updateStore(session, "app_key", isolate(input$modalPiaId))
        updateStore(session, "app_secret", isolate(input$modalPiaSecret))
        updateTextInput(session, "pia_url", value=isolate(input$modalPiaUrl))
        updateTextInput(session, "app_key", value=isolate(input$modalPiaId))
        updateTextInput(session, "app_secret", value=isolate(input$modalPiaSecret))
        piaUrl <<- isolate(input$modalPiaUrl)
        appKey <<- isolate(input$modalPiaId)
        appSecret <<- isolate(input$modalPiaSecret)
        
        token <- getToken(piaUrl, appKey, appSecret)
        if(is.na(token)){
                createAlert(session, 'piaStatus', alertId = 'myPiaStatus',
                            style = 'danger', append = FALSE,
                            title = 'PIA Verbindung',
                            content = paste0('Es sind keine oder nur unvollständige Verbindungsdaten vorhanden. Wähle im Menü ',
                                             icon('gear'),
                                             ' rechts oben "Konfiguration" und überprüfe die Verbindungsdaten zu deiner PIA!'))
        } else {
                closeAlert(session, 'myPiaStatus')
        }
        # for re-rendering BEGIN -----
        # myApp <- setupApp(piaUrl, appKey, appSecret)
        # allItems <- collectItems(defaultStatTabsName,
        #                          defaultStatTabsUI,
        #                          defaultStatTabsLogic,
        #                          'status',
        #                          myApp)
        # output$extStatusItemError <- renderUI({ '' })
        # statTabUiList <<- allItems['allItemsName', ]
        # updateSelectInput(session, 'extStatusList', 
        #                   choices = statTabUiList)
        # checkAllItems(allItems, 'Status')
        # headerStr <- "tabsetPanel(type='tabs', "
        # footerStr <- ", uiStatusItemConfig())"
        # outputStr <- extRenderStr(allItems['allItemsName',], 
        #                           headerStr, footerStr, 'desktop', 'Status')
        # output$desktopUiStatusItemsRender <- renderUI({
        #         eval(parse(text = outputStr), envir=.GlobalEnv)
        # })
        # # for re-rendering END -----
        
        updateCollapse(session, 'collapse',
                       open = 'Email',
                       style = list(
                               "Willkommen" = 'info',
                               'PIA' = 'info',
                               'Email' = 'primary',
                               'Fertig' = 'info'))
}))

observeEvent(input$p3next, {
        app <- currApp()
        url <- itemsUrl(app[['url']], schedulerEmailConfigKey())
        data <- list(server=input$modalMailerAddress,
                     port=input$modalMailerPort,
                     user=input$modalMailerUser,
                     pwd=input$modalMailerPassword)
        mailConfig <- readItems(app, url)
        if(nrow(mailConfig) > 0){
                retVal <- updateItem(app, url, data, mailConfig$id)
        } else {
                retVal <- writeItem(app, url, data)
        }
        
        updateCollapse(session, 'collapse',
                       open = 'Fertig',
                       style = list(
                               "Willkommen" = 'info',
                               'PIA' = 'info',
                               'Email' = 'info',
                               'Fertig' = 'primary'))
})

observeEvent(input$p3skip, {
        updateCollapse(session, 'collapse',
                       open = 'Fertig',
                       style = list(
                               "Willkommen" = 'info',
                               'PIA' = 'info',
                               'Email' = 'info',
                               'Fertig' = 'primary'))
})

observeEvent(input$p3prev, ({
        updateCollapse(session, 'collapse',
                       open = 'PIA',
                       style = list(
                               "Willkommen" = 'info',
                               'PIA' = 'primary',
                               'Email' = 'info',
                               'Fertig' = 'info'))
}))

observeEvent(input$p4prev, ({
        updateCollapse(session, 'collapse',
                       open = 'Email',
                       style = list(
                               "Willkommen" = 'info',
                               'PIA' = 'info',
                               'Email' = 'primary',
                               'Fertig' = 'info'))
}))

observeEvent(input$p4close, ({
        app <- currApp()
        toggleModal(session, 'startConfig', toggle = "toggle")
}))
