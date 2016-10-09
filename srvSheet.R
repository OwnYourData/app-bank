# show available data in an Excel like UI
# last update: 2016-07-28

values = reactiveValues()
setHot = function(x) values[["dataSheet"]] = x

preserveDate <- function(data){
        d <- as.list(data)
        if('date' %in% appFieldTypes){
                d[appFieldTypes == 'date'] <- 
                        as.character(d[appFieldTypes == 'date'][[1]])
        }
        d
}

preserveUTF8 <- function(data){
        d <- as.list(data)
        if(length(all.equal(app, logical(0)))>1){
                for(i in 1:length(d)){
                        if(appFieldTypes[i] == 'string'){
                                d[i] <- iconv(as.character(d[i][[1]]),
                                              from='latin1',
                                              to='UTF-8')
                        }
                }
        }
        d
        # d[appFieldTypes == 'string'] <-
        #         iconv(as.character(d[appFieldTypes == 'string'][[1]]), 
        #               from='latin1', to='utf-8')
}

bulkUpdateItems <- function(sheetData){
        app <- currApp()
        if(length(all.equal(app, logical(0)))>1){
                piaData <- currData()
                url <- itemsUrl(app[['url']], app[['app_key']])
                
                sheetDigest <- createDigest(sheetData, appFields)
                piaDigest <- createDigest(piaData, appFields)
                removePiaData <- 
                        piaData[!(piaDigest$digest %in% sheetDigest$digest), , 
                                drop=FALSE]
                createPiaData <- 
                        sheetData[!(sheetDigest$digest %in% piaDigest$digest), , 
                                  drop=FALSE]
                recCnt <- nrow(removePiaData) + nrow(createPiaData)
                if(recCnt > 0){
                        withProgress(message='Daten aktualisieren', 
                                     max=recCnt, {
                                             cnt <- 0
                                             if(nrow(removePiaData) > 0){
                                                     for(i in 1:nrow(removePiaData)){
                                                             cnt <- cnt + 1
                                                             id <- removePiaData[i, 'id']
                                                             deleteItem(app, url, id)
                                                             setProgress(value=cnt,
                                                                         detail=paste0(cnt, '/', recCnt,
                                                                                       ' Datensätze'))
                                                             
                                                     }
                                             }
                                             if(nrow(createPiaData) > 0){
                                                     for(i in 1:nrow(createPiaData)){
                                                             cnt <- cnt + 1
                                                             myTmp <- createPiaData[i, appFields, drop=FALSE]
                                                             dataItem <- preserveUTF8(preserveDate(
                                                                     createPiaData[i, appFields, drop=FALSE]))
                                                             dataItem <- appData(dataItem)
                                                             writeItem(app, url, dataItem)
                                                             setProgress(value=cnt,
                                                                         detail=paste0(cnt, '/', recCnt,
                                                                                       ' Datensätze'))
                                                     }
                                             }
                                     })
                }
        }
}

observe({
        if(!is.null(input$dataSheet)){
                suppressWarnings(
                        values[["dataSheet"]] <- hot_to_r(input$dataSheet))
                output$dataSheetDirty <- renderUI('Daten wurden geändert')
        }
})

observe({
        if(!is.null(input$mobileDataSheet)){
                suppressWarnings(
                        values[["dataSheet"]] <- hot_to_r(input$mobileDataSheet))
                output$mobielDataSheetDirty <- renderUI('Daten wurden geändert')
        }
})

rhotRender <- function(DF){
        # write data to Hot
        setHot(DF)
        # nice formatting
        if(nrow(DF)>20) {
                rhandsontable(DF, useTypes=TRUE, height=400) %>%
                        hot_table(highlightCol=TRUE, highlightRow=TRUE,
                                  allowRowEdit=TRUE) %>%
                        hot_cols(colWidths=appFieldsDisplayWidth)
        } else {
                rhandsontable(DF, useTypes=TRUE) %>%
                        hot_table(highlightCol=TRUE, highlightRow=TRUE,
                                  allowRowEdit=TRUE) %>%
                        hot_cols(colWidths=appFieldsDisplayWidth)
        }
}
observeEvent(input$saveSheet, {
        sheetRecords <- values[["dataSheet"]]
        if (!is.null(sheetRecords)) {
                colnames(sheetRecords) <- appFields
                sheetRecords <- 
                        sheetRecords[!is.na(sheetRecords[appFieldKey]), , 
                                     drop=FALSE]
                data <- bulkUpdateItems(sheetRecords)
                output$dataSheet <- renderRHandsontable({
                        suppressWarnings(DF <- hot_dat2DF(sheetRecords, TRUE))
                        rhotRender(DF)
                })  
        }
        output$dataSheetDirty <- renderText('')
})

observeEvent(input$mobileSaveSheet, {
        sheetRecords <- values[["dataSheet"]]
        if (!is.null(sheetRecords)) {
                colnames(sheetRecords) <- appFields
                sheetRecords <- sheetRecords[!is.na(sheetRecords[appFieldKey]),]
                data <- bulkUpdateItems(sheetRecords)        
                output$mobileDataSheet <- renderRHandsontable({
                        suppressWarnings(DF <- hot_dat2DF(sheetRecords, TRUE))
                        rhotRender(DF)
                })  
        }
        output$mobileDataSheetDirty <- renderText('')
})

hot_dat2DF <- function(data, orderDecreasing){
        DF <- data.frame()
        if(nrow(data) > 0){
                data <- data[, appFields, drop=FALSE]
                data <- data[!is.na(data[appFieldKey]), , drop=FALSE]
                DF <- rbind(data, rep(NA, length(appFields)))
        }
        if(nrow(data) == 0){
                initVal <- vector()
                for(i in 1:length(appFields)){
                        switch(appFieldInits[i],
                               today = {
                                       initVal <- c(initVal, 
                                                    as.character(as.Date(Sys.Date())))
                               },
                               zero = {
                                       initVal <- c(initVal, 
                                                    0)
                               }, 
                               empty = {
                                       initVal <- c(initVal, 
                                                    '')
                               }
                        )
                }
                names(initVal) <- appFields
                DF <- data.frame(lapply(initVal, type.convert), 
                                 stringsAsFactors=FALSE)
        }
        for(i in 1:length(appFields)){
                switch(appFieldTypes[i],
                       date = {
                               DF[, appFields[i]] <-
                                       as.Date(DF[, appFields[i]], 
                                               origin="1970-01-01")
                       },
                       double = {
                               DF[, appFields[i]] <-
                                       as.double(DF[, appFields[i]])
                       }, 
                       string = {
                               DF[, appFields[i]] <-
                                       as.character(DF[, appFields[i]])
                       }
                )
        }
        if(!missing(orderDecreasing)) {
                if(nrow(DF) > 1){
                        DF <- DF[order(DF[, appFieldKey, drop=FALSE], 
                                       decreasing = orderDecreasing), , 
                                 drop=FALSE]
                }
                if(!is.null(nrow(DF))){
                        rownames(DF) <- 1:nrow(DF)
                }
        }
        if(!is.null(nrow(DF))){
                colnames(DF) <- appFieldsDisplay
        }
        DF
}

# render Excel View UI
output$dataSheet <- renderRHandsontable({
        DF <- data.frame()
        if (is.null(input$dataSheet)) {
                data <- currData()
                if(is.null(data[[appFieldKey]])){
                        data <- data.frame()
                } else {
                        if(nrow(data) > 0){
                                data <- data[!(is.na(data[[appFieldKey]]) | 
                                                       data[[appFieldKey]] == 'NA'), ]
                        }
                }
                #                suppressWarnings(DF <- hot_dat2DF(data, TRUE))
                DF <- hot_dat2DF(data, TRUE)
        } else {
                suppressWarnings(data <- hot_to_r(input$dataSheet))
                colnames(data) <- appFields
                suppressWarnings(DF <- hot_dat2DF(data))
        }
        rhotRender(DF)
})

# render mobile Excel View UI
output$mobileDataSheet = renderRHandsontable({
        DF <- data.frame()
        if (is.null(input$dataSheet)) {
                data <- currData()
                if(nrow(data) > 0){
                        data <- data[!(is.na(data[[appFieldKey]]) | 
                                               data[[appFieldKey]] == 'NA'), ]
                }
                suppressWarnings(DF <- hot_dat2DF(data, TRUE))
        } else {
                suppressWarnings(data <- hot_to_r(input$dataSheet))
                colnames(data) <- appFields
                suppressWarnings(DF <- hot_dat2DF(data))
        }
        rhotRender(DF)
})

output$exportCSV <- downloadHandler(
        filename = paste0(appName, '.csv'),
        content = function(file) {
                write.csv(values[["dataSheet"]], file)
        }
)
