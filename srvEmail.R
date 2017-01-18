# functions for sending email reminders
# last update: 2016-12-28

writeSchedulerEmail <- function(app, email, content, time, response_structure){
        if(missing(response_structure)) {
                parameters <- list(address = email,
                                   content = content,
                                   encrypt = 'false')
                config <- list(app            = app[['app_key']],
                               time           = time,
                               task           = 'email',
                               parameters     = parameters,
                               '_oydRepoName' = 'Scheduler')
        } else {
                parameters <- list(address            = email,
                                   content            = content,
                                   response_structure = response_structure,
                                   repo_url           = app[['url']],
                                   repo_key           = app[['app_key']],
                                   repo_secret        = app[['app_secret']],
                                   encrypt            = 'false')
                config <- list(app            = app[['app_key']],
                               time           = time,
                               task           = 'email',
                               email_response = TRUE,
                               parameters     = parameters,
                               '_oydRepoName' = 'Scheduler')
        }
        writeItem(app,
                  itemsUrl(app[['url']], schedulerKey),
                  config)
}

updateSchedulerEmail <- function(app, email, content, time, id, response_structure){
        if(missing(response_structure)) {
                parameters <- list(address = email,
                                   content = content,
                                   encrypt = 'false')
                config <- list(app            = app[['app_key']],
                               time           = time,
                               task           = 'email',
                               parameters     = parameters)
        } else {
                parameters <- list(address            = email,
                                   content            = content,
                                   response_structure = response_structure,
                                   pia_url            = app[['url']],
                                   app_key            = app[['app_key']],
                                   app_secret         = app[['app_secret']],
                                   encrypt            = 'false')
                config <- list(app            = app[['app_key']],
                               time           = time,
                               task           = 'email',
                               email_response = TRUE,
                               parameters     = parameters)
        }
        updateItem(app, 
                   itemsUrl(app[['url']], schedulerKey), 
                   config,
                   id)
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
        vector()
        url <- itemsUrl(app[['url']],
                        schedulerKey)
        retVal <- readItems(app, url)
        if(nrow(retVal) == 0) {
                vector()
        } else {
                retVal <- retVal[retVal$app == app[['app_key']] &
                                         retVal$task == 'email', ]
                if(nrow(retVal) > 0) {
                        c(id=retVal$id,
                          email=retVal$parameters$address)
                } else {
                        vector()
                }
        }
}
