library(shiny)
library(shinyBS) #https://ebailey78.github.io/shinyBS/index.html

saved_bank_url <- ""
saved_bank_app_key <- ""
saved_bank_app_secret <- ""
if(file.exists("bankCredentials.RData"))
        load("bankCredentials.RData")

saved_scheduler_url <- ""
saved_scheduler_app_key <- ""
saved_scheduler_app_secret <- ""
if(file.exists("schedulerCredentials.RData"))
        load("schedulerCredentials.RData")

saved_mailer_address <- ""
saved_mailer_port <- ""
saved_mailer_user <- ""
saved_mailer_password <- ""
if(file.exists("mailConfig.RData"))
        load("mailConfig.RData")

shinyUI(fluidPage(
  titlePanel("Kontoentwicklung"),
  bsAlert("topAlert"),
  sidebarLayout(
    sidebarPanel(
            tabsetPanel(type='tabs', selected='Kontoentwicklung',
                        tabPanel('Kontoentwicklung',
                                 h3('Import'),
                                 selectInput('bankInstitute', "Bankinstitut", 
                                             choices = list('auswaehlen...', 
                                                            'Bawag/Easybank', 
                                                            'Erste Group', 
                                                            'ING-DiBa'), 
                                             selected = 1),
                                 fileInput('bankFile', 'CSV hochladen:',
                                           accept=c('text/csv', 
                                                    'text/comma-separated-values,text/plain', 
                                                    '.csv')),
                                 tags$script(
                                        'Shiny.addCustomMessageHandler("resetFileInputHandler", function(x) {      
                                             var id = "#" + x + "_progress";
                                             var idBar = id + " .bar";  
                                             $(id).css("visibility", "hidden");
                                             $(idBar).css("width", "0%");
                                             });'),
                                 hr(),
                                 h3('Referenzwert'),
                                 radioButtons('reference',
                                              label = 'Auswahl:',
                                              choices = list('Startwert'=1,
                                                             'Endwert'=2),
                                              selected = 1),
                                 numericInput('reference_value', 'Betrag:', 0),
                                 hr(),
                                 h3('Anzeige'),
                                 dateRangeInput('dateRange',
                                                language = 'de',
                                                separator = ' bis ',
                                                format = 'dd.mm.yyyy',
                                                label = 'Zeitfenster',
                                                start = Sys.Date() - 365, end = Sys.Date()),
                                 hr(),
                                 h3('Speichern'),
                                 actionButton('exportButton', 'Daten in PIA schreiben'),
                                 htmlOutput('last_saved'),
                                 helpText('wählen sie diese Funktion nach dem CSV Import, um ihre Bankdaten mit bereits vorhandenen Daten zusammenzuführen und permanent in der PIA zu speichern')
                        ),
                        tabPanel("PIA", 
                            h3('Authentifizierung'),
                            textInput('bank_url', 'Adresse:', saved_bank_url),
                            textInput('bank_app_key', 'ID (Kontoentwicklung):', saved_bank_app_key),
                            textInput('bank_app_secret', 'Secret (Kontoentwicklung):', saved_bank_app_secret),
                            checkboxInput("localBankSave", label = "Zugriffsinformationen lokal speichern", value = TRUE),
                            hr(),
                            htmlOutput("bank_token"),
                            htmlOutput("bank_records")
                        ),
                        tabPanel("Benachrichtigung", 
                                 h3('Authentifizierung'),
                                 textInput('scheduler_url', 'Adresse:', saved_scheduler_url),
                                  textInput('scheduler_app_key', 'ID (Scheduler):', saved_scheduler_app_key),
                                 textInput('scheduler_app_secret', 'Secret (Scheduler):', saved_scheduler_app_secret),
                                 checkboxInput("localSchedulerSave", label = "Zugriffsinformationen für Benachrichtigungen lokal speichern", value = TRUE),
                                 htmlOutput("scheduler_token"),
                                 hr(),
                                 h3('Email Konfiguration'),
                                 htmlOutput("mail_config"),
                                 textInput('mailer_address', 'Mail Server:', saved_mailer_address),
                                 numericInput('mailer_port', 'Port:', saved_mailer_port),
                                 textInput('mailer_user', 'Benutzer:', saved_mailer_user),
                                 passwordInput('mailer_password', 'Passwort', saved_mailer_password),
                                 h3('Benachrichtigung'),
                                 textInput('email', 'Emailadresse:'),
                                 htmlOutput("email_status"),
                                 helpText('Wenn sie hier ihre Emailadresse eingeben, erhalten sie jeden Monatsanfang eine Email mit der Darstellung des bisherigen Kontoverlaufs und der Erinnerung die aktuellen Daten hochzuladen.')
                        )
            )
    ),
    mainPanel(
            bsAlert("noData"),
            tabsetPanel(type="tabs",
                    tabPanel("Graph", 
                             plotOutput(outputId = "plot", height = "300px")),
                    tabPanel("Liste",
                             DT::dataTableOutput('table'))),
#                    tabPanel("Gruppierung",
#                             DT::dataTableOutput('group'))),
            bsAlert("noPIA")
    )
  )
))
