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
                                                               numericInput('bankImportDateColumn', label='Datum-Spalte:', 0),
                                                               numericInput('bankImportDescColumn', label='Text-Spalte:', 0),
                                                               numericInput('bankImportValueColumn', label='Betrag-Spalte:', 0),
                                                               numericInput('bankImportValueSoll', label='Soll-Spalte:', 0),
                                                               numericInput('bankImportValueHaben', label='Haben-Spalte:', 0)
                                                        )
                                                )),
                                        actionButton('bankImport', 'Daten importieren', icon('save')),
                                        htmlOutput('bankImportInfo')
                               ),
                               tabPanel('Referenzwert festlegen',
                                        helpText('Kontobewegungen beschreiben Eingänge oder Ausgaben von einem Konto. Durch die Angabe eines Referenzwertes kann daraus der Kontostand zu anderen Zeiten berechnet werden.'),
                                        dateInput('referenceDate', label = 'Datum des Referenzwerts:'),
                                        numericInput('referenceValue', label = 'Referenzwert:', value=0),
                                        actionButton('saveReference', 'Referenzwert speichern', icon('save')),
                                        htmlOutput('saveReferenceInfo')
                               ),
                               tabPanel('Email Benachrichtigung einrichten',
                                        br(),
                                        bsAlert('mailConfigStatus'),
                                        br(),
                                        textInput('mailerReceiver', 'Emailadresse des Empfängers'),
                                        selectInput('mailerInterval', 'Versandintervall:', choices = list(
                                                'auswählen...' = 1,
                                                'täglich'      = 2,
                                                'wöchentlich'  = 3,
                                                'monatlich'    = 4)),
                                        conditionalPanel(
                                                condition = 'input.mailerReceiver != ""',
                                                actionButton('endMailer', 'Emailversand beenden', icon('trash-o'))
                                        )
                               )
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
