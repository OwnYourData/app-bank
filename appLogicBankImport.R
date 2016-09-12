convAccountStr <- function(data){
        as.numeric(sub(',', '.', gsub("\\.", '', data)))        
}

csvImportDynamic <- function(myFile, config) {
        tryCatch({
                data <- read.csv2(myFile$datapath, 
                                  header       = config$header, 
                                  check.names  = FALSE,
                                  sep          = config$sep, 
                                  quote        = config$quot, 
                                  dec          = '.', 
                                  encoding     = config$encoding,
                                  fileEncoding = config$encoding)
                data$date <- as.Date(as.character(as.POSIXct(as.character(
                        data[, config$dateColumn]), 
                        format = config$dateFormat)))
                if(config$valueColumn < 1){
                        data$soll <- convAccountStr(data[, config$valueSoll])
                        data$haben <- convAccountStr(data[, config$valueHaben])
                        data$value <- data$haben - data$soll
                } else {
                        data$value <- convAccountStr(data[, config$valueColumn])
                }
                data$description <- as.character(data[, config$descColumn])
                Encoding(data$description) <- config$descEnc
                data <- data[complete.cases(data[, c('date', 'value')]), ]
                data$id <- 1:nrow(data)
                data[, c('date', 'description', 'id', 'value')]
        })
}
