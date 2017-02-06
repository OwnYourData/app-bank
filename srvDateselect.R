# functions to filter data in status tab by date
# last update: 2016-09-07

observe({
        if(!is.null(input$dateSelect)){
                switch(input$dateSelect,
                       '1'={ updateDateRangeInput(session, 'dateRange',
                                                  start = as.Date(Sys.Date()-7),
                                                  end = as.Date(Sys.Date())) },
                       '2'={ updateDateRangeInput(session, 'dateRange',
                                                  start = as.Date(Sys.Date() - months(1)),
                                                  end = as.Date(Sys.Date())) },
                       '3'={ updateDateRangeInput(session, 'dateRange',
                                                  start = as.Date(Sys.Date() - months(2)),
                                                  end = as.Date(Sys.Date())) },
                       '4'={ updateDateRangeInput(session, 'dateRange',
                                                  start = as.Date(Sys.Date() - months(6)),
                                                  end = as.Date(Sys.Date())) },
                       '5'={ updateDateRangeInput(session, 'dateRange',
                                                  start = as.Date(paste(year(Sys.Date()),'1','1',sep='-')),
                                                  end = as.Date(paste(year(Sys.Date()),'12','31',sep='-'))) },
                       '6'={ updateDateRangeInput(session, 'dateRange',
                                                  start = as.Date(Sys.Date() - months(12)),
                                                  end = as.Date(Sys.Date())) },
                       '10'={ data <- currData()
                       myStart <- min(as.Date(data$date), na.rm=TRUE)
                       myEnd <- max(as.Date(data$date), na.rm=TRUE)
                       updateDateRangeInput(session, 'dateRange',
                                            start = myStart,
                                            end = myEnd) },
                       {})
        }
})

observeEvent(input$dateRange, {
        myStart <- input$dateRange[1]
        myEnd <- input$dateRange[2]
        if((myStart == as.Date(Sys.Date()-7)) & 
           (myEnd == as.Date(Sys.Date()))) {
                updateSelectInput(session, 'dateSelect', selected=1)
        } else {
                if((myStart == as.Date(Sys.Date() - months(1))) & 
                   (myEnd == as.Date(Sys.Date()))) {
                        updateSelectInput(session, 'dateSelect', selected=2)
                } else {
                        if((myStart == as.Date(Sys.Date() - months(2))) & 
                           (myEnd == as.Date(Sys.Date()))) {
                                updateSelectInput(session, 'dateSelect', selected=3)
                        } else {
                                if((myStart == as.Date(Sys.Date() - months(6))) & 
                                   (myEnd == as.Date(Sys.Date()))) {
                                        updateSelectInput(session, 'dateSelect', selected=4)
                                } else {
                                        if((myStart == as.Date(paste(year(Sys.Date()),'1','1',sep='-'))) & 
                                           (myEnd == as.Date(paste(year(Sys.Date()),'12','31',sep='-')))) {
                                                updateSelectInput(session, 'dateSelect', selected=5)
                                        } else {
                                                if((myStart == as.Date(Sys.Date() - months(12))) & 
                                                   (myEnd == as.Date(Sys.Date()))) {
                                                        updateSelectInput(session, 'dateSelect', selected=6)
                                                } else {
                                                        updateSelectInput(session, 'dateSelect', selected=7)
                                                }
                                        }
                                }
                        }
                }
        }
})

currDataSelect <- reactive({
        data <- currData()
        if(nrow(data) == 0) {
                createAlert(session, 'dataStatus', alertId = 'myDataStatus',
                            style = 'warning', append = FALSE,
                            title = 'Keine Daten im gewählten Zeitfenster',
                            content = 'Für das ausgewählte Zeitfenster sind keine Daten vorhanden.')
                data <- data.frame()
        } else {
                data$dat <- as.POSIXct(data$date, 
                                       format='%Y-%m-%d')
                dataMin <- min(data$dat, na.rm=TRUE)
                dataMax <- max(data$dat, na.rm=TRUE)
                curMin <- as.Date(input$dateRange[1], '%d.%m.%Y')
                curMax <- as.Date(input$dateRange[2], '%d.%m.%Y')
                daterange <- seq(curMin, curMax, 'days')
                data <- data[as.Date(data$dat) %in% daterange, ]
                if(nrow(data)>0){
                        closeAlert(session, 'myDataStatus')
                }
        }
        data
})
