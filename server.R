'
Manifest for bank (encode with https://www.base64encode.org/)
{
        "name":"Bank App",
        "identifier":"eu.ownyourdata.bank",
        "type":"external",
        "description":"visualize development of your savings",
        "permissions":["eu.ownyourdata.bank:read",
                       "eu.ownyourdata.bank:write"]
}
Manifest for scheduler
{
        "name":"Scheduler",
        "identifier":"eu.ownyourdata.scheduler",
        "type":"external",
        "description":"perform repetitive tasks",
        "permissions":["eu.ownyourdata.scheduler:read",
                       "eu.ownyourdata.scheduler:write",
                       "eu.ownyourdata.scheduler:update",
                       "eu.ownyourdata.scheduler:delete",
                       "eu.ownyourdata.scheduler.config:read",
                       "eu.ownyourdata.scheduler.config:write",
                       "eu.ownyourdata.scheduler.config:update",
                       "eu.ownyourdata.scheduler.config:delete"]
}
'
# install.packages(c('shiny', 'shinyBS', 'DT', 'tidyr', 'digest', 'RCurl', 'jsonlite', 'dplyr'), repos='https://cran.rstudio.com/')
library(shiny)
library(digest)
library(tidyr)
library(RCurl)
library(jsonlite)
library(dplyr)

first <- TRUE
prevInstitute <- ''

shinyServer(function(input, output, session) {
        
        defaultHeaders <- function(token) {
                c('Accept'        = '*/*',
                  'Content-Type'  = 'application/json',
                  'Authorization' = paste('Bearer', token))
        }
        
        items_url <- function(url, app_key) {
                paste0(url, '/api/repos/', app_key, '/items')
        }
        
        get_token <- function(url, app_key, app_secret) {
                url_auth <- paste0(url, '/oauth/token')
                response <- tryCatch(
                        postForm(url_auth,
                                 client_id=app_key,
                                 client_secret=app_secret,
                                 grant_type='client_credentials'),
                        error = function(e) { return(NA) })
                if (is.na(response)) {
                        return(NA)
                } else {
                        return(fromJSON(response[1])$access_token)
                }
        }

        create_digest <- function(data) {
                if (nrow(data)>0) {
                        data <- unite_(data, 'merged', 
                                      c('date', 'value', 'description'), 
                                      remove=FALSE)
                        data$digest <- sapply(data$merged, digest)
                        data[, c('date', 'value',  'description',  'digest')]
                } else {
                        data.frame()
                }
        }
        
        csv_import_Easybank <- function(myFile) {
                tryCatch({
                        myData <- read.csv2(myFile$datapath, header=FALSE, 
                                            sep=';', quote="\"", dec='.', 
                                            encoding = 'UTF-8')
                        colnames(myData) <- c('Konto', 
                                              'Beschreibung', 
                                              'Datum1', 
                                              'Datum2', 
                                              'Betrag', 
                                              'Waehrung')
                        myData$description <- as.character(myData$Beschreibung)
                        Encoding(myData$description) <- 'latin1'
                        myData$id <- 1:nrow(myData)
                        myData$value <- as.numeric(sub(',', '.', 
                                                       gsub("\\.", '', 
                                                            myData$Betrag)))
                        myData$date <- as.Date(as.POSIXct(myData$Datum1, 
                                                          format='%d.%m.%Y'))
                        myData[, c('date', 'description', 'id', 'value')]
                })
        }
 
        csv_import_ErsteGroup <- function(myFile) {
                tryCatch({
                        myData <- read.csv2(myFile$datapath, header = TRUE, 
                                            sep = ';', quote = "\"", dec='.', 
                                            fileEncoding = 'ISO-8859-1')
                        myData$description <- as.character(myData$Bezeichnung)
                        Encoding(myData$description) <- 'latin1'
                        myData <- head(myData, -1)
                        myData$id <- 1:nrow(myData)
                        myData$value <- as.numeric(sub(',', '.', 
                                                       gsub("\\.", '', 
                                                            myData$Betrag)))
                        myData$date <- as.Date(as.POSIXct(myData$Valutadatum, 
                                                          format='%d.%m.%Y'))
                        myData[, c('date', 'description', 'id', 'value')]
                })
        }

        csv_import_IngDiba <- function(myFile) {
                tryCatch({
                        myData <- read.csv2(myFile$datapath, header = TRUE, 
                                            sep = ';', quote = "\"", dec='.', 
                                            fileEncoding = 'ISO-8859-1')
                        myData$description <- as.character(myData$Text)
                        Encoding(myData$description) <- 'latin1'
                        myData$id <- 1:nrow(myData)
                        myData$SollValue <- -1*as.numeric(sub(',', '.', 
                                                              gsub("\\.", '', 
                                                                   myData$Soll)))
                        myData$HabenValue <- as.numeric(sub(',', '.', 
                                                            gsub("\\.", '', 
                                                                 myData$Haben)))
                        myData$value <- myData$SollValue + myData$HabenValue                        
                        myData$date <- as.Date(as.POSIXct(myData$ValutaDatum, 
                                                          format='%d.%m.%Y'))
                        myData[, c('date', 'description', 'id', 'value')]
                })
        }
        
        writeRecord <- function(repo, url, record) {
                headers <- defaultHeaders(repo[['token']])
                data <- gsub("\\[|\\]", '', 
                             toJSON(record, auto_unbox = TRUE))
                response <- tryCatch(
                        postForm(url,
                                 .opts=list(httpheader = headers,
                                            postfields = data)),
                        error = function(e) { return(NA) })
                response
        }
        
        updateRecord <- function(repo, url, record, id) {
                headers <- defaultHeaders(repo[['token']])
                record$id <- id
                data <- gsub("\\[|\\]", '', 
                             toJSON(record, auto_unbox = TRUE))
                response <- tryCatch(
                        postForm(url,
                                 .opts=list(httpheader = headers,
                                            postfields = data)),
                        error = function(e) { return(NA) })
                response
        }
        
        bank_repo <- reactive({
                bank_url <- input$bank_url
                bank_app_key <- input$bank_app_key
                bank_app_secret <- input$bank_app_secret
                if((nchar(bank_url) > 0) & 
                   (nchar(bank_app_key) > 0) & 
                   (nchar(bank_app_secret) > 0)) {
                        if(input$localBankSave) {
                                saved_bank_url <- bank_url
                                saved_bank_app_key <- bank_app_key
                                saved_bank_app_secret <- bank_app_secret
                        } else {
                                saved_bank_url <- ''
                                saved_bank_app_key <- ''
                                saved_bank_app_secret <- ''
                        }
                        save(saved_bank_url, 
                             saved_bank_app_key, 
                             saved_bank_app_secret, 
                             file='bankCredentials.RData')
                        c('url'=bank_url,
                          'app_key'=bank_app_key,
                          'app_secret'=bank_app_secret,
                          'token'=get_token(bank_url, 
                                            bank_app_key, 
                                            bank_app_secret))
                } else {
                        vector()
                }
        })
        
        read_items <- function(repo, url) {
                if (length(repo) == 0) {
                        data.frame()
                } else {
                        headers <- defaultHeaders(repo[['token']])
                        url_data <- paste0(url, '?size=2000')
                        response <- tryCatch(
                                getURL(url_data,
                                       .opts=list(httpheader = headers)),
                                error = function(e) { return(NA) })
                        if (is.na(response)) {
                                data.frame()
                        } else {
                                if (nchar(response) > 0) {
                                        retVal <- fromJSON(response)
                                        if(length(retVal) == 0) {
                                                data.frame()
                                        } else {
                                                if ('error' %in% names(fromJSON(response))) {
                                                        data.frame()
                                                } else {
                                                        retVal
                                                }
                                        }
                                } else {
                                        data.frame()
                                }
                        }
                }
        }
        
        csv_import <- reactive({
                bankInstitute <- input$bankInstitute
                bankFile <- input$bankFile
                if(prevInstitute != bankInstitute) {
                        bankFile <- NULL
                        session$sendCustomMessage(type='resetFileInputHandler', 
                                                  'bankFile')
                        prevInstitute <<- bankInstitute
                }
                if (is.null(bankFile) | 
                    bankInstitute == 'auswaehlen...') {
                        data.frame()  
                } else {
                        data <- switch(bankInstitute,
                                       'Bawag/Easybank' = csv_import_Easybank(bankFile),
                                       'Erste Group' = csv_import_ErsteGroup(bankFile),
                                       'ING-DiBa' = csv_import_IngDiba(bankFile))
                        colnames(data) <- c('date', 
                                            'description', 
                                            'id', 
                                            'value')
                        data
                }
        })
        
        bank_data <- reactive({
                # get data from PIA and CSV Import
                repo <- bank_repo()
                if(length(repo) > 0) {
                        url <- items_url(repo[['url']], 
                                         repo[['app_key']])
                        piaData <- read_items(repo, url)
                } else {
                        piaData <- data.frame()
                }
                importData <- csv_import()
                        
                # merge both data sets
                piaData <- create_digest(piaData)
                importData <- create_digest(importData)
                data <- rbind(importData, piaData)
                dups <- duplicated(data$digest)
                data <- data[!dups, ]
                        
                # create return Value
                if(nrow(data) > 0) {
                        data$dat <- as.POSIXct(data$date, 
                                               format='%Y-%m-%d')
                        data[with(data, order(dat)),]
                } else {
                        data.frame()
                }
        })
        
        scheduler_repo <- reactive({
                scheduler_url <- input$scheduler_url
                scheduler_app_key <- input$scheduler_app_key
                scheduler_app_secret <- input$scheduler_app_secret
                if((nchar(scheduler_url) > 0) & 
                   (nchar(scheduler_app_key) > 0) & 
                   (nchar(scheduler_app_secret) > 0)) {
                        if(input$localSchedulerSave) {
                                saved_scheduler_url <- scheduler_url
                                saved_scheduler_app_key <- scheduler_app_key
                                saved_scheduler_app_secret <- scheduler_app_secret
                        } else {
                                saved_scheduler_url <- ''
                                saved_scheduler_app_key <- ''
                                saved_scheduler_app_secret <- ''
                        }
                        save(saved_scheduler_url, 
                             saved_scheduler_app_key, 
                             saved_scheduler_app_secret, 
                             file='schedulerCredentials.RData')
                        c('url'=scheduler_url,
                          'app_key'=scheduler_app_key,
                          'app_secret'=scheduler_app_secret,
                          'token'=get_token(scheduler_url, 
                                            scheduler_app_key, 
                                            scheduler_app_secret))
                } else {
                        vector()
                }
        })
        
        getReferenceValue <- reactive({
                refType <- input$reference
                refValue <- input$reference_value
                c(refType=refType, refValue=refValue)
        })
        
        output$plot <- renderPlot({
                if(first) {
                        createAlert(session, 'topAlert', style='danger', title='Sie befinden sich auf einer unsicheren Webseite!',
                                    content="Die auf dieser Webseite eingegebenen und hochgeladenden Daten können möglicherweise durch Unberechtigte mitgelesen werden - <a href='https://www.ownyourdata.eu/laendervergleich-datenschutz/'>weitere Infos</a>.<br><strong>Lösung:</strong> <a href='https://www.ownyourdata.eu/apps/kontodaten-visualisierung-app/'>Installieren</a> sie die <em>Kontoauszüge App</em> an einem sicheren Ort ihrer Wahl!", append=FALSE)
                        first <<- FALSE                  
                }
                closeAlert(session, 'noDataAlert')
                data <- bank_data()
                if(nrow(data) > 0) {
                        refValue <- getReferenceValue()
                        dataMin <- min(data$dat, na.rm=TRUE)
                        dataMax <- max(data$dat, na.rm=TRUE)
                        switch(as.character(refValue[['refType']]),
                               '1' = { # Startbetrag
                                       newDat <- dataMin -1
                                       newVal <- refValue[['refValue']]
                                       data <- rbind(data.frame(date = as.Date(newDat),
                                                                value = as.numeric(newVal),
                                                                description = 'Startbetrag',
                                                                digest = '',
                                                                dat = as.POSIXct(newDat, format='%Y-%m-%d')),
                                                     data)
                               },
                               '2' = { # Endbetrag
                                       newDat <- dataMin -1
                                       newVal <- as.numeric(refValue[['refValue']]) - sum(data$value)
                                       data <- rbind(data.frame(date = as.Date(newDat),
                                                                value = newVal,
                                                                description = paste('Endbetrag:', refValue[['refValue']]),
                                                                digest = '',
                                                                dat = as.POSIXct(newDat, format='%Y-%m-%d')),
                                                     data)
                                       
                               })
                        data$cumsum <- cumsum(as.numeric(data$value))
                        curMin <- as.Date(input$dateRange[1], '%d.%m.%Y')
                        curMax <- as.Date(input$dateRange[2], '%d.%m.%Y')
                        daterange <- seq(curMin, curMax, 'days')
                        data <- data[as.Date(data$dat) %in% daterange, ]
                        if(nrow(data) > 0) {
                                plot(x=data$dat, y=data$cumsum, type='l', 
                                     xlab='Datum', ylab='Euro')
                        } else {
                                createAlert(session, 'noData', 'noDataAlert', style='warning', title='Keine Daten im ausgewählten Zeitfenster',
                                            content=paste0('Passen sie links die Zeitauswahl an - es stehen Daten zwischen ',
                                                           format(as.POSIXct(dataMin, '%Y-%m-%d'), '%d.%m.%Y'),
                                                           ' und ',
                                                           format(as.POSIXct(dataMax, '%Y-%m-%d'), '%d.%m.%Y'),
                                                           ' zur Verfügung.'))
                        }
                } else {
                        createAlert(session, 'noData', 'noDataAlert', style='info', title='Keine Daten vorhanden',
                                    content='Laden sie ihren Kontoauszug hoch und/oder verbinden sie sich zu ihrer PIA, um die Kontoentwicklung anzuzeigen.', append=FALSE)
                }
        })
  
        output$table <- DT::renderDataTable({
                data <- bank_data()
                closeAlert(session, 'noDataAlert')
                data <- bank_data()
                if(nrow(data) > 0) {
                        dataMin <- min(data$dat)
                        dataMax <- max(data$dat)
                        curMin <- as.Date(input$dateRange[1], '%d.%m.%Y')
                        curMax <- as.Date(input$dateRange[2], '%d.%m.%Y')
                        daterange <- seq(curMin, curMax, 'days')
                        data$cumsum <- cumsum(data$value)
                        data <- data[as.Date(data$dat) %in% daterange, ]
                        if(nrow(data) > 0) {
                                myData <- data[, c('date', 'value', 'description')]
                                colnames(myData) <- c('Datum', 'Betrag', 'Beschreibung')
                                DT::datatable(myData, options = list(pageLength = 25))
                        } else {
                                createAlert(session, 'noData', 'noDataAlert', style='warning', title='Keine Daten im ausgewählten Zeitfenster',
                                            content=paste0('Passen sie links die Zeitauswahl an - es stehen Daten zwischen ',
                                                           format(as.POSIXct(dataMin, '%Y-%m-%d'), '%d.%m.%Y'),
                                                           ' und ',
                                                           format(as.POSIXct(dataMax, '%Y-%m-%d'), '%d.%m.%Y'),
                                                           ' zur Verfügung.'))
                        }
                } else {
                        createAlert(session, 'noData', 'noDataAlert', style='info', title='Keine Daten vorhanden',
                                    content='Laden sie ihren Kontoauszug hoch und/oder verbinden sie sich zu ihrer PIA, um die Kontoentwicklung anzuzeigen.', append=FALSE)
                }
        })
        
        savedPia <- eventReactive(input$exportButton, {
                # get data from PIA and CSV Import
                repo <- bank_repo()
                url <- items_url(repo[['url']], 
                                 repo[['app_key']])
                piaData <- read_items(repo, url)
                importData <- csv_import()
                
                # merge both data sets
                data <- data.frame()
                piaData <- create_digest(piaData)
                importData <- create_digest(importData)
                data <- rbind(importData, piaData)
                dups <- duplicated(data$digest)
                data <- data[!dups, ]

                # write only updates to PIA
                recCnt <- nrow(data)
                cnt <- 0
                withProgress(message = 'PIA abgleichen', max=recCnt, {
                        for(i in 1:recCnt) {
                                if(!(data[i,'digest'] %in% piaData$digest)) {
                                        writeRecord(repo, url,
                                                    data[i, c('date', 
                                                              'value', 
                                                              'description')])
                                        cnt <- cnt+1
                                }
                                setProgress(value=i, 
                                            detail=paste0(i,'/', recCnt,
                                                          ' Datensätze'))
                        }
                })
                paste('<strong>zuletzt gespeichert:</strong>',
                      cnt, 'Datensätze um',
                      format(Sys.time(), '%H:%M:%S'))
        })

        output$last_saved <- renderText({
                savedPia()
        })
        
        output$bank_token <- renderText({
                repo <- bank_repo()
                if (length(repo) == 0) {
                        '<strong>Token:</strong> nicht verfügbar'
                } else {
                        paste0('<strong>Token:</strong><br><small>', 
                               repo[['token']], '</small>')
                }
        })
        
        output$bank_records <- renderText({
                data <- bank_data()
                paste('<strong>Datensätze:</strong>',
                      nrow(data))
        })
        
        output$scheduler_token <- renderText({
                repo <- scheduler_repo()
                if (length(repo) == 0) {
                        '<strong>Token:</strong> nicht verfügbar'
                } else {
                        paste0('<strong>Token:</strong><br><small>', 
                               repo[['token']], '</small>')
                }
        })

        writeMailConfig <- function(mailConfig) {
                repo <- scheduler_repo()
                url <- items_url(repo[['url']], 
                                 paste0(repo[['app_key']], '.config'))
                data <- as.list(mailConfig)[-which(names(mailConfig)=='valid')]
                writeRecord(repo, url, data)
        }
        
        updateMailConfig <- function(mailConfig, id) {
                repo <- scheduler_repo()
                url <- items_url(repo[['url']], 
                                 paste0(repo[['app_key']], '.config'))
                data <- as.list(mailConfig)[-which(names(mailConfig)=='valid')]
                updateRecord(repo, url, data, id)
        }
        
        setMailConfig <- function(mailConfig) {
                updateTextInput(session, 'mailer_address', 
                                value=mailConfig[['server']])
                updateNumericInput(session, 'mailer_port', 
                                value=mailConfig[['port']])
                updateTextInput(session, 'mailer_user', 
                                value=mailConfig[['user']])
                updateTextInput(session, 'mailer_password', 
                                value=mailConfig[['pwd']])
        }
        
        getLocalMailConfig <- reactive({
                validMailConfig <- FALSE
                server <- input$mailer_address
                port <- input$mailer_port
                user <- input$mailer_user
                pwd <- input$mailer_password
                if((nchar(server) > 0) & 
                   (nchar(port) > 0) & 
                   (nchar(user) > 0) & 
                   (nchar(pwd) > 0)) {
                        validMailConfig <- TRUE
                }
                c('valid'=validMailConfig,
                  'server'=server,
                  'port'=port,
                  'user'=user,
                  'pwd'=pwd)
        })
        
        getPiaMailConfig <- function() {
                repo <- scheduler_repo()
                url <- items_url(repo[['url']], 
                                 paste0(repo[['app_key']], '.config'))
                retVal <- read_items(repo, url)
                if(nrow(retVal) == 0) {
                        vector()
                } else {
                        retVal
                }
        }
        
        mailConfigStatus <- function() {
                localMailConfig <- getLocalMailConfig()
                piaMailConfig <- getPiaMailConfig()
                if (localMailConfig[['valid']]) {
                        # is there already a config in PIA?
                        if (length(piaMailConfig) > 0) {
                                # is it different?
                                if((localMailConfig[['server']] == piaMailConfig[['server']]) &
                                   (localMailConfig[['port']] == piaMailConfig[['port']]) &
                                   (localMailConfig[['user']] == piaMailConfig[['user']]) &
                                   (localMailConfig[['pwd']] == piaMailConfig[['pwd']])) {
                                        'config in sync'
                                } else {
                                        updateMailConfig(localMailConfig, piaMailConfig[['id']])
                                        'config updated'
                                }
                        } else {
                                writeMailConfig(localMailConfig)
                                'config saved'
                        }
                } else {
                        # is there already a config in PIA?
                        if (length(piaMailConfig) > 0) {
                                setMailConfig(piaMailConfig)
                                'config loaded' # Mailkonfiguration von PIA gelesen
                        } else {
                                'not configured' # keine Mailkonfiguration vorhanden
                        }
                }
        }

        output$mail_config <- renderText({
                retVal <- mailConfigStatus()
                switch(retVal,
                       'config in sync' = 'Benachrichtigungen via Email sind eingerichtet',
                       'not configured' = 'Benachrichtigungen via Email sind noch nicht konfiguiert',
                       'config saved'   = 'Emailkonfiguration in PIA gespeichert',
                       'config updated' = 'Emailkonfiguration in PIA aktualisiert',
                       'config loaded'  = 'Emailkonfiguration aus PIA geladen')
        })
        
        writeSchedulerEmail <- function(email) {
                sRepo <- scheduler_repo()
                bRepo <- bank_repo()
                url <- items_url(sRepo[['url']], 
                                 sRepo[['app_key']])
                parameters <- list(address=email,
                                   content='upload bank csv',
                                   encrypt='false')
                config <- list(repo=bRepo[['app_key']],
                               time='0 9 1 * *',
                               task='email',
                               parameters=parameters)
                writeRecord(sRepo, url, config)
        }

        updateSchedulerEmail <- function(email, id) {
                sRepo <- scheduler_repo()
                bRepo <- bank_repo()
                url <- items_url(sRepo[['url']], 
                                 sRepo[['app_key']])
                parameters <- list(address=email,
                                   content='upload bank csv',
                                   encrypt='false')
                config <- list(repo=bRepo[['app_key']],
                               time='0 9 1 * *',
                               task='email',
                               parameters=parameters)
                updateRecord(sRepo, url, config, id)
        }
        
        setSchedulerEmail <- function(email) {
                updateTextInput(session, 'email',
                                value=email)
        }
        
        getPiaSchedulerEmail <- function() {
                repo <- scheduler_repo()
                url <- items_url(repo[['url']], 
                                 repo[['app_key']])
                retVal <- read_items(repo, url)
                if(nrow(retVal) == 0) {
                        vector()
                } else {
                        c(id=retVal$id,
                          email=retVal$parameters$address)
                }
        }
        
        emailReminderStatus <- reactive({
                piaMailConfig <- getPiaMailConfig()
                piaSchedulerEmail <- getPiaSchedulerEmail()
                piaEmail <- ''
                piaEmailId <- NA
                if (length(piaSchedulerEmail) > 0) {
                        piaEmail <- piaSchedulerEmail[['email']]
                        piaEmailId <-  piaSchedulerEmail[['id']]
                }
                if (length(piaMailConfig) == 0) {
                        'no mail config'
                } else {
                        localEmail <- as.character(input$email)
                        emailPtrn <- "^[\\w\\.-]+@([\\w\\-]+\\.)+[A-Za-z]{2,4}$"
                        if (any(grep(emailPtrn, localEmail, perl = TRUE))) {
                                if (localEmail == piaEmail) {
                                        'email in sync'
                                } else {
                                        if (piaEmail == '') {
                                                writeSchedulerEmail(localEmail)
                                                'email saved'
                                        } else {
                                                updateSchedulerEmail(
                                                        localEmail,
                                                        piaEmailId)
                                                'email updated'
                                        }
                                }
                        } else {
                                if (nchar(localEmail) == 0) {
                                        if (piaEmail == '') {
                                                'missing email'
                                        } else {
                                                setSchedulerEmail(piaEmail)
                                                'email loaded'
                                        }
                                } else {
                                        'invalid email'
                                }
                        }
                }
                
        })
        
        output$email_status <- renderText({
                retVal <- emailReminderStatus()
                paste('<strong>Status:</strong>',
                        switch(retVal,
                               'no mail config' = 'Email-Konfiguration noch nicht vorhanden',
                               'missing email'  = 'fehlende Emailadresse',
                               'invalid email'  = 'ungültige Emailadresse',
                               'email loaded'   = 'Emailadresse aus PIA geladen',
                               'email in sync'  = 'periodische Email-Benachrichtigungen werden versandt',
                               'email saved'    = 'Emailadresse in PIA gespeichert',
                               'email updated'  = 'Emailadresse in PIA aktualisiert'))
        })
        
#===========LEGACY========================        
  output$group <- DT::renderDataTable({
          bank <- processDat(input, output, session)
          if(nrow(bank) > 0) {
                  bank$strType <- 4
                  bank[grepl('^Bezahlung Maestro', bank$Beschreibung),"strType"]<-1
                  bank[bank$strType == 4 & grepl('DEBIT[[:space:]]*POS', bank$Beschreibung),"strType"]<-2
                  bank[bank$strType == 4 & grepl('^[A-Za-z ]{10}', bank$Beschreibung),"strType"]<-3
                  bank$Kurzbez <- ""
                  bank[bank$strType == 1, "Kurzbez"] <- paste("Bezahlung Maestro", gsub(pattern="(.*UM [[:digit:]]{2}.[[:digit:]]{2} )(.*)([\\].*)", replacement="\\2", x = bank[bank$strType == 1, "Beschreibung"]))
                  bank[bank$strType == 2, "Kurzbez"] <- gsub("[[:space:]]*$","",gsub(pattern="(.*VD/[[:digit:]]* )(.*)", replacement="\\2", x = bank[bank$strType == 2, "Beschreibung"]))
                  bank[bank$strType == 3, "Kurzbez"] <- gsub(patter="(^[[:alpha:]]*[[[:blank:]][[:alpha:]]+]*)(.*)", replacement="\\1", x = bank[bank$strType == 3, "Beschreibung"])
                  bank[bank$strType == 4, "Kurzbez"] <- gsub("^\\s+|\\s+$", "", gsub(pattern="(.*[[:digit:]]{3})(.*$)", replacement="\\2", x = bank[bank$strType == 4, "Beschreibung"]))
                  bank[bank$strType == 4 & bank$Kurzbez == "", "Kurzbez"] <- gsub(pattern="(^[A-Za-z-]*[[:blank:]]+)(.*)", replacement="\\1", x = bank[bank$strType == 4 & bank$Kurzbez == "", "Beschreibung"])
                  agg_bank <- bank %>% group_by(Kurzbez) %>% summarise(count=n(), sum=sum(value), mean=mean(value))
                  DT::datatable(agg_bank, options = list(pageLength = 25))
          }
  })
})
