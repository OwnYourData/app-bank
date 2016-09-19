# application specific logic
# last update:2016-09-12

source('oyd_dateselect.R', local=TRUE)
source('oyd_email.R', local=TRUE)
source('appLogicBankImport.R', local=TRUE)

bankPlotly <- function(data){
        closeAlert(session, 'myDataStatus')
        if(nrow(data) > 0){
                mymin <- as.Date(input$dateRange[1], "%d.%m.%Y")
                mymax <- as.Date(input$dateRange[2], "%d.%m.%Y")
                if(mymax > mymin){
                        daterange <- seq(mymin, mymax, "days")
                        data$dat <- as.Date(data$date)
                        data <- data[order(data[, 'dat']),]
                        data <- data[data$dat %in% daterange, ]
                        if(nrow(data) > 0){
                                #euro <- dollar_format(prefix = "\u20ac ", suffix = "")
                                # all data until reference value
                                app <- currApp()
                                url <- itemsUrl(app[['url']], paste0(app[['app_key']],
                                                                     '.reference'))
                                refData <- readItems(app, url)
                                if(nrow(refData) == 1){
                                        subData <- data[as.Date(as.character(data$date)) < as.Date(refData$date), ]
                                        startValue <- refData$value - sum(subData$value)
                                        minDate <- min(data$dat)
                                        refRow <- data.frame(as.character(as.Date(minDate)-1),
                                                    'Startbetrag',
                                                    -1,
                                                    startValue,
                                                    'Starbetrag',
                                                    as.Date(minDate)-1)
                                        colnames(refRow) <- colnames(data)
                                        data <- rbind(refRow, data)
                                }
                                data$cumsum <- cumsum(data$value)
                                gg <- ggplot(data, 
                                             aes(x=dat, y=cumsum, 
                                                 text=paste0(
                                                         #format(dat, '%A, %d %b %Y'),
                                                         format(dat, '%d.%m.%Y'),
                                                         ': \u20ac ',
                                                         formatC(as.numeric(value), format='f', digits=2, big.mark=','), 
                                                         '<br>',
                                                         description
                                                 ))) + #label=paste0('Betrag:<br>',description), 
                                        scale_y_continuous(labels=dollar_format(prefix="€")) + 
                                        xlab('') +
                                        ylab('') +
                                        geom_line(group=1) + 
                                        geom_point() + 
                                        theme_bw()
                                ggplotly(gg, tooltip=c('text'))
                        } else {
                                createAlert(session, 'dataStatus', alertId = 'myDataStatus',
                                            style = 'warning', append = FALSE,
                                            title = 'Keine Daten im gewählten Zeitfenster',
                                            content = 'Für das ausgewählte Zeitfenster sind keine Daten vorhanden.')
                                plotly_empty()
                        }
                } else {
                        createAlert(session, 'dataStatus', alertId = 'myDataStatus',
                                    style = 'warning', append = FALSE,
                                    title = 'Ungültiges Zeitfenster',
                                    content = 'Im ausgewählten Zeitfenster liegt das End-Datum vor dem Beginn-Datum. Korriege die Eingabe!')
                        plotly_empty()
                }
        } else {
                createAlert(session, 'dataStatus', alertId = 'myDataStatus',
                            style = 'warning', append = FALSE,
                            title = 'Keine Daten in der PIA vorhanden',
                            content = 'Derzeit sind noch keine Daten in der PIA erfasst. Wechsle zu "Datenquellen" und importiere Kontodaten oder richte auch gleich ein Erinnerungsmail ein!')
                plotly_empty()
        }
}

output$bankPlot <- renderPlotly({
        data <- currData()
        pdf(NULL)
        bankPlotly(data)
})

output$mobileBankPlot <- renderPlot({
        data <- currData()
        if(nrow(data)>0){
                data$dat <- as.Date(as.character(data$date))
                data <- data[order(data[, 'dat']),]
                data$cumsum <- cumsum(data$value)
                plot(x=data$dat, y=data$cumsum, type='l', xlab='', ylab='')
        }
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

appData <- function(data){
        data$descriptionOrig <- data$description
        data
}

observeEvent(input$bankImport, {
        importData <- csv_import()
        app <- currApp()
        createPiaData <- data.frame()
        if(length(all.equal(app, logical(0)))>1){
                piaData <- currData()
                url <- itemsUrl(app[['url']], app[['app_key']])
                
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
                                                                     createPiaData[i, appFields])
                                                             dataItem$descriptionOrig <- dataItem$description
                                                             writeItem(app, url, dataItem)
                                                             setProgress(value=cnt,
                                                                         detail=paste0(cnt, '/', recCnt,
                                                                                       ' Datensätze'))
                                                     }
                                             }
                                     })
                }
                output$bankImportInfo <- renderUI(paste0(nrow(createPiaData), 
                                                         ' Datensätze wurden importiert'))
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
                                suppressWarnings(DF <- hot_dat2DF(data, TRUE))
                        }
                        # write data to Hot
                        setHot(DF)
                        # nice formatting
                        if(nrow(DF)>20) {
                                rhandsontable(DF, useTypes=TRUE, height=400) %>%
                                        hot_table(highlightCol=TRUE, highlightRow=TRUE,
                                                  allowRowEdit=TRUE)
                        } else {
                                rhandsontable(DF, useTypes=TRUE) %>%
                                        hot_table(highlightCol=TRUE, highlightRow=TRUE,
                                                  allowRowEdit=TRUE)
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

output$saveReferenceInfo <- renderUI({
        app <- currApp()
        url <- itemsUrl(app[['url']], paste0(app[['app_key']],
                                             '.reference'))
        refData <- readItems(app, url)
        if(nrow(refData) == 1){
                updateDateInput(session, 'referenceDate',
                                value = refData$date)
                updateNumericInput(session, 'referenceValue',
                                   value = refData$value)
        }
        ''
})

observeEvent(input$saveReference, {
        app <- currApp()
        url <- itemsUrl(app[['url']], paste0(app[['app_key']],
                                             '.reference'))
        data <- list(date=as.character(input$referenceDate),
                     value=input$referenceValue)
        refData <- readItems(app, url)
        if(nrow(refData) > 0){
                retVal <- updateItem(app, url, data, refData$id)
                output$saveReferenceInfo <- renderUI('Referenzwert aktualisiert')
        } else {
                retVal <- writeItem(app, url, data)
                output$saveReferenceInfo <- renderUI('Referenzwert gespeichert')
        }
        
})

observeEvent(input$endMailer, {
        app <- currApp()
        url <- itemsUrl(app[['url']], schedulerKey())
        data <- readItems(app, url)
        if(nrow(data) > 0){
                retVal <- deleteItem(app, url, data$id)
        }
        updateTextInput(session, 'mailerReceiver', value='')
        updateSelectInput(session, 'mailerInterval', selected = 1)
})