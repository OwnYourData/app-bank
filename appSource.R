source("uiSourceItemConfig.R")

appSource <- function(){
        # uiOutput('desktopUiSourceItemsRender')
        fluidRow(
                column(12,
                       tabsetPanel(
                               type='tabs',
                               tabPanel('Kontoauszug importieren',
                                        fluidRow(
                                                column(6,
                                                       fileInput('bankFile', 
                                                                 label = h4('Kontoauszug:'))),
                                                column(6,
                                                       selectInput('bankInstitute', 
                                                                   label = h4('Institut:'), 
                                                                   choices = list('auswählen ...'='auswählen...',
                                                                                  'Bank Austria'='ba',
                                                                                  'Bawag/Easybank'='easy',
                                                                                  'Erste Group'='erste',
                                                                                  'ING-DiBa'='ingdiba')))),
                                        checkboxInput('showImportSettings', 'weitere Einstellungen anzeigen', FALSE),
                                        conditionalPanel(
                                                condition = 'input.showImportSettings',
                                                fluidRow(
                                                        column(4,
                                                               selectInput('bankImportHeader', label='Kopfzeile:', choices=list('Ja'=1, 'Nein'=2), selected=1),
                                                               textInput('bankImportSep', label='Trennzeichen:', ';'),
                                                               textInput('bankImportQuote', label='Anführungszeichen:', "\\\""),
                                                               textInput('bankImportDec', label='Dezimalzeichen:', '.')
                                                        ),
                                                        column(4,
                                                               textInput('bankImportEncoding', label='Dateikodierung:', 'utf-8'),
                                                               textInput('bankImportDescEnc', label='Zeichensatz:', 'latin1'),
                                                               textInput('bankImportDateFormat', label='Datumsformat:', '%d.%m.%Y')
                                                        ),
                                                        column(4,
                                                               numericInput('bankImportDateColumn', label='Datum-Spalte:', NA),
                                                               numericInput('bankImportDescColumn', label='Text-Spalte:', NA),
                                                               numericInput('bankImportValueColumn', label='Betrag-Spalte:', NA),
                                                               numericInput('bankImportValueSoll', label='Soll-Spalte:', NA),
                                                               numericInput('bankImportValueHaben', label='Haben-Spalte:', NA)
                                                        )
                                                )),
                                        actionButton('bankImport', 'Daten importieren', icon('save')),
                                        htmlOutput('bankImportInfo')
                               ),
                               tabPanel('Email Benachrichtigung einrichten',
                                        br())
                       )
                )
        )
}

defaultSrcTabsName <- c('SrcTab1', 'SrcTab2')

defaultSrcTabsUI <- c(
        "
        tabPanel('SrcTab1',
                textInput(inputId=ns('defaultSourceInput1'), 
                        'Eingabe1:'),
                htmlOutput(outputId = ns('defaultSourceItem1'))
        )
        ",
        "
        tabPanel('SrcTab2',
                textInput(inputId=ns('defaultSourceInput2'), 
                        'Eingabe2:'),
                htmlOutput(outputId = ns('defaultSourceItem2'))
        )
        "
)

defaultSrcTabsLogic <- c(
        "
        output$defaultSourceItem1 <- renderUI({
                input$defaultSourceInput1
        })
        ",
        "
        output$defaultSourceItem2 <- renderUI({
                input$defaultSourceInput2
        })
        "
)
