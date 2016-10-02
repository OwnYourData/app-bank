# extension handling for Status and Source tab
# last update:2016-08-11

# get stored extensions
readExtItems <- function(app){
        if(missing(app)){
                app <- currApp()
        }
        extItems <- data.frame()
        if(length(app) > 0){
                url <- itemsUrl(app[['url']], 
                                paste0(app[['app_key']],'.extension'))
                extItems <- readItems(app, url)
                if(length(extItems)>0){
                        extItems <- data.frame(extItems)
                        # extItems <- t(as.data.frame(lapply(extItems, 
                        #        function(x){
                        #                c(x$id, x$name, x$ui, x$logic, x$group)
                        #         
                        # })))
                        colnames(extItems) <- c('id', 'name', 'ui', 'logic', 'group')
                        rownames(extItems) <- NULL
                        extItems <- as.data.frame(extItems, stringsAsFactors = FALSE)
                } else {
                        extItems <- data.frame()
                }
        }
        extItems
}

buildAllItems <- function(defaultItems, groupName, attributeName, app){
        allItems <- vector()
        extItems <- data.frame()
        if(missing(app)){
                extItems <- readExtItems()
        } else {
                extItems <- readExtItems(app)
        }
        if(nrow(extItems) > 0){
                allItems <- c(defaultItems, 
                              extItems[extItems$group == groupName, 
                                       attributeName])
        } else {
                allItems <- defaultItems
        }
        allItems
}

extRenderStr <- function(allItems, headerStr, footerStr, viewName, group){
        outputStr <- paste0(
                headerStr,
                buildTabList(allItems, viewName, group),
                footerStr
        )
}

collectItems <- function(tabsName, tabsUi, tabsLogic, groupName, app){
        if(missing(app)){
                allItemsName <- buildAllItems(tabsName, groupName, 'name')
                allItemsUI <- buildAllItems(tabsUi, groupName, 'ui')
                allItemsLogic <- buildAllItems(tabsLogic, groupName, 'logic')
        } else {
                allItemsName <- buildAllItems(tabsName, groupName, 'name', 
                                              app)
                allItemsUI <- buildAllItems(tabsUi, groupName, 'ui', 
                                            app)
                allItemsLogic <- buildAllItems(tabsLogic, groupName, 'logic', 
                                               app)
        }
        rbind(allItemsName, allItemsUI, allItemsLogic)
}

# render Status default tabs and extensions for desktop version
output$desktopUiStatusItemsRender <- renderUI({
        allItems <- collectItems(defaultStatTabsName,
                                 defaultStatTabsUI,
                                 defaultStatTabsLogic,
                                 'status')
        statTabUiList <<- allItems['allItemsName', ]
        checkAllItems(allItems, 'Status')
        headerStr <- "tabsetPanel(type='tabs', "
        footerStr <- ", uiStatusItemConfig())"
        outputStr <- extRenderStr(allItems['allItemsName',], 
                                  headerStr, footerStr, 'desktop', 'Status')
        eval(parse(text = outputStr), envir=.GlobalEnv)
        # outputStr <- "
        #         tabsetPanel(type='tabs', 
        #                 Tab1UI('desktopStatusItemsTab1'),
        #                 Tab2UI('desktopStatusItemsTab2'),
        #                 uiStatusItemConfig()
        #         )
        # "
})

# render Source default tabs and extensions for desktop version
output$desktopUiSourceItemsRender <- renderUI({
        allItems <- collectItems(defaultSrcTabsName,
                                 defaultSrcTabsUI,
                                 defaultSrcTabsLogic,
                                 'source')
        srcTabUiList <<- allItems['allItemsName', ]
        checkAllItems(allItems, 'Source')
        headerStr <- "tabsetPanel(type='tabs', "
        footerStr <- ", uiSourceItemConfig())"
        outputStr <- extRenderStr(allItems['allItemsName',], 
                                  headerStr, footerStr, 'desktop', 'Source')
        eval(parse(text = outputStr), envir=.GlobalEnv)
        # outputStr <- "
        #         tabsetPanel(type='tabs', 
        #                 Tab1UI('desktopSourceItemsTab1'),
        #                 Tab2UI('desktopSourceItemsTab2'),
        #                 uiSourceItemConfig()
        #         )
        # "
})

# render Status default tabs and extensions for mobile version
output$mobileUiStatusItemsRender <- renderUI({
        allItems <- collectItems(defaultStatTabsName,
                                 defaultStatTabsUI,
                                 defaultStatTabsLogic,
                                 'status')
        checkAllItems(allItems, 'Status')
        headerStr <- "
                navbarPage(
                        uiOutput('hdrImageLinkMobile'),
                        id='page',
                        collapsible=TRUE,
                        inverse=FALSE,
                        windowTitle=paste0(appTitle, ' | OwnYourData'),"
                
        footerStr <- "
                        ,
                        tabPanel('Datenblatt',
                                rHandsontableOutput('mobileDataSheet'),
                                br(),
                                htmlOutput('mobileDataSheetDirty', inline = TRUE),
                                conditionalPanel(
                                        condition = 'output.mobileDataSheetDirty != \"\"',
                                        tagList(actionButton('mobileSaveSheet', 
                                                'Daten in PIA speichern', 
                                                icon=icon('save'))))
        
                        ),
                        tabPanel('PIA Einrichtung',
                                h3('Authentifizierung'),
                                textInput('pia_urlMobile', 'Adresse:'),
                                textInput('app_keyMobile', 'Key:'),
                                textInput('app_secretMobile', 'Secret:'),
                                htmlOutput('mobileToken'),
                                actionButton('mobilePiaSave', 'Speichern')
                        )
                )"
        outputStr <- extRenderStr(allItems['allItemsName', ], 
                                  headerStr, footerStr, 'mobile', 'Status')
        eval(parse(text = outputStr), envir=.GlobalEnv)
        # outputStr <- "
        #         navbarPage(
        #                 uiOutput('hdrImageLinkMobile'),
        #                 id='page',
        #                 collapsible=TRUE,
        #                 inverse=FALSE,
        #                 windowTitle=paste0(appTitle, ' | OwnYourData'),
        #                 Tab1UI('mobileStatusItemsTab1'),
        #                 Tab2UI('mobileStatusItemsTab2'),
        #                 tabPanel('PIA Einrichtung',
        #                         h3('Authentifizierung'),
        #                         textInput('pia_urlMobile', 'Adresse:'),
        #                         textInput('app_keyMobile', 'Key:'),
        #                         textInput('app_secretMobile', 'Secret:'),
        #                         #actionButton('localStoreMobile', 
        #                         #        'Zugriffsinformationen speichern', 
        #                         #        icon('save')),
        #                         hr(),
        #                         htmlOutput('current_tokenMobile'),
        #                         htmlOutput('current_recordsMobile')
        #                 )
        #         )
        # "                
})

# show attributes on selecting an item in the status list
observeEvent(input$extStatusList, {
        selTab <- input$extStatusList
        if(length(selTab)>1){
                selTab <- selTab[1]
                updateSelectInput(session, 'extStatusList', selected = selTab)
        }
        allItems <- collectItems(defaultStatTabsName,
                                 defaultStatTabsUI, 
                                 defaultStatTabsLogic,
                                 'status')
        selUi <- allItems['allItemsUI', 
                          allItems['allItemsName',] == selTab]
        selLogic <- allItems['allItemsLogic', 
                             allItems['allItemsName',] == selTab]
        updateTextInput(session, 'extStatusItemName', 
                        value=selTab)
        updateTextInput(session, 'extStatusItemUi', 
                        value=trim(as.character(selUi)))
        updateTextInput(session, 'extStatusItemLogic', 
                        value=trim(as.character(selLogic)))
})

# show attributes on selecting an item in the source list
observeEvent(input$extSourceList, {
        selTab <- input$extSourceList
        if(length(selTab)>1){
                selTab <- selTab[1]
                updateSelectInput(session, 'extSourceList', selected = selTab)
        }
        allItems <- collectItems(defaultSrcTabsName,
                                 defaultSrcTabsUI, 
                                 defaultSrcTabsLogic,
                                 'source')
        selUi <- allItems['allItemsUI', 
                          allItems['allItemsName',] == selTab]
        selLogic <- allItems['allItemsLogic', 
                             allItems['allItemsName',] == selTab]
        updateTextInput(session, 'extSourceItemName', 
                        value=selTab)
        updateTextInput(session, 'extSourceItemUi', 
                        value=trim(as.character(selUi)))
        updateTextInput(session, 'extSourceItemLogic', 
                        value=trim(as.character(selLogic)))
})

# adding an external tab
addExtItem <- function(extName, extUi, extLogic, group,
                       defaultTabsName, defaultTabsUI, defaultTabsLogic){
        errMsg   <- ''
        if(is.null(extName) | (extName == '')){
                errMsg <- 'fehlender Name'
        }
        allItems <- collectItems(defaultTabsName,
                                 defaultTabsUI,
                                 defaultTabsLogic,
                                 tolower(group))
        if(extName %in% allItems['allItemsName',]){
                errMsg <- 'Name bereits vergeben'
        }
        if(errMsg == '') {
                output[[paste0('ext', group, 'ItemError')]] <- renderUI({ '' })
                allItems <- cbind(allItems, 
                                  c(extName, extUi, extLogic))
                if(group == 'Status'){
                        statTabUiList <<- allItems['allItemsName', ]
                        updateSelectInput(session, 'extStatusList', 
                                          choices = statTabUiList)
                } else {
                        srcTabUiList <<- allItems['allItemsName', ]
                        updateSelectInput(session, 'extSourceList', 
                                          choices = srcTabUiList)
                }
                checkAllItems(allItems, group)
                headerStr <- paste0("tabsetPanel(type='tabs', ",
                                    "selected='config', ")
                footerStr <- paste0(", ui", group, "ItemConfig())")
                outputStr <- extRenderStr(allItems['allItemsName',], 
                                          headerStr, footerStr, 'desktop',group)
                output[[paste0('desktopUi',group,'ItemsRender')]] <- renderUI({
                        eval(parse(text = outputStr), envir=.GlobalEnv)
                })
                
                app <- currApp()
                url <- itemsUrl(app[['url']], 
                                paste0(app[['app_key']],
                                       '.extension'))
                data <- list(group=tolower(group),
                             name=extName,
                             ui=extUi,
                             logic=extLogic)
                writeItem(app, url, data)
        } else {
                errMsg <- paste('Fehler:', errMsg)
        }
        errMsg
}

# handle adding status extension
observeEvent(input$addExtStatusItem, {
        extName  <- input$extStatusItemName
        extUi    <- input$extStatusItemUi
        extLogic <- input$extStatusItemLogic
        errMsg <- addExtItem(extName, extUi, extLogic, 'Status',
                             defaultStatTabsName,
                             defaultStatTabsUI,
                             defaultStatTabsLogic)
        output$extStatusItemError <- renderUI({ errMsg })
})

# handle adding source extension
observeEvent(input$addExtSourceItem, {
        extName  <- input$extSourceItemName
        extUi    <- input$extSourceItemUi
        extLogic <- input$extSourceItemLogic
        errMsg <- addExtItem(extName, extUi, extLogic, 'Source',
                             defaultSrcTabsName,
                             defaultSrcTabsUI,
                             defaultSrcTabsLogic)
        output$extSourceItemError <- renderUI({ errMsg })
})

# handle updating status extension
observeEvent(input$updateExtStatusItem, {
        selTab   <- input$extStatusList
        extName  <- input$extStatusItemName
        extUi    <- input$extStatusItemUi
        extLogic <- input$extStatusItemLogic
        errMsg <- ''
        if(is.null(selTab)){
                errMsg <- 'keine Auswahl'
        }
        if(selTab %in% defaultStatTabsName){
                errMsg <- 'Standardauswertung kann nicht verändert werden'
        }
        if(errMsg == ''){
                allItems <- collectItems(defaultStatTabsName,
                                         defaultStatTabsUI,
                                         defaultStatTabsLogic,
                                         'status')
                allItems['allItemsLogic',allItems['allItemsName',] == selTab] <-
                        extLogic
                allItems['allItemsUI', allItems['allItemsName',] == selTab] <-
                        extUi
                allItems['allItemsName', allItems['allItemsName',] == selTab] <-
                        extName
                statTabUiList <<- allItems['allItemsName', ]
                updateSelectInput(session, 'extStatusList', 
                                  choices = statTabUiList)
                checkAllItems(allItems, 'Status')
                headerStr <- paste0("tabsetPanel(type='tabs', ",
                                                "selected='config', ")
                footerStr <- ", uiStatusItemConfig())"
                outputStr <- extRenderStr(allItems['allItemsName',], 
                                          headerStr, footerStr, 'desktop', 
                                          'Status')
                output$desktopUiStatusItemsRender <- renderUI({
                        eval(parse(text = outputStr), envir=.GlobalEnv)
                })
                
                app <- currApp()
                url <- itemsUrl(app[['url']], 
                                paste0(app[['app_key']],
                                       '.extension'))
                data <- list(group = 'status',
                             name  = extName,
                             ui    = extUi,
                             logic = extLogic)
                extItems <- readExtItems()
                id <- extItems[extItems$name == selTab, 'id']
                updateItem(app, url, data, id)
        } else {
                errMsg <- paste('Fehler:', errMsg)
                output$extStatusItemError <- renderUI({ errMsg })
        }
})

# handle updating source extension
observeEvent(input$updateExtSourceItem, {
        selTab   <- input$extSourceList
        extName  <- input$extSourceItemName
        extUi    <- input$extSourceItemUi
        extLogic <- input$extSourceItemLogic
        errMsg <- ''
        if(is.null(selTab)){
                errMsg <- 'keine Auswahl'
        }
        if(selTab %in% defaultSrcTabsName){
                errMsg <- 'Standard-Datenquelle kann nicht verändert werden'
        }
        if(errMsg == ''){
                allItems <- collectItems(defaultSrcTabsName,
                                         defaultSrcTabsUI,
                                         defaultSrcTabsLogic,
                                         'source')
                allItems['allItemsLogic',allItems['allItemsName',] == selTab] <-
                        extLogic
                allItems['allItemsUI', allItems['allItemsName',] == selTab] <-
                        extUi
                allItems['allItemsName', allItems['allItemsName',] == selTab] <-
                        extName
                srcTabUiList <<- allItems['allItemsName', ]
                updateSelectInput(session, 'extSourceList', 
                                  choices = srcTabUiList)
                checkAllItems(allItems, 'Source')
                headerStr <- paste0("tabsetPanel(type='tabs', ",
                                    "selected='config', ")
                footerStr <- ", uiSourceItemConfig())"
                outputStr <- extRenderStr(allItems['allItemsName',], 
                                          headerStr, footerStr, 'desktop', 
                                          'Source')
                output$desktopUiSourceItemsRender <- renderUI({
                        eval(parse(text = outputStr), envir=.GlobalEnv)
                })
                
                app <- currApp()
                url <- itemsUrl(app[['url']], 
                                paste0(app[['app_key']],
                                       '.extension'))
                data <- list(group = 'source',
                             name  = extName,
                             ui    = extUi,
                             logic = extLogic)
                extItems <- readExtItems()
                id <- extItems[extItems$name == selTab, 'id']
                updateItem(app, url, data, id)
        } else {
                errMsg <- paste('Fehler:', errMsg)
                output$extStatusItemError <- renderUI({ errMsg })
        }
})

# handle removing status extension
observeEvent(input$delExtStatusList, {
        selTab <- input$extStatusList
        errMsg <- ''
        if(is.null(selTab)){
                errMsg <- 'keine Auswahl'
        }
        if(selTab %in% defaultStatTabsName){
                errMsg <- 'Standardauswertung kann nicht entfernt werden'
        }
        if(errMsg == ''){
                output$extStatusItemDeleteError <- renderUI({ '' })
                allItems <- collectItems(defaultStatTabsName,
                                         defaultStatTabsUI,
                                         defaultStatTabsLogic,
                                         'status')
                allItems <- allItems[,allItems['allItemsName',] != selTab]
                statTabUiList <<- allItems['allItemsName', ]
                updateSelectInput(session, 'extStatusList', 
                                  choices = statTabUiList)
                checkAllItems(allItems, 'Status')
                headerStr <- paste0("tabsetPanel(type='tabs', ",
                                                "selected='config', ")
                footerStr <- ", uiStatusItemConfig())"
                outputStr <- extRenderStr(allItems['allItemsName',], 
                                          headerStr, footerStr, 'desktop', 
                                          'Status')
                output$desktopUiStatusItemsRender <- renderUI({
                        eval(parse(text = outputStr), envir=.GlobalEnv)
                })
                app <- currApp()
                url <- itemsUrl(app[['url']], 
                                paste0(app[['app_key']],
                                       '.extension'))
                extItems <- readExtItems()
                id <- extItems[extItems$name == selTab, 'id']
                deleteItem(app, url, id)
        } else {
                errMsg <- paste('Fehler:', errMsg)
                output$extStatusItemDeleteError <- renderUI({ errMsg })
        }        
})

# handle removing source extension
observeEvent(input$delExtSourceList, {
        selTab <- input$extSourceList
        errMsg <- ''
        if(is.null(selTab)){
                errMsg <- 'keine Auswahl'
        }
        if(selTab %in% defaultSrcTabsName){
                errMsg <- 'Standard-Datenquelle kann nicht entfernt werden'
        }
        if(errMsg == ''){
                output$extSourceItemDeleteError <- renderUI({ '' })
                allItems <- collectItems(defaultSrcTabsName,
                                         defaultSrcTabsUI,
                                         defaultSrcTabsLogic,
                                         'source')
                allItems <- allItems[,allItems['allItemsName',] != selTab]
                srcTabUiList <<- allItems['allItemsName', ]
                updateSelectInput(session, 'extSourceList', 
                                  choices = srcTabUiList)
                checkAllItems(allItems, 'Source')
                headerStr <- paste0("tabsetPanel(type='tabs', ",
                                    "selected='config', ")
                footerStr <- ", uiSourceItemConfig())"
                outputStr <- extRenderStr(allItems['allItemsName',], 
                                          headerStr, footerStr, 'desktop', 
                                          'Source')
                output$desktopUiSourceItemsRender <- renderUI({
                        eval(parse(text = outputStr), envir=.GlobalEnv)
                })
                app <- currApp()
                url <- itemsUrl(app[['url']], 
                                paste0(app[['app_key']],
                                       '.extension'))
                extItems <- readExtItems()
                id <- extItems[extItems$name == selTab, 'id']
                deleteItem(app, url, id)
        } else {
                errMsg <- paste('Fehler:', errMsg)
                output$extSourceItemDeleteError <- renderUI({ errMsg })
        }        
})

# adding status extension from Github
observeEvent(input$addExtStatusItemGithub, {
        errMsg <- ''
        dirStr <- input$extStatusItemGithub
        dirStr <- gsub('^https://github.com/', 
                       'https://raw.githubusercontent.com/',
                       dirStr)
        dirStr <- gsub('https://www.github.com/', 
                       'https://raw.githubusercontent.com/',
                       dirStr)
        dirStr <- gsub('^github.com/', 
                       'https://raw.githubusercontent.com/',
                       dirStr)
        dirStr <- gsub('^www.github.com/', 
                       'https://raw.githubusercontent.com/',
                       dirStr)
        dirStr <- gsub('/tree/', '/', dirStr)
        if(stri_sub(dirStr, -1) != '/'){
                dirStr <- paste0(dirStr, '/')
        }
        
        oyd_json <- getURL(paste0(dirStr, 'oyd.json'))
        extName <- fromJSON(oyd_json)$name
        extUi <- getURL(paste0(dirStr, 'ext_ui.R'))
        extLogic <- getURL(paste0(dirStr, 'ext_server.R'))
        
        #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        if(is.null(extName) | (extName == '')){
                errMsg <- 'fehlender Name'
        }
        allItems <- collectItems(defaultStatTabsName,
                                 defaultStatTabsUI,
                                 defaultStatTabsLogic,
                                 'status')
        if(extName %in% allItems['allItemsName',]){
                errMsg <- 'Name bereits vergeben'
        }
        if(errMsg == '') {
                allItems <- cbind(allItems, 
                                  c(extName, extUi, extLogic))
                app <- currApp()
                url <- itemsUrl(app[['url']], 
                                paste0(app[['app_key']],
                                       '.extension'))
                data <- list(group='status',
                             name=extName,
                             ui=extUi,
                             logic=extLogic)
                writeItem(app, url, data)
        } else {
                errMsg <- paste('Fehler:', errMsg)
        }
        
        
        #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        #errMsg <- addExtItem(extName, extUi, extLogic)
        if(errMsg == ''){
                #toggleModal(session = session, 'loadExtStatusListDialog', toggle = 'toggle')
                output$extStatusItemGithubError <- renderUI({ '' })
                output$extStatusItemGithubSuccess <- renderUI({ 'Erweiterung erfolgreich geladen' })
                allItems <- collectItems(defaultStatTabsName,
                                         defaultStatTabsUI,
                                         defaultStatTabsLogic,
                                         'status')
                statTabUiList <<- allItems['allItemsName', ]
                updateSelectInput(session, 'extStatusList',
                                  choices = statTabUiList)
                checkAllItems(allItems, 'Status')
                headerStr <- paste0("tabsetPanel(type='tabs', ",
                                    "selected='config', ")
                footerStr <- ", uiStatusItemConfig())"
                outputStr <- extRenderStr(allItems['allItemsName',],
                                          headerStr, footerStr, 'desktop', 
                                          'Status')
                output$desktopUiStatusItemsRender <- renderUI({
                        eval(parse(text = outputStr), envir=.GlobalEnv)
                })
                output$loadExtStatusListDialogCloseScript <- renderUI({
                        tagList(
                                tags$script('$("body div").last().attr("class", "");')
                        )
                })
        } else {
                output$extStatusItemGithubSuccess <- renderUI({ '' })
                output$extStatusItemGithubError <- renderUI({ errMsg })
        }
})

# adding source extension from Github
observeEvent(input$addExtSourceItemGithub, {
        errMsg <- ''
        dirStr <- input$extSourceItemGithub
        dirStr <- gsub('^https://github.com/', 
                       'https://raw.githubusercontent.com/',
                       dirStr)
        dirStr <- gsub('https://www.github.com/', 
                       'https://raw.githubusercontent.com/',
                       dirStr)
        dirStr <- gsub('^github.com/', 
                       'https://raw.githubusercontent.com/',
                       dirStr)
        dirStr <- gsub('^www.github.com/', 
                       'https://raw.githubusercontent.com/',
                       dirStr)
        dirStr <- gsub('/tree/', '/', dirStr)
        if(stri_sub(dirStr, -1) != '/'){
                dirStr <- paste0(dirStr, '/')
        }
        
        oyd_json <- getURL(paste0(dirStr, 'oyd.json'))
        extName <- fromJSON(oyd_json)$name
        extUi <- getURL(paste0(dirStr, 'ext_ui.R'))
        extLogic <- getURL(paste0(dirStr, 'ext_server.R'))
        
        #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        if(is.null(extName) | (extName == '')){
                errMsg <- 'fehlender Name'
        }
        allItems <- collectItems(defaultSrcTabsName,
                                 defaultSrcTabsUI,
                                 defaultSrcTabsLogic,
                                 'source')
        if(extName %in% allItems['allItemsName',]){
                errMsg <- 'Name bereits vergeben'
        }
        if(errMsg == '') {
                allItems <- cbind(allItems, 
                                  c(extName, extUi, extLogic))
                app <- currApp()
                url <- itemsUrl(app[['url']], 
                                paste0(app[['app_key']],
                                       '.extension'))
                data <- list(group='source',
                             name=extName,
                             ui=extUi,
                             logic=extLogic)
                writeItem(app, url, data)
        } else {
                errMsg <- paste('Fehler:', errMsg)
        }
        
        
        #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        if(errMsg == ''){
                output$extSourceItemGithubError <- renderUI({ '' })
                output$extSourceItemGithubSuccess <- renderUI({ 'Erweiterung erfolgreich geladen' })
                allItems <- collectItems(defaultSrcTabsName,
                                         defaultSrcTabsUI,
                                         defaultSrcTabsLogic,
                                         'source')
                srcTabUiList <<- allItems['allItemsName', ]
                updateSelectInput(session, 'extSourceList',
                                  choices = srcTabUiList)
                checkAllItems(allItems, 'Source')
                headerStr <- paste0("tabsetPanel(type='tabs', ",
                                    "selected='config', ")
                footerStr <- ", uiSourceItemConfig())"
                outputStr <- extRenderStr(allItems['allItemsName',],
                                          headerStr, footerStr, 'desktop', 
                                          'Source')
                output$desktopUiSourceItemsRender <- renderUI({
                        eval(parse(text = outputStr), envir=.GlobalEnv)
                })
                output$loadExtSourceListDialogCloseScript <- renderUI({
                        tagList(
                                tags$script('$("body div").last().attr("class", "");')
                        )
                })
        } else {
                output$extSourceItemGithubSuccess <- renderUI({ '' })
                output$extSourceItemGithubError <- renderUI({ errMsg })
        }
})
