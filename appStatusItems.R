# all tabs in section App-Status
# last update: 2016-10-06

appStatusItems <- function(){
        tabsetPanel(type='tabs',
                    tabPanel('Konto Chart', br(),
                             plotlyOutput('bankPlot')
                    ),
                    tabPanel('Gruppen Analyse', br(),
                             bsModal('groupAnalysisDetail',
                                     'Datensätze',
                                     trigger = NA,
                                     size='large',
                                     DT::dataTableOutput('groupAnalysisDetailList')
                             ),
                             bsModal('groupAnalysisChart',
                                     'Gruppen vergleichen',
                                     trigger = 'showGroupComparison',
                                     size='large',
                                     tagList(
                                             bsAlert('groupInfo'),
                                             plotOutput('groupChart')
                                     )),
                             
                             fluidRow(
                                     column(12,
                                            id='groupTableID',
                                            DT::dataTableOutput('groupAnalysis'),
                                            actionButton('showGroupDetails', 
                                                         'Details für Auswahl anzeigen', 
                                                         icon=icon('table')),
                                            actionButton('showGroupComparison', 
                                                         'Vergleich anzeigen', 
                                                         icon=icon('pie-chart')),
                                            actionButton('configureGroups', 
                                                         'Gruppen konfigurieren', 
                                                         icon=icon('wrench')))),
                             bsModal('groupAnalysisConfig', 
                                     'Gruppen konfigurieren',
                                     'configureGroups',
                                     size='large',
                                     tagList(bsAlert('grpConfigItemStatus'),
                                     fluidRow(
                                             column(3,
                                                    selectInput('grpConfigList',
                                                                'Gruppen:',
                                                                grpConfigUiList,
                                                                multiple=TRUE, 
                                                                selectize=FALSE,
                                                                size=12),
                                                    actionButton('delGrpConfigList', 'Entfernen', 
                                                                 icon('trash'))),
                                             column(8,
                                                    textInput('grpConfigItemName',
                                                              'Name:'),
                                                    tags$label('Auswahlkriterium Beschreibung:'),
                                                    br(),
                                                    tags$textarea(id='grpConfigItemDescFilter',
                                                                  rows=3, cols=80),
                                                    br(),
                                                    fluidRow(
                                                            column(4,
                                                                   selectInput('grpConfigItemValFilter', label = 'Auswahlkriterium Betrag:', 
                                                                               choices = list('keines' = 'not', '= (gleich)' = '=', '< (kleiner)' = '<', '> (größer)' = '>'), 
                                                                               selected = 'not')),
                                                            column(4,
                                                                   numericInput('grpConfigItemValFilterValue', '', value=NA))),
                                                    br(),
                                                    htmlOutput('grpConfigItemError', 
                                                               style='color:red'),
                                                    actionButton('addGrpConfigItem', 
                                                                 'Hinzufügen', icon('plus')),
                                                    actionButton('updateGrpConfigItem', 
                                                                 'Aktualisieren', icon('edit'))
                                             )
                                     )))
                    )
        )
}
