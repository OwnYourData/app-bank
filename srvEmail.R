# functions for sending email reminders
# last update: 2017-02-06

writeSchedulerEmail <- function(app, app_name, email, subject, content, time, response_structure, id){
        port <- as.character(session$clientData$url_port)
        app_url <- paste0(session$clientData$url_protocol, '//',
                          session$clientData$url_hostname)
        if(port != '80'){
                app_url <- paste0(app_url, ':', port)
        }
        if(missing(response_structure)) {
                parameters <- list(address = email,
                                   appName = app_name,
                                   subject = subject,
                                   content = content,
                                   appUrl  = app_url,
                                   pia_url  = app[['url']],
                                   encrypt = 'false')
                config <- list(app            = app[['app_key']],
                               time           = time,
                               task           = 'email',
                               parameters     = parameters,
                               '_oydRepoName' = 'Scheduler')
        } else {
                parameters <- list(address            = email,
                                   appName            = app_name,
                                   subject            = subject,
                                   content            = content,
                                   appUrl             = app_url,
                                   response_structure = response_structure,
                                   pia_url           = app[['url']],
                                   app_key           = app[['app_key']],
                                   app_secret        = app[['app_secret']],
                                   encrypt            = 'false')
                config <- list(app            = app[['app_key']],
                               time           = time,
                               task           = 'email',
                               email_response = TRUE,
                               parameters     = parameters,
                               '_oydRepoName' = 'Scheduler')
        }
        if(missing(id)) {
                writeItem(app,
                          itemsUrl(app[['url']], schedulerKey),
                          config)
        } else {
                updateItem(app, 
                           itemsUrl(app[['url']], schedulerKey), 
                           config,
                           id)
        }
}

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
        c('valid'  = validEmailConfig,
          'server' = server,
          'port'   = port,
          'user'   = user,
          'pwd'    = pwd)
})

getPiaEmailConfig <- function(app){
        url <- itemsUrl(app[['url']],
                        schedulerEmailConfigKey)
        retVal <- readItems(app, url)
        if(length(retVal) == 0 |
           nrow(retVal) == 0) {
                vector()
        } else {
                retVal
        }
}

getPiaSchedulerEmail <- function(app) {
        url <- itemsUrl(app[['url']], schedulerKey)
        retVal <- readItems(app, url)
        if(nrow(retVal) == 0) {
                vector()
        } else {
                retVal <- retVal[retVal$app == app[['app_key']] &
                                 retVal$task == 'email', ]
                if(nrow(retVal) > 0) {
                        c(id=retVal$id,
                          email=retVal$parameters.address)
                } else {
                        vector()
                }
        }
}
