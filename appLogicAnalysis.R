# calc statistic properties for each group
# last update:2016-09-28

# get stored group configs
readGrpConfigItems <- function(){
        app <- currApp()
        cfgItems <- data.frame()
        if(length(app) > 0){
                url <- itemsUrl(app[['url']], 
                                paste0(app[['app_key']],
                                       '.group'))
                cfgItems <- readItems(app, url)
                if(nrow(cfgItems) > 0){
                        rownames(cfgItems) <- cfgItems$name
                        cfgItems <- cfgItems[, c('descFilter', 
                                                 'valFilter',
                                                 'valFilterValue')]
                }
        }
        cfgItems
}

collectGrpConfigItems <- function(){
        piaGroupConfigList <- readGrpConfigItems()
        if(nrow(piaGroupConfigList) > 0){
                piaGroupConfigList$valFilterValue <- 
                        as.character(piaGroupConfigList$valFilterValue)
        }
        rbind(staticGroupConfigList, piaGroupConfigList)
}

# show attributes on selecting an item in the GroupConfig List
observeEvent(input$grpConfigList, {
        selItem <- input$grpConfigList
        if(length(selItem)>1){
                selItem <- selItem[1]
                updateSelectInput(session, 'grpConfigList', selected = selItem)
        }
        allItems <- collectGrpConfigItems()
        selItemName <- selItem
        selItemDescFilter <- allItems[rownames(allItems) == selItem, 'descFilter']
        selItemValFilter <- allItems[rownames(allItems) == selItem, 'valFilter']
        selItemValFilterValue <- allItems[rownames(allItems) == selItem, 'valFilterValue']
        updateTextInput(session, 'grpConfigItemName',
                        value = selItemName)
        updateTextInput(session, 'grpConfigItemDescFilter',
                        value = trim(as.character(selItemDescFilter)))
        updateSelectInput(session, 'grpConfigItemValFilter', 
                          selected = trim(as.character(selItemValFilter)))
        updateNumericInput(session, 'grpConfigItemValFilterValue',
                           value = as.numeric(trim(as.character(selItemValFilterValue))))
})

observeEvent(input$addGrpConfigItem, {
        errMsg   <- ''
        itemName <- input$grpConfigItemName
        itemDescFilter <- input$grpConfigItemDescFilter
        itemValFilter <- input$grpConfigItemValFilter
        if(itemValFilter == 'not'){
                itemValFilterValue <- ''
        } else {
                itemValFilterValue <- as.character(input$grpConfigItemValFilterValue)
        }
        allItems <- collectGrpConfigItems()
        if(itemName %in% rownames(allItems)){
                errMsg <- 'Name bereits vergeben'
        }
        if(errMsg == ''){
                app <- currApp()
                url <- itemsUrl(app[['url']], 
                                paste0(app[['app_key']],
                                       '.group'))
                data <- list(name=itemName,
                             descFilter=itemDescFilter,
                             valFilter=itemValFilter,
                             valFilterValue=itemValFilterValue)
                writeItem(app, url, data)
                initNames <- rownames(allItems)
                allItems$descFilter <- as.character(allItems$descFilter )
                allItems$valFilter <- as.character(allItems$valFilter)
                allItems$valFilterValue <- as.numeric(as.character(allItems$valFilterValue))
                allItems <- rbind(allItems, c(itemDescFilter, 
                                              itemValFilter,
                                              itemValFilterValue))
                
                updateSelectInput(session, 'grpConfigList',
                                  choices = c(initNames, itemName),
                                  selected = NA)
                updateTextInput(session, 'grpConfigItemName',
                                value = '')
                updateTextInput(session, 'grpConfigItemDescFilter',
                                value = '')
                updateSelectInput(session, 'grpConfigItemValFilter', 
                                  selected = 'not')
                updateNumericInput(session, 'grpConfigItemValFilterValue',
                                   value = NA)
                rownames(allItems) <- c(initNames, itemName)
                output$groupAnalysis <- DT::renderDataTable(datatable({
                        t(apply(allItems, 1, calcGroupAnalysis))
                }, options = list(language = list(url = '//cdn.datatables.net/plug-ins/1.10.11/i18n/German.json'))) 
                %>% formatCurrency(c('Summe', 'Durchschnitt', 'Min', 'Max'), 
                                   currency = "\U20AC", interval = 3, 
                                   mark = ",", digits=2)
                )
                
        }
        closeAlert(session, 'myGrpConfigItemStatus')
        if(errMsg != ''){
                createAlert(session, 'grpConfigItemStatus', 
                            'myGrpConfigItemStatus',
                            title = 'Achtung',
                            content = errMsg,
                            style = 'warning',
                            append = 'false')
        }
})

observeEvent(input$updateGrpConfigItem, {
        errMsg   <- ''
        selItem <- input$grpConfigList
        itemName <- input$grpConfigItemName
        itemDescFilter <- input$grpConfigItemDescFilter
        itemValFilter <- input$grpConfigItemValFilter
        if(itemValFilter == 'not'){
                itemValFilterValue <- NA
        } else {
                itemValFilterValue <- input$grpConfigItemValFilterValue
        }
        if(is.null(selItem)){
                errMsg <- 'Keine Gruppe ausgewählt.'
        }
        if(selItem %in% staticGroupConfigUiList){
                errMsg <- 'Standard-Gruppe kann nicht verändert werden.'
        }
        if(errMsg == ''){
                allItems <- collectGrpConfigItems()
                app <- currApp()
                url <- itemsUrl(app[['url']], 
                                paste0(app[['app_key']],
                                       '.group'))
                data <- list(name=itemName,
                             descFilter=itemDescFilter,
                             valFilter=itemValFilter,
                             valFilterValue=itemValFilterValue)
                cfgItems <- readItems(app, url)
                id <- cfgItems[cfgItems$name == selItem, 'id']
                updateItem(app, url, data, id)
                newRowNames <- rownames(allItems)
                newRowNames[newRowNames == selItem] <- itemName
                updateSelectInput(session, 'grpConfigList',
                                  choices = newRowNames,
                                  selected = NA)
                updateTextInput(session, 'grpConfigItemName',
                                value = '')
                updateTextInput(session, 'grpConfigItemDescFilter',
                                value = '')
                updateSelectInput(session, 'grpConfigItemValFilter', 
                                  selected = 'not')
                updateNumericInput(session, 'grpConfigItemValFilterValue',
                                   value = NA)
                
                allItems <- collectGrpConfigItems()
                allItems[rownames(allItems) == selItem, 'descFilter'] <-
                        itemDescFilter
                allItems[rownames(allItems) == selItem, 'valFilter'] <-
                        itemValFilter
                allItems[rownames(allItems) == selItem, 'valFilterValue'] <-
                        itemValFilterValue
                newRowNames <- rownames(allItems)
                newRowNames[newRowNames == selItem] <- itemName
                rownames(allItems) <- newRowNames
                output$groupAnalysis <- DT::renderDataTable(datatable({
                        t(apply(allItems, 1, calcGroupAnalysis))
                }, options = list(language = list(url = '//cdn.datatables.net/plug-ins/1.10.11/i18n/German.json'))) 
                %>% formatCurrency(c('Summe', 'Durchschnitt', 'Min', 'Max'), 
                                   currency = "\U20AC", interval = 3, 
                                   mark = ",", digits=2)
                )
        }
        closeAlert(session, 'myGrpConfigItemStatus')
        if(errMsg != ''){
                createAlert(session, 'grpConfigItemStatus', 
                            'myGrpConfigItemStatus',
                            title = 'Achtung',
                            content = errMsg,
                            style = 'warning',
                            append = 'false')
        }
})

observeEvent(input$delGrpConfigList, {
        selItem <- input$grpConfigList
        errMsg <- ''
        if(is.null(selItem)){
                errMsg <- 'Keine Gruppe ausgewählt.'
        } else {
                if(selItem %in% staticGroupConfigUiList){
                        errMsg <- 'Standard-Gruppe kann nicht entfernt werden.'
                }
        }
        if(errMsg == ''){
                allItems <- collectGrpConfigItems()
                newRowNames <- rownames(allItems)
                app <- currApp()
                url <- itemsUrl(app[['url']], 
                                paste0(app[['app_key']],
                                       '.group'))
                cfgItems <- readItems(app, url)
                id <- cfgItems[cfgItems$name == selItem, 'id']
                deleteItem(app, url, id)
                newRowNames <- newRowNames[newRowNames != selItem]
                allItems <- allItems[rownames(allItems) != selItem, ]
                updateSelectInput(session, 'grpConfigList',
                                  choices = newRowNames,
                                  selected = NA)
                updateTextInput(session, 'grpConfigItemName',
                                value = '')
                updateTextInput(session, 'grpConfigItemDescFilter',
                                value = '')
                updateSelectInput(session, 'grpConfigItemValFilter', 
                                  selected = 'not')
                updateNumericInput(session, 'grpConfigItemValFilterValue',
                                   value = NA)
                output$groupAnalysis <- DT::renderDataTable(datatable({
                        t(apply(allItems, 1, calcGroupAnalysis))
                }, options = list(language = list(url = '//cdn.datatables.net/plug-ins/1.10.11/i18n/German.json'))) 
                %>% formatCurrency(c('Summe', 'Durchschnitt', 'Min', 'Max'), currency = "\U20AC", interval = 3, mark = ",", digits=2)
                )
                
        }
        closeAlert(session, 'myGrpConfigItemStatus')
        if(errMsg != ''){
                createAlert(session, 'grpConfigItemStatus', 
                            'myGrpConfigItemStatus',
                            title = 'Achtung',
                            content = errMsg,
                            style = 'warning',
                            append = 'false')
        }
        
})

calcGroupAnalysis <- function(group_select){
        data <- currDataSelect()
        cnt <- 0
        sum <- NA
        avg <- NA
        min <- NA
        max <- NA
        if(nrow(data) > 0){
                data$description <- as.character(data$description)
                if(!is.na(group_select['descFilter'])){
                        if(group_select['descFilter'] != ''){
                                data <- data[grepl(group_select['descFilter'], 
                                                   data$description, 
                                                   ignore.case = TRUE), 
                                             ]
                        }
                        if(group_select['valFilter'] == '<'){
                                data <- data[data$value < as.numeric(group_select['valFilterValue']), ]
                        }
                        if(group_select['valFilter'] == '>'){
                                data <- data[data$value > as.numeric(group_select['valFilterValue']), ]
                        }
                        if(group_select['valFilter'] == '='){
                                data <- data[data$value == as.numeric(group_select['valFilterValue']), ]
                        }
                        cnt <- nrow(data)
                        sum <- NA
                        avg <- NA
                        min <- NA
                        max <- NA
                }
                if(cnt > 0){
                        sum <- sum(data$value)
                        avg <- mean(data$value)
                        min <- min(data$value)
                        max <- max(data$value)
                }
        }
        c(Anzahl=cnt, Summe=sum, Durchschnitt=avg, Min=min, Max=max)
}

getGroupItems <- function(group_select){
        data <- currDataSelect()
        if(nrow(data) > 0){
                data$description <- as.character(data$description)
                if(!is.na(group_select['descFilter'])){
                        if(group_select['descFilter'] != ''){
                                data <- data[grepl(group_select['descFilter'], 
                                                   data$description, 
                                                   ignore.case = TRUE), 
                                             ]
                        }
                        if(group_select['valFilter'] == '<'){
                                data <- data[data$value < as.numeric(group_select['valFilterValue']), ]
                        }
                        if(group_select['valFilter'] == '>'){
                                data <- data[data$value > as.numeric(group_select['valFilterValue']), ]
                        }
                        if(group_select['valFilter'] == '='){
                                data <- data[data$value == as.numeric(group_select['valFilterValue']), ]
                        }
                        data
                } else {
                        data.frame()
                }
        } else {
                data.frame()
        }
}

observeEvent(input$showGroupDetails, {
        selItems <- input$groupAnalysis_rows_selected
        if(is.null(selItems)){
                createAlert(session, 'taskInfo', 'nothingSelect',
                            style = 'warning', append = FALSE,
                            title = 'Details für Auswahl',
                            content = 'Es sind keine Gruppen ausgewählt.')
        } else {
                closeAlert(session, 'nothingSelect')
                cfgItems <- collectGrpConfigItems()
                cfgItems <- cfgItems[selItems, ]
                allItems <- do.call(rbind, apply(cfgItems, 1, getGroupItems))
                itemDigest <- createDigest(allItems, appFields)
                save(allItems, itemDigest, file='tmpDetail.RData')
                allItems <- allItems[!duplicated(itemDigest$digest), ]
                data <- as.matrix(allItems[, c('date', 'value', 'description')])
                colnames(data) <- c('Datum', 'Betrag', 'Beschreibung')
                rownames(data) <- 1:nrow(data)
                #save(data, data1, cfgItems, selItems, allItems, file='tmpDetails.RData')
                output$groupAnalysisDetailList <- DT::renderDataTable(datatable({
                        data
                }, 
                selection = 'none', 
                options = list(language = list(url = '//cdn.datatables.net/plug-ins/1.10.11/i18n/German.json'),
                               aoColumnDefs = list(list(targets=2, class='dt-right'))))
                %>% formatCurrency(c('Betrag'), currency = "\U20AC", interval = 3, mark = ",", digits=2))
                toggleModal(session, 'groupAnalysisDetail')
        }
})

observeEvent(input$showGroupComparison, {
        selItems <- input$groupAnalysis_rows_selected
        if(is.null(selItems)){
                createAlert(session, 'groupInfo', 'nothingSelect',
                            style = 'warning', append = FALSE,
                            title = 'Vergleich anzeigen',
                            content = 'Es sind keine Gruppen ausgewählt.')
        } else {
                output$groupChart <- renderPlot({
                        renderGroupChart()
                })
        }
})

renderGroupChart <- function(){
        grpConfigList <<- collectGrpConfigItems()
        data <- data.frame(t(apply(grpConfigList, 1, calcGroupAnalysis)))
        selItems <- input$groupAnalysis_rows_selected
        if(!is.null(selItems)){
                data <- data[selItems, ]
                if(nrow(data) > 0){
                        data <- data[!is.na(data$Summe), ]
                        if(nrow(data) > 0){
                                closeAlert(session, 'nothingSelect')
                                data$Summe <- abs(as.numeric(data$Summe))
                                data$Gruppe <- rownames(data)
                                data <- data[, c('Gruppe', 'Summe')]
                                data$frac <- data$Summe / sum(data$Summe)
                                data <- data[order(data$frac), ]
                                data$ymax <- cumsum(data$frac)
                                data$ymin <- c(0, head(data$ymax, n=-1))
                                ggplot(data, 
                                       aes(fill=Gruppe, ymax=ymax, ymin=ymin, 
                                           xmax=4, xmin=2)) + 
                                        geom_rect(colour="grey50") + 
                                        coord_polar(theta="y") + 
                                        xlim(c(0, 4)) + 
                                        theme_bw() +
                                        geom_label(aes(label=paste(format(frac*100, digits=2, nsmall=1),'%'),
                                                       x=3.5,
                                                       y=(ymin+ymax)/2),
                                                   inherit.aes = TRUE, 
                                                   show.legend = FALSE) + 
                                        theme(panel.grid=element_blank()) + 
                                        theme(axis.text=element_blank()) + 
                                        theme(axis.ticks=element_blank()) + 
                                        theme(legend.text=element_text(size=16)) +
                                        theme(legend.title=element_text(size=18)) +
                                        xlab('') + ylab('')
                        }
                }
        }
}