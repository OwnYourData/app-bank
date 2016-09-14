uiStatusDateSelect <- function(){
        fluidRow(
                column(4,
                       dateRangeInput('dateRange',
                                      language = 'de',
                                      separator = ' bis ',
                                      format = 'dd.mm.yyyy',
                                      label = 'Zeitfenster',
                                      start = Sys.Date() - 30, end = Sys.Date()
                        )
                ),
                column(4,
                       selectInput('dateSelect',
                                   label = 'Auswahl',
                                   choices = c('letzte Woche'='1',
                                               'letztes Monat'='2',
                                               'letzten 2 Monate'='3',
                                               'letzten 6 Monate'='4',
                                               'aktuelles Jahr'='5',
                                               'letztes Jahr'='6',
                                               'alle Daten'='10',
                                               'individuell'='7'),
                                   selected = 4
                        )
                )
        )
}
