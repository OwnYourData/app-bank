# show account chart
# last update:2016-09-28

bankPlotly <- function(data){
        closeAlert(session, 'myDataStatus')
        pdf(NULL)
        outputPlot <- plotly_empty()
        if(nrow(data) > 0){
                mymin <- as.Date(input$dateRange[1], "%d.%m.%Y")
                mymax <- as.Date(input$dateRange[2], "%d.%m.%Y")
                if(mymax > mymin){
                        daterange <- seq(mymin, mymax, "days")
                        data$dat <- as.Date(data$date)
                        data <- data[order(data[, 'dat']),]
                        data <- data[data$dat %in% daterange, ]
                        if(nrow(data) > 0){
                                #euro <- dollar_format(prefix = "\u20ac ", suffix = "")
                                # all data until reference value
                                app <- currApp()
                                url <- itemsUrl(app[['url']], paste0(app[['app_key']],
                                                                     '.reference'))
                                refData <- readItems(app, url)
                                if(nrow(refData) == 1){
                                        subData <- data[as.Date(as.character(data$date)) < as.Date(refData$date), ]
                                        startValue <- refData$value - sum(subData$value)
                                        minDate <- min(data$dat)
                                        refRow <- data.frame(as.character(as.Date(minDate)-1),
                                                             'Startbetrag',
                                                             -1,
                                                             startValue,
                                                             'Starbetrag',
                                                             as.Date(minDate)-1)
                                        colnames(refRow) <- colnames(data)
                                        data <- rbind(refRow, data)
                                }
                                data$cumsum <- cumsum(data$value)
                                gg <- ggplot(data, 
                                             aes(x=dat, y=cumsum, 
                                                 text=paste0(
                                                         #format(dat, '%A, %d %b %Y'),
                                                         format(dat, '%d.%m.%Y'),
                                                         ': \u20ac ',
                                                         formatC(as.numeric(value), format='f', digits=2, big.mark=','), 
                                                         '<br>',
                                                         description
                                                 ))) + #label=paste0('Betrag:<br>',description), 
                                        scale_y_continuous(labels=dollar_format(prefix="€")) + 
                                        xlab('') +
                                        ylab('') +
                                        geom_line(group=1) + 
                                        geom_point() + 
                                        theme_bw()
                                outputPlot <- ggplotly(gg, tooltip=c('text'))
                        } else {
                                createAlert(session, 'dataStatus', alertId = 'myDataStatus',
                                            style = 'warning', append = FALSE,
                                            title = 'Keine Daten im gewählten Zeitfenster',
                                            content = 'Für das ausgewählte Zeitfenster sind keine Daten vorhanden.')
                        }
                } else {
                        createAlert(session, 'dataStatus', alertId = 'myDataStatus',
                                    style = 'warning', append = FALSE,
                                    title = 'Ungültiges Zeitfenster',
                                    content = 'Im ausgewählten Zeitfenster liegt das End-Datum vor dem Beginn-Datum. Korriege die Eingabe!')
                }
        } else {
                createAlert(session, 'dataStatus', alertId = 'myDataStatus',
                            style = 'warning', append = FALSE,
                            title = 'Keine Daten in der PIA vorhanden',
                            content = 'Derzeit sind noch keine Daten in der PIA erfasst. Wechsle zu "Datenquellen" und importiere Kontodaten oder richte auch gleich ein Erinnerungsmail ein!')
        }
        dev.off()
        layout(outputPlot)
}
