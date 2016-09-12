# functions required in the Store tab
# last update:2016-07-28

source('srvSheet.R', local=TRUE)

# handle HTML5 Local Storage used for saving PIA connection data
observe({
        if(!is.null(input$localStore)){
                if (input$localStore <= 0){
                        # On initialization, set the value to the current val
                        updateTextInput(session, "pia_url", value=isolate(input$store)$pia_url)
                        updateTextInput(session, "app_key", value=isolate(input$store)$app_key)
                        updateTextInput(session, "app_secret", value=isolate(input$store)$app_secret)
                        return()
                }
                updateStore(session, "pia_url", isolate(input$pia_url))
                updateStore(session, "app_key", isolate(input$app_key))
                updateStore(session, "app_secret", isolate(input$app_secret))
        }
})

# display current token
output$current_token <- renderText({
        app <- currApp()
        if (length(app) == 0) {
                '<strong>Token:</strong> nicht verfügbar'
        } else {
                paste0('<strong>Token:</strong><br><small>', 
                       app[['token']], '</small>')
        }
})

# display number of records in (main) repository
output$curr_records <- renderText({
        data <- currData()
        paste('<strong>Datensätze:</strong>',
              nrow(data))
})

