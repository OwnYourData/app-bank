# last update: 2016-05-14
 
# Accessing PIA ===========================================
getPiaConnection <- function(appName){
        url <- ''
        app_key <- ''
        app_secret <- ''
        
        rDataFile <- paste0('~/', appName, 'Credentials.RData')
        if(file.exists(rDataFile))
                load(rDataFile)
        
        credentialsFile <-'credentials.json'
        if(file.exists(credentialsFile)) {
                credentialStr <- readChar(credentialsFile, 
                                          file.info(credentialsFile)$size)
                credentials <- fromJSON(credentialStr)
        }

        # drv <- dbDriver("PostgreSQL")
        # con <- dbConnect(drv, 
        #                  dbname = Sys.getenv('HEROKU_DBNAME'), 
        #                  host = Sys.getenv('HEROKU_HOST'), 
        #                  port=5432, 
        #                  user = Sys.getenv('HEROKU_USER'), 
        #                  password = Sys.getenv('HEROKU_PASSWORD'))
        # pia_con <- dbGetQuery(con, "SELECT * FROM pia")

        if((url == '') & (Sys.getenv('HEROKU_PIA_URL') != '')) {
                url <- Sys.getenv('HEROKU_PIA_URL')
        }
        if((app_key == '') & (Sys.getenv('HEROKU_APP_KEY') != '')) {
                app_key <- Sys.getenv('HEROKU_APP_KEY')
        }
        if((app_secret == '') & (Sys.getenv('HEROKU_APP_SECRET') != '')) {
                app_secret <- Sys.getenv('HEROKU_APP_SECRET')
        }
        
        if(url == '')
                url <- 'http://127.0.0.1:8080'
        if(app_key == '') {
                if(exists('credentials')) {
                        if(!is.null(credentials$client_id))
                                app_key <- credentials$client_id
                }
        }
        if(app_secret == '') {
                if(exists('credentials')) {
                        if(!is.null(credentials$client_secret))
                                app_secret <- credentials$client_secret
                }
        }
        c(url        = url,
          app_key    = app_key,
          app_secret = app_secret)
}

# Default Text Blocks =====================================
renderUpgrade <- function(session){
        if(grepl('.herokuapp.com', session$clientData$url_hostname))
                paste0('<h4>Upgrade: <a href="https://dashboard.heroku.com/apps/',
                       strsplit(session$clientData$url_hostname, '.', fixed=TRUE)[[1]][1],
                       '/deploy/github">hier klicken</a></h4>',
                       '<p class="help-block">Anmerkung: zum Upgrade musst du auf der verlinkten Seite ganz nach unten scrollen und dort auf die Schaltfläche "Deploy Branch" klicken; der Installationsvorgang dauert dann etwa 10 Minuten</p>')
        
}

internetAlert <- function(session, appUrl){
        createAlert(session, 'topAlert', style='danger', title='Sie befinden sich auf einer unsicheren Webseite!',
                    content=paste0("Die auf dieser Webseite eingegebenen und hochgeladenden Daten können möglicherweise durch Unberechtigte mitgelesen werden - <a href='https://www.ownyourdata.eu/laendervergleich-datenschutz/'>weitere Infos</a>.<br><strong>Lösung:</strong> <a href='", appUrl, "'>Installiere</a> die App an einem sicheren Ort!"), append=FALSE)
        
}

# Accessing a Repo ========================================
defaultHeaders <- function(token) {
        c('Accept'        = '*/*',
          'Content-Type'  = 'application/json',
          'Authorization' = paste('Bearer', token))
}

itemsUrl <- function(url, app_key) {
        paste0(url, '/api/repos/', app_key, '/items')
}

getToken <- function(url, app_key, app_secret) {
        url_auth <- paste0(url, '/oauth/token')
        response <- tryCatch(
                postForm(url_auth,
                         client_id=app_key,
                         client_secret=app_secret,
                         grant_type='client_credentials'),
                error = function(e) { return(NA) })
        if (is.na(response)) {
                return(NA)
        } else {
                return(fromJSON(response[1])$access_token)
        }
}

getRepo <- function(url, key, secret) {
        c('url'        = url,
          'app_key'    = key,
          'app_secret' = secret,
          'token'      = getToken(url, 
                                  key, 
                                  secret))
}

writeRecord <- function(repo, url, record) {
        headers <- defaultHeaders(repo[['token']])
        data <- gsub("^\\[|\\]$", '', 
                     toJSON(record, auto_unbox = TRUE))
        response <- tryCatch(
                postForm(url,
                         .opts=list(httpheader = headers,
                                    postfields = data)),
                error = function(e) { return(NA) })
        response
}

updateRecord <- function(repo, url, record, id) {
        headers <- defaultHeaders(repo[['token']])
        record$id <- as.numeric(id)
        data <- gsub("^\\[|\\]$", '', 
                     toJSON(record, auto_unbox = TRUE))
        response <- tryCatch(
                postForm(url,
                         .opts=list(httpheader = headers,
                                    postfields = data)),
                error = function(e) { return(NA) })
        response
}

readItems <- function(repo, url) {
        if (length(repo) == 0) {
                data.frame()
        } else {
                headers <- defaultHeaders(repo[['token']])
                url_data <- paste0(url, '?size=2000')
                response <- tryCatch(
                        getURL(url_data,
                               .opts=list(httpheader = headers)),
                        error = function(e) { return(NA) })
                if (is.na(response)) {
                        data.frame()
                } else {
                        if (nchar(response) > 0) {
                                retVal <- fromJSON(response)
                                if(length(retVal) == 0) {
                                        data.frame()
                                } else {
                                        if ('error' %in% names(retVal)) {
                                                data.frame()
                                        } else {
                                                if (!is.null(retVal$message)) {
                                                        if (retVal$message == 'error.accessDenied') {
                                                                data.frame()
                                                        } else {
                                                                retVal
                                                        }
                                                } else {
                                                        retVal
                                                }
                                        }
                                }
                        } else {
                                data.frame()
                        }
                }
        }
}

# Email Reminder Configuration ============================
schedulerKey <- function(){
        'eu.ownyourdata.scheduler'        
}

schedulerEmailConfigKey <- function(){
        'eu.ownyourdata.scheduler.email_config'
}

getPiaSchedulerEmail <- function(repo) {
        url <- itemsUrl(repo[['url']], 
                        schedulerKey())
        retVal <- readItems(repo, url)
        if(nrow(retVal) == 0) {
                vector()
        } else {
                retVal <- retVal[retVal$repo == repo[['app_key']] & 
                                 retVal$task == 'email', ]
                if(nrow(retVal) > 0) {
                        c(id=retVal$id,
                          email=retVal$parameters$address)
                } else {
                        vector()
                }
        }
}

setSchedulerEmail <- function(session, email){
        updateTextInput(session, 'email',
                        value=email)
}

writeSchedulerEmail <- function(repo, email, content, time, response_structure){
        if(missing(response_structure)) {
                parameters <- list(address=email,
                                   content=content,
                                   encrypt='false')
                config <- list(repo=repo[['app_key']],
                               time=time,
                               task='email',
                               parameters=parameters)
        } else {
                parameters <- list(address=email,
                                   content=content,
                                   response_structure=response_structure,
                                   repo_url=repo[['url']],
                                   repo_key=repo[['app_key']],
                                   repo_secret=repo[['app_secret']],
                                   encrypt='false')
                config <- list(repo=repo[['app_key']],
                               time=time,
                               task='email',
                               email_response = TRUE,
                               parameters=parameters)
        }
        writeRecord(repo, 
                    itemsUrl(repo[['url']], schedulerKey()), 
                    config)
}

updateSchedulerEmail <- function(repo, email, content, time, response_structure, id){
        if(missing(response_structure)) {
                parameters <- list(address=email,
                                   content=content,
                                   encrypt='false')
                config <- list(repo=repo[['app_key']],
                               time=time,
                               task='email',
                               parameters=parameters)
        } else {
                parameters <- list(address=email,
                                   content=content,
                                   response_structure=response_structure,
                                   repo_url=repo[['url']],
                                   repo_key=repo[['app_key']],
                                   repo_secret=repo[['app_secret']],
                                   encrypt='false')
                config <- list(repo=repo[['app_key']],
                               time=time,
                               task='email',
                               email_response = TRUE,
                               parameters=parameters)
        }
        updateRecord(repo, 
                     itemsUrl(repo[['url']], schedulerKey()), 
                     config,
                     id)
}

# Email Configuration in Scheduler ========================
getPiaEmailConfig <- function(repo){
        url <- itemsUrl(repo[['url']], 
                        schedulerEmailConfigKey())
        retVal <- readItems(repo, url)
        if(length(retVal) == 0 | 
           nrow(retVal) == 0) {
                vector()
        } else {
                retVal
        }
}

setEmailConfig <- function(session, emailConfig){
        updateTextInput(session, 'mailer_address', 
                        value=emailConfig[['server']])
        updateNumericInput(session, 'mailer_port', 
                           value=emailConfig[['port']])
        updateTextInput(session, 'mailer_user', 
                        value=emailConfig[['user']])
        updateTextInput(session, 'mailer_password', 
                        value=emailConfig[['pwd']])
}

writeEmailConfig <- function(repo, emailConfig){
        url <- itemsUrl(repo[['url']], 
                        schedulerEmailConfigKey())
        data <- as.list(emailConfig)[-which(names(emailConfig)=='valid')]
        writeRecord(repo, url, data)
}

updateEmailConfig <- function(repo, emailConfig, id){
        url <- itemsUrl(repo[['url']], 
                        schedulerEmailConfigKey())
        data <- as.list(emailConfig)[-which(names(emailConfig)=='valid')]
        updateRecord(repo, url, data, id)
}

# other helper functions ==================================
createDigest <- function(data, fields){
        if (nrow(data)>0) {
                data <- unite_(data, 'merged', 
                               fields, 
                               remove=FALSE)
                data$digest <- sapply(data$merged, digest)
                data[, c(fields,  'digest')]
        } else {
                data.frame()
        }
}

validEmail <- function(email){
        emailPtrn <- "^[\\w\\.-]+@([\\w\\-]+\\.)+[A-Za-z]{2,4}$"
        if (any(grep(emailPtrn, email, perl = TRUE))) {
                TRUE
        } else {
                FALSE
        }
}
