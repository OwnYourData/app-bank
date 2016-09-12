tabPanel(icon('cog'),
         br(),
         fluidRow(
                 column(3,
                        selectInput('extStatusList', 
                                    'Vorhandene Darstellungen:',
                                    statTabUiList,
                                    multiple=TRUE, selectize=FALSE),
                        actionButton('delExtStatusList', 'Entfernen', icon('trash'))),
                 column(8,
                        selectInput('extStatusView',
                                    'Quelle:',
                                    c('SAM'='sam', 'Github'='github', 'Lokal'='local'),
                                    selectize=FALSE),
                        conditionalPanel(
                                condition = 'input.extStatusView == \"sam\"',
                                selectInput('extStatusListSam',
                                            'Auswahl:',
                                            c('Visual #1', 'Visual #2'),
                                            multiple=TRUE, selectize=FALSE),
                                actionButton('addExtStatusItemSam', 'Hinzufügen', icon('plus'))),
                        conditionalPanel(
                                condition = 'input.extStatusView == \"github\"',
                                textInput('extStatusItemGithub',
                                          'Pfad:'),
                                helpText('Im angegebenen Verzeichnis werden die Dateien oyd.json, sub_ui.R und sub_server.R ausgelesen.')),
                        conditionalPanel(
                                condition = 'input.extStatusView == \"local\"',
                                textInput('extStatusItemName',
                                          'Name:'),
                                tags$label('Ansicht (ui.R):'),
                                br(),
                                tags$textarea(id='extStatusItemUi',
                                              rows=5, cols=80),
                                br(),
                                tags$label('Logik (server.R):'),
                                br(),
                                tags$textarea(id='extStatusItemLogic',
                                              rows=5, cols=80),
                                br(),
                                actionButton('addExtStatusItem', 'Hinzufügen', icon('plus')),
                                actionButton('updateExtStatusItem', 'Aktualisieren', icon('edit'))
                        )
                 )
         )
)
