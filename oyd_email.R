# functions for sending email reminders
# last update:2016-07-28

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
        c('valid'=validEmailConfig,
          'server'=server,
          'port'=port,
          'user'=user,
          'pwd'=pwd)
})

# fix me !!!
getPiaEmailConfig <- function(app){
        vector()
        # url <- itemsUrl(app[['url']], 
        #                 schedulerEmailConfigKey())
        # retVal <- readItems(repo, url)
        # if(length(retVal) == 0 | 
        #    nrow(retVal) == 0) {
        #         vector()
        # } else {
        #         retVal
        # }
}

# fix me !!!
getPiaSchedulerEmail <- function(repo) {
        vector()
        # url <- itemsUrl(repo[['url']], 
        #                 schedulerKey())
        # retVal <- readItems(repo, url)
        # if(nrow(retVal) == 0) {
        #         vector()
        # } else {
        #         retVal <- retVal[retVal$repo == repo[['app_key']] & 
        #                                  retVal$task == 'email', ]
        #         if(nrow(retVal) > 0) {
        #                 c(id=retVal$id,
        #                   email=retVal$parameters$address)
        #         } else {
        #                 vector()
        #         }
        # }
}

emailConfigStatus <- function(app){
        localMailConfig <- getLocalEmailConfig()
        piaMailConfig <- getPiaEmailConfig(app)
        if (localMailConfig[['valid']]) {
                # is there already a config in PIA?
                if (length(piaMailConfig) > 0) {
                        # is it different?
                        if((localMailConfig[['server']] == piaMailConfig[['server']]) &
                           (localMailConfig[['port']] == piaMailConfig[['port']]) &
                           (localMailConfig[['user']] == piaMailConfig[['user']]) &
                           (localMailConfig[['pwd']] == piaMailConfig[['pwd']])) {
                                'config in sync'
                        } else {
                                updateEmailConfig(app, 
                                                  localMailConfig, 
                                                  piaMailConfig[['id']])
                                'config updated'
                        }
                } else {
                        writeEmailConfig(app, localMailConfig)
                        'config saved'
                }
        } else {
                # is there already a config in PIA?
                if (length(piaMailConfig) > 0) {
                        setEmailConfig(session, piaMailConfig)
                        'config loaded' # Mailkonfiguration von PIA gelesen
                } else {
                        'not configured' # keine Mailkonfiguration vorhanden
                }
        }
}

emailReminderStatus <- reactive({
        app <- currApp()
        if(length(app) > 0){
                piaMailConfig <- getPiaEmailConfig(app)
                piaSchedulerEmail <- getPiaSchedulerEmail(app)
                piaEmail <- ''
                piaEmailId <- NA
                if (length(piaMailConfig) == 0) {
                        'no mail config'
                } else {
                        if (length(piaSchedulerEmail) > 0) {
                                piaEmail <- piaSchedulerEmail[['email']]
                                piaEmailId <-  piaSchedulerEmail[['id']]
                        }
                        localEmail <- as.character(input$email)
                        if(validEmail(localEmail)) {
                                if (localEmail == piaEmail) {
                                        'email in sync'
                                } else {
                                        goal_fields <- list(
                                                date='Date.now',
                                                value='line_1'
                                        )
                                        goal_structure <- list(
                                                app=repo_app,
                                                fields=goal_fields
                                        )
                                        response_structure <- list(
                                                goal_structure
                                        )
                                        content <- 'text'
                                        timePattern <- '0 7 * * *'
                                        if (piaEmail == '') {
                                                writeSchedulerEmail(
                                                        app,
                                                        localEmail,
                                                        content,
                                                        timePattern,
                                                        response_structure)
                                                'email saved'
                                        } else {
                                                updateSchedulerEmail(
                                                        app,
                                                        localEmail,
                                                        content,
                                                        timePattern,
                                                        response_structure,
                                                        piaEmailId)
                                                'email updated'
                                        }
                                }
                        } else {
                                if (nchar(localEmail) == 0) {
                                        if (piaEmail == '') {
                                                'missing email'
                                        } else {
                                                setSchedulerEmail(session, piaEmail)
                                                'email loaded'
                                        }
                                } else {
                                        'invalid email'
                                }
                        }
                }
        } else {
                'no Pia'
        }
        
})

output$mail_config <- renderText({
        app <- currApp()
        if(length(app) > 0){
                retVal <- emailConfigStatus(app)
                switch(retVal,
                       'config in sync' = 'Benachrichtigungen via Email sind eingerichtet',
                       'not configured' = 'Benachrichtigungen via Email sind noch nicht konfiguiert',
                       'config saved'   = 'Emailkonfiguration in PIA gespeichert',
                       'config updated' = 'Emailkonfiguration in PIA aktualisiert',
                       'config loaded'  = 'Emailkonfiguration aus PIA geladen')
        } else {
                'keine Verbindung zu PIA'
        }
})

output$email_status <- renderText({
        retVal <- emailReminderStatus()
        paste('<strong>Status:</strong>',
              switch(retVal,
                     'no Pia'         = 'keine Verbindung zu PIA',
                     'no mail config' = 'Emailkonfiguration noch nicht vorhanden',
                     'missing email'  = 'fehlende Emailadresse',
                     'invalid email'  = 'ungültige Emailadresse',
                     'email loaded'   = 'Emailadresse aus PIA geladen',
                     'email in sync'  = 'periodische Email-Benachrichtigungen werden versandt',
                     'email saved'    = 'Emailadresse in PIA gespeichert',
                     'email updated'  = 'Emailadresse in PIA aktualisiert'))
})
