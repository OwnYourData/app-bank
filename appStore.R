# layout for section "Storage"
# last update: 2016-10-06

appStore <- function(){
        fluidRow(
                column(12,
                       h3('Datenblatt'),
                       rHandsontableOutput('dataSheet'),
                       br(),
                       htmlOutput('dataSheetDirty', inline = TRUE),
                       conditionalPanel(
                               condition = "output.dataSheetDirty != ''",
                               tagList(actionButton('saveSheet', 
                                                    'Daten in PIA speichern', 
                                                    icon=icon('save')),
                                       br(),br())),
                       downloadButton('exportCSV', 'CSV Export')
                )
        )
}
