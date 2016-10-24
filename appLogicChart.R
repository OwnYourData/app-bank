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
                        input$saveReference
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
                                                     as.Date(minDate)-1)
                                data <- data[, c('date', 'description', 'id', 'value', 'dat')]
                                colnames(refRow) <- colnames(data)
                                data <- rbind(refRow, data)
                        }
                        data <- data %>%
                                group_by(date) %>%
                                summarise(description = 
                                                  paste0('\u20ac ',
                                                         formatC(as.numeric(value), format='f', digits=2, big.mark=','), ': ',
                                                         description, 
                                                         collapse = '<br>'),
                                          value = sum(value))
                        data$dat <- as.Date(data$date)
                        data <- as.data.frame(data)
                        data <- data[order(data[, 'dat']),]
                        data$cumsum <- cumsum(data$value)
                        data <- data[data$dat %in% daterange, ]
                        if(nrow(data) > 0){
                                #euro <- dollar_format(prefix = "\u20ac ", suffix = "")
                                # all data until reference value
                                outputPlot <- plot_ly(data = data,
                                                      x = ~dat,
                                                      y = ~cumsum,
                                                      hoverinfo = 'text',
                                                      text = paste0(format(data$dat, '%d.%m.%Y'),
                                                                    ': \u20ac ',
                                                                    formatC(as.numeric(data$cumsum), format='f', digits=2, big.mark=','), 
                                                                    '<br>',
                                                                    data$description),
                                                      type = 'scatter',
                                                      mode = 'lines+markers',
                                                      line = list(width = 3),
                                                      marker = list(size = 8)) %>%
                                        layout(title = '',
                                               xaxis = list(title = ''),
                                               yaxis = list(title = '',
                                                            tickformat = ':04,2f',
                                                            tickprefix = '\u20ac '),
                                               showlegend = FALSE,
                                               margin = list(l = 80, r = 80)
                                        )
                                # gg <- ggplot(data, 
                                #              aes(x=dat, y=cumsum, 
                                #                  text=paste0(
                                #                          #format(dat, '%A, %d %b %Y'),
                                #                          format(dat, '%d.%m.%Y'),
                                #                          ': \u20ac ',
                                #                          formatC(as.numeric(cumsum), format='f', digits=2, big.mark=','), 
                                #                          '<br>',
                                #                          description
                                #                  ))) + #label=paste0('Betrag:<br>',description), 
                                #         scale_y_continuous(labels=dollar_format(prefix="€")) + 
                                #         xlab('') +
                                #         ylab('') +
                                #         geom_line(group=1) + 
                                #         geom_point() + 
                                #         theme_bw()
                                # outputPlot <- ggplotly(gg, tooltip=c('text'))
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
                            title = 'Keine Kontodaten im Datentresor vorhanden',
                            content = 'Derzeit sind noch keine Kontodaten im Datentresor gespeichert. Wechsle zu "Datenquellen" und importiere Kontodaten oder richte auch gleich ein Erinnerungsmail ein!')
        }
        dev.off()
        outputPlot
}
