# basic functions for accessing PIA
# last update:2016-08-21

# Low-level functions to access PIA =======================
# used header for GET and POST requests
defaultHeaders <- function(token) {
        c('Accept'        = '*/*',
          'Content-Type'  = 'application/json',
          'Authorization' = paste('Bearer', token))
}

# URL to access a repo
itemsUrl <- function(url, repo_name) {
        paste0(url, '/api/repos/', repo_name, '/items')
}

# request token for a plugin (app)
getToken <- function(pia_url, app_key, app_secret) {
        auth_url <- paste0(pia_url, '/oauth/token')
        # reduce response timeout to 10s to avoid hanging app
        # https://curl.haxx.se/libcurl/c/CURLOPT_CONNECTTIMEOUT.html
        optTimeout <- curlOptions(connecttimeout = 10)
        response <- tryCatch(
                postForm(auth_url,
                         client_id     = app_key,
                         client_secret = app_secret,
                         grant_type    = 'client_credentials',
                         .opts         = optTimeout),
                error = function(e) { return(NA) })
        if (is.na(response)) {
                return(NA)
        } else {
                return(fromJSON(response[1])$access_token)
        }
}

# vector with all plugin (app) infos to access PIA
setupApp <- function(pia_url, app_key, app_secret) {
        app_token <- getToken(pia_url, 
                              app_key, 
                              app_secret)
        if(is.na(app_token)){
                vector()
        } else {
                c('url'        = pia_url,
                  'app_key'    = app_key,
                  'app_secret' = app_secret,
                  'token'      = app_token)
        }
}

# Read and CRUD Operations for a Plugin (App) =============
# convert response string into data.frame
r2d <- function(response){
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
                                                if (retVal$message == 
                                                    'error.accessDenied') {
                                                        data.frame()
                                                } else {
                                                        # convert list to data.frame
                                                        do.call(rbind, 
                                                                lapply(retVal, 
                                                                       data.frame))
                                                }
                                        } else {
                                                do.call(rbind, 
                                                        lapply(retVal, 
                                                               data.frame))
                                        }
                                }
                        }
                } else {
                        data.frame()
                }
        }
}

# read data from PIA
readItems <- function(app, repo_url) {
        if (length(app) == 0) {
                data.frame()
                return()
        }
        headers <- defaultHeaders(app[['token']])
        url_data <- paste0(repo_url, '?size=2000')
        h <- basicHeaderGatherer()
        doc <- tryCatch(
                getURI(url_data, 
                      .opts=list(httpheader = headers), 
                      headerfunction = h$update),
                error = function(e) { return(NA) })
        response <- NA
        respData <- data.frame()
        if(!is.na(doc)){
                recs <- tryCatch(
                        as.integer(h$value()[['X-Total-Count']]),
                        error = function(e) { return(0)})
                if(recs > 2000) {
                        for(page in 0:floor(recs/2000)){
                                url_data <- paste0(repo_url,
                                                   '?page=', page,
                                                   '&size=2000')
                                response <- tryCatch(
                                        getURL(url_data,
                                               .opts=list(httpheader=headers)),
                                        error = function(e) { return(NA) })
                                subData <- r2d(response)
                                if(nrow(respData)>0){
                                        respData <- rbind(respData, subData)
                                } else {
                                        respData <- subData
                                }
                        }
                } else {
                        response <- tryCatch(
                                getURL(url_data,
                                       .opts=list(httpheader = headers)),
                                error = function(e) { return(NA) })
                        respData <- r2d(response)
                }
        }
        respData
}

# write data into PIA
writeItem <- function(app, repo_url, item) {
        headers <- defaultHeaders(app[['token']])
        data <- rjson::toJSON(item)
        response <- tryCatch(
                postForm(repo_url,
                         .opts=list(httpheader = headers,
                                    postfields = data)),
                error = function(e) { 
                        return(NA) })
        response
}

# update data in PIA
updateItem <- function(app, repo_url, item, id) {
        headers <- defaultHeaders(app[['token']])
        item <- c(item, c(id=as.numeric(id)))
        data <- rjson::toJSON(item)
        response <- tryCatch(
                postForm(repo_url,
                         .opts=list(httpheader = headers,
                                    postfields = data)),
                error = function(e) { return(NA) })
        response
}

# delete data in PIA
deleteItem <- function(app, repo_url, id){
        headers <- defaultHeaders(app[['token']])
        item_url <- paste0(repo_url, '/', id)
        response <- tryCatch(
                DELETE(item_url, 
                       add_headers(headers)),
                error = function(e) { return(NA) })
        response
}

# other helper functions ==================================
# remove leading and trailing whitespace
trim <- function (x) gsub("^\\s+|\\s+$", "", x)

# create md5 digest from specified fields in data frame
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

# check if a string is a valid email
validEmail <- function(email){
        emailPtrn <- "^[\\w\\.-]+@([\\w\\-]+\\.)+[A-Za-z]{2,4}$"
        if (any(grep(emailPtrn, email, perl = TRUE))) {
                TRUE
        } else {
                FALSE
        }
}

# merge 2 data frames by date
combineData <- function(dat1, dat2){
        data <- data.frame()
        if(nrow(dat1) == 0) {
                data <- dat2
        } else {
                if(nrow(dat2) == 0){
                        data <- dat1
                } else {
                        data <- merge(dat1[, !names(dat1) %in% c('id')], 
                                      dat2[, !names(dat2) %in% c('id')],
                                      by='date', all=TRUE)
                }
        }
        data
}
