# OYD: Kontoentwicklung  - last update:2016-05-02
# Manifest for bank app ===================================
'
encode with https://www.base64encode.org/
{
        "name":"Bank App",
        "identifier":"eu.ownyourdata.bank",
        "type":"external",
        "description":"visualize development of your savings",
        "permissions":["eu.ownyourdata.bank:read",
                       "eu.ownyourdata.bank:write",
                       "eu.ownyourdata.scheduler:read",
                       "eu.ownyourdata.scheduler:write",
                       "eu.ownyourdata.scheduler:update",
                       "eu.ownyourdata.scheduler:delete",
                       "eu.ownyourdata.scheduler.email_config:read",
                       "eu.ownyourdata.scheduler.email_config:write",
                       "eu.ownyourdata.scheduler.email_config:update",
                       "eu.ownyourdata.scheduler.email_config:delete"]
}
ew0KICAgICAgICAibmFtZSI6IkJhbmsgQXBwIiwNCiAgICAgICAgImlkZW50aWZpZXIiOiJldS5vd255b3VyZGF0YS5iYW5rIiwNCiAgICAgICAgInR5cGUiOiJleHRlcm5hbCIsDQogICAgICAgICJkZXNjcmlwdGlvbiI6InZpc3VhbGl6ZSBkZXZlbG9wbWVudCBvZiB5b3VyIHNhdmluZ3MiLA0KICAgICAgICAicGVybWlzc2lvbnMiOlsiZXUub3dueW91cmRhdGEuYmFuazpyZWFkIiwNCiAgICAgICAgICAgICAgICAgICAgICAgImV1Lm93bnlvdXJkYXRhLmJhbms6d3JpdGUiLA0KICAgICAgICAgICAgICAgICAgICAgICAiZXUub3dueW91cmRhdGEuc2NoZWR1bGVyOnJlYWQiLA0KICAgICAgICAgICAgICAgICAgICAgICAiZXUub3dueW91cmRhdGEuc2NoZWR1bGVyOndyaXRlIiwNCiAgICAgICAgICAgICAgICAgICAgICAgImV1Lm93bnlvdXJkYXRhLnNjaGVkdWxlcjp1cGRhdGUiLA0KICAgICAgICAgICAgICAgICAgICAgICAiZXUub3dueW91cmRhdGEuc2NoZWR1bGVyOmRlbGV0ZSIsDQogICAgICAgICAgICAgICAgICAgICAgICJldS5vd255b3VyZGF0YS5zY2hlZHVsZXIuZW1haWxfY29uZmlnOnJlYWQiLA0KICAgICAgICAgICAgICAgICAgICAgICAiZXUub3dueW91cmRhdGEuc2NoZWR1bGVyLmVtYWlsX2NvbmZpZzp3cml0ZSIsDQogICAgICAgICAgICAgICAgICAgICAgICJldS5vd255b3VyZGF0YS5zY2hlZHVsZXIuZW1haWxfY29uZmlnOnVwZGF0ZSIsDQogICAgICAgICAgICAgICAgICAgICAgICJldS5vd255b3VyZGF0YS5zY2hlZHVsZXIuZW1haWxfY29uZmlnOmRlbGV0ZSJdDQp9DQo=
'

# Setup and config ========================================
# install.packages(c('shiny', 'shinyBS', 'DT', 'tidyr', 'digest', 'RCurl', 'jsonlite', 'dplyr'), repos='https://cran.rstudio.com/')
library(shiny)
library(digest)
library(tidyr)
library(RCurl)
library(jsonlite)
library(dplyr)

source("oyd_helpers.R")

first <- TRUE
prevInstitute <- ''

# Shiny Server ============================================
shinyServer(function(input, output, session) {

# Bank specific functions =================================
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
                                                          format='%d.%m.%y'))
                        myData[, c('date', 'description', 'id', 'value')]
                })
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
                    bankInstitute == 'auswählen...') {
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
        
        bankRepo <- reactive({
                url <- input$bank_url
                app_key <- input$bank_app_key
                app_secret <- input$bank_app_secret
                if((nchar(url) > 0) & 
                   (nchar(app_key) > 0) & 
                   (nchar(app_secret) > 0)) {
                        if(input$localBankSave) {
                                save(url, 
                                     app_key, 
                                     app_secret, 
                                     file='~/bankCredentials.RData')
                        } else {
                                # if (file.exists('~/bankCredentials.RData'))
                                #         file.remove('~/bankCredentials.RData')
                        }
                        getRepo(url, app_key, app_secret)
                } else {
                        vector()
                }
        })

        bankData <- reactive({
                # get data from PIA and CSV Import
                repo <- bankRepo()
                if(length(repo) > 0) {
                        url <- itemsUrl(repo[['url']], 
                                         repo[['app_key']])
                        piaData <- readItems(repo, url)
                } else {
                        piaData <- data.frame()
                }
                importData <- csv_import()
                        
                # merge both data sets
                piaData <- createDigest(piaData, 
                                        c('date', 'value', 'description'))
                importData <- createDigest(importData, 
                                           c('date', 'value', 'description'))
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

        getReferenceValue <- reactive({
                refType <- input$reference
                refValue <- input$reference_value
                c(refType=refType, refValue=refValue)
        })
        
        savedPia <- eventReactive(input$exportButton, {
                # get data from PIA and CSV Import
                repo <- bankRepo()
                url <- itemsUrl(repo[['url']], 
                                repo[['app_key']])
                piaData <- readItems(repo, url)
                importData <- csv_import()
                
                # merge both data sets
                data <- data.frame()
                piaData <- createDigest(piaData,
                                        c('date', 'value', 'description'))
                importData <- createDigest(importData,
                                           c('date', 'value', 'description'))
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

# Bank specific output fields =============================
        output$plot <- renderPlot({
                if(first) {
                        createAlert(session, 'topAlert', style='danger', title='Sie befinden sich auf einer unsicheren Webseite!',
                                    content="Die auf dieser Webseite eingegebenen und hochgeladenden Daten können möglicherweise durch Unberechtigte mitgelesen werden - <a href='https://www.ownyourdata.eu/laendervergleich-datenschutz/'>weitere Infos</a>.<br><strong>Lösung:</strong> <a href='https://www.ownyourdata.eu/apps/kontodaten-visualisierung-app/'>Installieren</a> sie die <em>Kontoauszüge App</em> an einem sicheren Ort ihrer Wahl!", append=FALSE)
                        first <<- FALSE                  
                }
                closeAlert(session, 'noDataAlert')
                data <- bankData()
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
                data <- bankData()
                closeAlert(session, 'noDataAlert')
                data <- bankData()
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
        
        output$last_saved <- renderText({
                savedPia()
        })
        
        output$bank_token <- renderText({
                repo <- bankRepo()
                if (length(repo) == 0) {
                        '<strong>Token:</strong> nicht verfügbar'
                } else {
                        paste0('<strong>Token:</strong><br><small>', 
                               repo[['token']], '</small>')
                }
        })
        
        output$bank_records <- renderText({
                data <- bankData()
                paste('<strong>Datensätze:</strong>',
                      nrow(data))
        })

# Email reminders =========================================        
        getLocalEmailConfig <- reactive({
                validEmailConfig <- FALSE
                server <- input$mailer_address
                port <- input$mailer_port
                user <- input$mailer_user
                pwd <- input$mailer_password
                if((nchar(server) > 0) & 
                   (nchar(port) > 0) & 
                   (nchar(user) > 0) & 
                   (nchar(pwd) > 0)) {
                        validEmailConfig <- TRUE
                }
                c('valid'=validEmailConfig,
                  'server'=server,
                  'port'=port,
                  'user'=user,
                  'pwd'=pwd)
        })

        emailConfigStatus <- function(repo){
                localMailConfig <- getLocalEmailConfig()
                piaMailConfig <- getPiaEmailConfig(repo)
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
                                        updateEmailConfig(repo, 
                                                          localMailConfig, 
                                                          piaMailConfig[['id']])
                                        'config updated'
                                }
                        } else {
                                writeEmailConfig(repo, localMailConfig)
                                'config saved'
                        }
                } else {
                        # is there already a config in PIA?
                        if (length(piaMailConfig) > 0) {
                                setEmailConfig(session, piaMailConfig)
                                'config loaded' # Mailkonfiguration von PIA gelesen
                        } else {
                                'not configured' # keine Mailkonfiguration vorhanden
                        }
                }
        }
        
        emailReminderStatus <- reactive({
                repo <- bankRepo()
                piaMailConfig <- getPiaEmailConfig(repo)
                piaSchedulerEmail <- getPiaSchedulerEmail(repo)
                piaEmail <- ''
                piaEmailId <- NA
                if (length(piaMailConfig) == 0) {
                        'no mail config'
                } else {
                        if (length(piaSchedulerEmail) > 0) {
                                piaEmail <- piaSchedulerEmail[['email']]
                                piaEmailId <-  piaSchedulerEmail[['id']]
                        }
                        localEmail <- as.character(input$email)
                        if(validEmail(localEmail)) {
                                if (localEmail == piaEmail) {
                                        'email in sync'
                                } else {
                                        if (piaEmail == '') {
                                                writeSchedulerEmail(
                                                        repo,
                                                        localEmail,
                                                        'upload bank csv',
                                                        '0 9 1 * *')
                                                'email saved'
                                        } else {
                                                updateSchedulerEmail(
                                                        repo,
                                                        localEmail,
                                                        'upload bank csv',
                                                        '0 9 1 * *',
                                                        piaEmailId)
                                                'email updated'
                                        }
                                }
                        } else {
                                if (nchar(localEmail) == 0) {
                                        if (piaEmail == '') {
                                                'missing email'
                                        } else {
                                                setSchedulerEmail(session, piaEmail)
                                                'email loaded'
                                        }
                                } else {
                                        'invalid email'
                                }
                        }
                }
                
        })
        
        output$mail_config <- renderText({
                repo <- bankRepo()
                retVal <- emailConfigStatus(repo)
                switch(retVal,
                       'config in sync' = 'Benachrichtigungen via Email sind eingerichtet',
                       'not configured' = 'Benachrichtigungen via Email sind noch nicht konfiguiert',
                       'config saved'   = 'Emailkonfiguration in PIA gespeichert',
                       'config updated' = 'Emailkonfiguration in PIA aktualisiert',
                       'config loaded'  = 'Emailkonfiguration aus PIA geladen')
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
        

# LEGACY - fix me =========================================
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
