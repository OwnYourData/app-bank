# application specific logic
# last update: 2016-10-07

source('srvDateselect.R', local=TRUE)
source('srvEmail.R', local=TRUE)
source('srvScheduler.R', local=TRUE)

source('appLogicBankImport.R', local=TRUE)
source('appLogicChart.R', local = TRUE)
source('appLogicAnalysis.R', local = TRUE)

# any record manipulations before storing a record
appData <- function(data){
        data$descriptionOrig <- data$description
        data
}

getRepoStruct <- function(repo){
        appStruct[[repo]]
}

repoData <- function(repo){
        data <- data.frame()
        app <- currApp()
        if(length(app) > 0){
                url <- itemsUrl(app[['url']],
                                repo)
                data <- readItems(app, url)
        }
        data
}

output$bankPlot <- renderPlotly({
        data <- currData()
        bankPlotly(data)
})

output$groupAnalysis <- DT::renderDataTable(datatable({
        input$bankImport
        input$saveReference
        grpConfigList <<- collectGrpConfigItems()
        grpConfigUiList <<- rownames(grpConfigList)
        updateSelectInput(session, 'grpConfigList', choices = grpConfigUiList)
        t(apply(grpConfigList, 1, calcGroupAnalysis))
}, options = list(language = list(url = '//cdn.datatables.net/plug-ins/1.10.11/i18n/German.json'))) 
%>% formatCurrency(c('Summe', 'Durchschnitt', 'Min', 'Max'), currency = "\U20AC", interval = 3, mark = ",", digits=2)
)

output$groupChart <- renderPlot({
        renderGroupChart()
})

csv_import <- function(){
        bankInstitute <- input$bankInstitute
        bankFile <- input$bankFile
        if (is.null(bankFile) | 
            bankInstitute == 'auswählen...') {
                data.frame()  
        } else {
                config <- list()
                if(input$bankImportHeader == 1) {
                        config$header <- FALSE
                } else {
                        config$header <- TRUE
                }
                config$sep         <- input$bankImportSep
                quoteStr <- input$bankImportQuote
                config$quote       <- sub("\\\\", "\\", quoteStr)
                config$dec         <- input$bankImportDec
                config$encoding    <- input$bankImportEncoding
                config$descEnc     <- input$bankImportDescEnc
                config$dateFormat  <- input$bankImportDateFormat
                config$dateColumn  <- input$bankImportDateColumn
                config$descColumn  <- input$bankImportDescColumn
                config$valueColumn <- input$bankImportValueColumn
                config$valueSoll   <- input$bankImportValueSoll
                config$valueHaben  <- input$bankImportValueHaben
                data <- csvImportDynamic(bankFile, config)
                colnames(data) <- c('date', 
                                    'description', 
                                    'id', 
                                    'value')
                data
        }
}

observeEvent(input$bankImport, {
        importData <- csv_import()
        app <- currApp()
        createPiaData <- data.frame()
        if(length(all.equal(app, logical(0)))>1){
                piaData <- currData()
                piaData$description <- as.character(piaData$description)
                if(nrow(piaData) > 0) {
                        Encoding(piaData$description) <- "UTF-8"
                }
                if(nrow(importData) > 0){
                        Encoding(importData$description) <- "UTF-8"
                }
                url <- itemsUrl(app[['url']], 
                                appRepos[['Kontobewegungen']])
                
                repoName <- input$repoSelect
                repoStruct <- getRepoStruct(repoName)

                appFields <- appStruct[['Kontobewegungen']]$fields
                appFieldKey <- appStruct[['Kontobewegungen']]$fieldKey
                appFieldTypes <- appStruct[['Kontobewegungen']]$fieldTypes
                importDigest <- createDigest(importData, appFields)
                piaDigest <- createDigest(piaData, appFields)
                createPiaData <- 
                        importData[!(importDigest$digest %in% piaDigest$digest), ]
                recCnt <- nrow(createPiaData)
                if(recCnt > 0){
                        withProgress(message='Daten importieren', 
                                     max=recCnt, {
                                             cnt <- 0
                                             if(nrow(createPiaData) > 0){
                                                     for(i in 1:nrow(createPiaData)){
                                                             cnt <- cnt + 1
                                                             dataItem <- preserveDate(
                                                                     createPiaData[i, appFields],
                                                                     appFieldTypes)
                                                             dataItem$descriptionOrig <- dataItem$description
                                                             dataItem$`_oydRepoName` <- 'Kontodaten'
                                                             writeItem(app, url, dataItem)
                                                             setProgress(value=cnt,
                                                                         detail=paste0(cnt, '/', recCnt,
                                                                                       ' Datensätze'))
                                                     }
                                             }
                                     })
                }
                writeLog(paste0('Kontoauszug importiert (',
                                nrow(createPiaData),
                                ' Datensätze wurden erstellt)'))
                createAlert(session, 'taskInfo', 'successImport',
                            style = 'success', append = TRUE,
                            title = 'Kontodaten Import',
                            content = paste0(nrow(createPiaData), 
                                            ' Datensätze wurden importiert'))
                # output$bankImportInfo <- renderUI(paste0(nrow(createPiaData), 
                #                                          ' Datensätze wurden importiert'))
                data <- data.frame()
                if(nrow(piaData) > 0){
                        if(nrow(createPiaData) > 0) {
                                data <- rbind(piaData[, c('date', 'description', 'id', 'value')], 
                                              createPiaData)
                        } else {
                                data <- piaData[, c('date', 'description', 'id', 'value')]
                        }
                } else {
                        if(nrow(createPiaData) > 0) {
                                data <- createPiaData
                        }
                }
                output$bankPlot <- renderPlotly({
                        pdf(NULL)
                        bankPlotly(data)
                })
                output$dataSheet = renderRHandsontable({
                        DF <- data.frame()
                        if(nrow(data) > 0){
                                data <- data[!(is.na(data[[appFieldKey]]) | 
                                               as.character(data[[appFieldKey]]) == 'NA'), ]
                                suppressWarnings(DF <- hot_dat2DF(data, repoStruct, TRUE))
                        }
                        # write data to Hot
                        setHot(DF)
                        # nice formatting
                        if(nrow(DF)>20) {
                                rhandsontable(DF, useTypes=TRUE, height=400) %>%
                                        hot_table(highlightCol=TRUE, highlightRow=TRUE,
                                                  allowRowEdit=TRUE) %>%
                                        hot_col('Betrag', width=80) %>%
                                        hot_col('Beschreibung', width=600)
                        } else {
                                rhandsontable(DF, useTypes=TRUE) %>%
                                        hot_table(highlightCol=TRUE, highlightRow=TRUE,
                                                  allowRowEdit=TRUE) %>%
                                        hot_col('Betrag', width=80) %>%
                                        hot_col('Beschreibung', width=600)
                        }
                })
        }        
})

observeEvent(input$bankInstitute, {
        switch (input$bankInstitute,
                easy = {
                        updateSelectInput(session,
                                          'bankImportHeader', 
                                          selected = 2)
                        updateTextInput(session,
                                        'bankImportSep',
                                        value=';')
                        updateTextInput(session,
                                        'bankImportQuote',
                                        value = '\"')
                        updateTextInput(session,
                                        'bankImportDec',
                                        value = '.')
                        updateTextInput(session,
                                        'bankImportEncoding',
                                        value = 'ISO-8859-1')
                        updateTextInput(session,
                                        'bankImportDescEnc',
                                        value = 'ISO-8859-1')
                        updateTextInput(session,
                                        'bankImportDateFormat',
                                        value = '%d.%m.%Y')
                        updateNumericInput(session,
                                           'bankImportDateColumn',
                                           value = 3)
                        updateNumericInput(session,
                                           'bankImportDescColumn',
                                           value = 2)
                        updateNumericInput(session,
                                           'bankImportValueColumn',
                                           value = 5)
                        updateNumericInput(session,
                                           'bankImportValueSoll',
                                           value = 0)
                        updateNumericInput(session,
                                           'bankImportValueHaben',
                                           value = 0)
                },
                erste = {
                        updateSelectInput(session,
                                          'bankImportHeader', 
                                          selected = 1)
                        updateTextInput(session,
                                        'bankImportSep',
                                        value=';')
                        updateTextInput(session,
                                        'bankImportQuote',
                                        value = "\\\"")
                        updateTextInput(session,
                                        'bankImportDec',
                                        value = '.')
                        updateTextInput(session,
                                        'bankImportEncoding',
                                        value = 'ISO-8859-1')
                        updateTextInput(session,
                                        'bankImportDescEnc',
                                        value = 'latin1')
                        updateTextInput(session,
                                        'bankImportDateFormat',
                                        value = '%d.%m.%y')
                        updateNumericInput(session,
                                           'bankImportDateColumn',
                                           value = 2)
                        updateNumericInput(session,
                                           'bankImportDescColumn',
                                           value = 1)
                        updateNumericInput(session,
                                           'bankImportValueColumn',
                                           value = 3)
                        updateNumericInput(session,
                                           'bankImportValueSoll',
                                           value = 0)
                        updateNumericInput(session,
                                           'bankImportValueHaben',
                                           value = 0)
                },
                ingdiba = {
                        updateSelectInput(session,
                                          'bankImportHeader', 
                                          selected = 1)
                        updateTextInput(session,
                                        'bankImportSep',
                                        value=';')
                        updateTextInput(session,
                                        'bankImportQuote',
                                        value = "\\\"")
                        updateTextInput(session,
                                        'bankImportDec',
                                        value = '.')
                        updateTextInput(session,
                                        'bankImportEncoding',
                                        value = 'ISO-8859-1')
                        updateTextInput(session,
                                        'bankImportDescEnc',
                                        value = 'latin1')
                        updateTextInput(session,
                                        'bankImportDateFormat',
                                        value = '%d.%m.%Y')
                        updateNumericInput(session,
                                           'bankImportDateColumn',
                                           value = 3)
                        updateNumericInput(session,
                                           'bankImportDescColumn',
                                           value = 2)
                        updateNumericInput(session,
                                           'bankImportValueColumn',
                                           value = 0)
                        updateNumericInput(session,
                                           'bankImportValueSoll',
                                           value = 5)
                        updateNumericInput(session,
                                           'bankImportValueHaben',
                                           value = 6)
                },
                ba = {
                        updateSelectInput(session,
                                          'bankImportHeader', 
                                          selected = 1)
                        updateTextInput(session,
                                        'bankImportSep',
                                        value=';')
                        updateTextInput(session,
                                        'bankImportQuote',
                                        value = "\\\"")
                        updateTextInput(session,
                                        'bankImportDec',
                                        value = '.')
                        updateTextInput(session,
                                        'bankImportEncoding',
                                        value = 'macroman')
                        updateTextInput(session,
                                        'bankImportDescEnc',
                                        value = 'macroman')
                        updateTextInput(session,
                                        'bankImportDateFormat',
                                        value = '%d.%m.%y')
                        updateNumericInput(session,
                                           'bankImportDateColumn',
                                           value = 1)
                        updateNumericInput(session,
                                           'bankImportDescColumn',
                                           value = 3)
                        updateNumericInput(session,
                                           'bankImportValueColumn',
                                           value = 6)
                        updateNumericInput(session,
                                           'bankImportValueSoll',
                                           value = 0)
                        updateNumericInput(session,
                                           'bankImportValueHaben',
                                           value = 0)
                },
                {
                        updateSelectInput(session,
                                          'bankImportHeader', 
                                          selected = 1)
                        updateTextInput(session,
                                        'bankImportSep',
                                        value=';')
                        updateTextInput(session,
                                        'bankImportQuote',
                                        value = '\"')
                        updateTextInput(session,
                                        'bankImportDec',
                                        value = '.')
                        updateTextInput(session,
                                        'bankImportEncoding',
                                        value = 'utf-8')
                        updateTextInput(session,
                                        'bankImportDescEnc',
                                        value = 'latin1')
                        updateTextInput(session,
                                        'bankImportDateFormat',
                                        value = '%d.%m.%Y')
                        updateNumericInput(session,
                                           'bankImportDateColumn',
                                           value = 1)
                        updateNumericInput(session,
                                           'bankImportDescColumn',
                                           value = 3)
                        updateNumericInput(session,
                                           'bankImportValueColumn',
                                           value = 2)
                        updateNumericInput(session,
                                           'bankImportValueSoll',
                                           value = 0)
                        updateNumericInput(session,
                                           'bankImportValueHaben',
                                           value = 0)
                }
        )
})

observeEvent(input$saveReference, {
        app <- currApp()
        if(length(all.equal(app, logical(0)))>1){
                url <- itemsUrl(app[['url']], paste0(app[['app_key']],
                                                     '.reference'))
                rv <- input$referenceValue
                data <- list(date=as.character(input$referenceDate),
                             value=input$referenceValue)
                data$`_oydRepoName` <- 'Referenzwert'
                refData <- readItems(app, url)
                if(nrow(refData) > 0){
                        retVal <- updateItem(app, url, data, refData$id)
                        createAlert(session, 'taskInfo', 'successReference',
                                    style = 'success', append = TRUE,
                                    title = 'Referenzwert festlegen',
                                    content = 'Der Referenzwert wurde aktualisiert.')
                        writeLog('Referenzwert wurde aktualisiert')
                        
                } else {
                        retVal <- writeItem(app, url, data)
                        createAlert(session, 'taskInfo', 'successReference',
                                    style = 'success', append = TRUE,
                                    title = 'Referenzwert festlegen',
                                    content = 'Der Referenzwert wurde gespeichert')
                        writeLog('Referenzwert wurde gespeichert')
                }
        }
})


observeEvent(input$referenceValue, {
        if(is.na(input$referenceValue)){
                app <- currApp()
                if(length(all.equal(app, logical(0)))>1){
                        url <- itemsUrl(app[['url']], paste0(app[['app_key']],
                                                             '.reference'))
                        refData <- readItems(app, url)
                        if(nrow(refData) == 1){
                                updateDateInput(session,
                                                'referenceDate',
                                                value = refData$date)
                                updateTextInput(session,
                                                'referenceValue',
                                                value = refData$value)       
                        }
                }
        }
})

observeEvent(input$mailerReceiver, {
        email <- input$mailerReceiver
        if(validEmail(email)){
                app <- currApp()
                schedulerEmail <- getPiaSchedulerEmail(app)
                if(length(schedulerEmail) == 0) {
                        writeSchedulerEmail(
                                app,
                                appTitle,
                                email,
                                'Download Kontoauszug',
                                'Lade deinen aktuellen Kontoauszug herunter und speichere diesen in deinem Datentresor!',
                                '0 9 1 * *')
                        createAlert(session, 'taskInfo', 'successEmail',
                                    style = 'success', append = TRUE,
                                    title = 'Erinnerungsemail konfigurieren',
                                    content = 'Die monatliche Erinnerung per Email wurde eingerichtet.')
                } else {
                        writeSchedulerEmail(
                                app,
                                appTitle,
                                email,
                                'Download Kontoauszug',
                                'Lade deinen aktuellen Kontoauszug herunter und speichere diesen in deinem Datentresor!',
                                '0 9 1 * *',
                                id=schedulerEmail[['id']])
                        createAlert(session, 'taskInfo', 'successEmail',
                                    style = 'success', append = TRUE,
                                    title = 'Erinnerungsemail konfigurieren',
                                    content = 'Die monatliche Erinnerung per Email wurde aktualisiert')
                }
        }
})

output$icalReminder <- downloadHandler(
        filename = 'oyd-bank.ics',
        content = function(file) {
                icsData <- paste('BEGIN:VCALENDAR',
                                 'CALSCALE:GREGORIAN',
                                 'VERSION:2.0',
                                 'BEGIN:VEVENT',
                                 'SEQUENCE:0',
                                 'SUMMARY:OwnYourData - Kontoauszug importieren',
                                 paste0('DTSTART;VALUE=DATE:', format(seq(Sys.Date(), length=2, by='1 month')[2],"%Y%m"),'01'),
                                 'RRULE:FREQ=MONTHLY;INTERVAL=1;BYMONTHDAY=1',
                                 'END:VEVENT',
                                 'END:VCALENDAR',
                                 sep="\n")
                writeChar(icsData, file)
        }
)
