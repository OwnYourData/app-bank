# server-side UI logic
# last update: 2016-10-07

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
