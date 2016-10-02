# server-side UI logic
# last update:2016-08-14

# output$upgradeLink <- renderText({
#         renderUpgrade(session)
# })
# 
# renderUpgrade <- function(session){
#         if(grepl('.herokuapp.com', session$clientData$url_hostname))
#                 paste0('<h4>Upgrade: <a href="https://dashboard.heroku.com/apps/',
#                        strsplit(session$clientData$url_hostname, '.', fixed=TRUE)[[1]][1],
#                        '/deploy/github">hier klicken</a></h4>',
#                        '<p class="help-block">Anmerkung: zum Upgrade musst du auf der verlinkten Seite ganz nach unten scrollen und dort auf die Schaltfläche "Deploy Branch" klicken; der Installationsvorgang dauert dann etwa 10 Minuten</p>')
# 
# }

output$versionHistory <- renderText({
        do.call(paste, as.list(apply(verHistory,1,function(x){ 
                paste0('<p><strong>Version ', x[1], '</strong></p>',
                       '<p>', x[2], '</p>') })))
})

output$hdrImageLinkDesktop <- renderUI({
        # fix for "Raspberry Navigation"
        updateNavbarPage(session, 'mainPage', selected = appName)
        session$sendCustomMessage(type='finishInit', NA)
        renderHdrImageLink()
})

output$hdrImageLinkMobile <- renderUI({
        renderHdrImageLink()
})

headerTitle <- function() {
        app <- currApp()
        if(length(all.equal(app, logical(0)))>1){
                app <- currApp()
                url <- itemsUrl(app[['url']], 'eu.ownyourdata.info')
                infoRec <- readItems(app, url)
                if(nrow(infoRec) == 1){
                        infoRec$name
                } else {
                        "Neue PIA"                        
                }
        } else {
                "Neue PIA"
        }
}

renderHdrImageLink <- function() {
        tags$div(
                tags$a(href=input$store$pia_url,
                       tags$img(height='25px', style='margin-top:-5px',
                                src=oydLogo)),
                tags$a(href=input$store$pia_url, headerTitle())
        )
}

observeEvent(input$buttonVisual, {
        session$sendCustomMessage(type='setDisplayButton', 
                                  'buttonVisual')
        output$displayVisual <- renderText('.')
        output$displaySource <- renderText('')
        output$displayStore <- renderText('')
})

observeEvent(input$buttonSource, {
        session$sendCustomMessage(type='setDisplayButton', 
                                  'buttonSource')
        output$displayVisual <- renderText('')
        output$displaySource <- renderText('.')
        output$displayStore <- renderText('')
})

observeEvent(input$buttonStore, {
        session$sendCustomMessage(type='setDisplayButton', 
                                  'buttonStore')
        output$displayVisual <- renderText('')
        output$displaySource <- renderText('')
        output$displayStore <- renderText('.')
})

output$displayVisual <- reactive({
        output$displayVisual <- renderText('.')
        output$displaySource <- renderText('')
        output$displayStore <- renderText('')
})

output$dataSheetDirty <- reactive({
        output$dataSheetDirty <- renderText('')
})

observeEvent(input$backToApp, {
        updateNavbarPage(session, 'mainPage', selected = appName)
})
