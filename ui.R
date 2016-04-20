# Setup and config ========================================
library(shiny)
library(shinyBS) #https://ebailey78.github.io/shinyBS/index.html

source("oyd_helpers.R")

saved <- getPiaConnection('bank')
saved_url        <- saved[['url']]
saved_app_key    <- saved[['app_key']]
saved_app_secret <- saved[['app_secret']]

# Shiny UI ================================================
shinyUI(fluidPage(
  titlePanel("Kontoentwicklung"),
  bsAlert("topAlert"),
  sidebarLayout(
    sidebarPanel(
            tabsetPanel(type='tabs', selected='Kontoentwicklung',
# Bank specific ===========================================
                        tabPanel('Kontoentwicklung',
                                 h3('Anzeige'),
                                 dateRangeInput('dateRange',
                                                language = 'de',
                                                separator = ' bis ',
                                                format = 'dd.mm.yyyy',
                                                label = 'Zeitfenster',
                                                start = Sys.Date() - 365, end = Sys.Date()),
                                 hr(),
                                 h3('Import'),
                                 selectInput('bankInstitute', "Bankinstitut", 
                                             choices = list('auswählen...', 
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
                                 h3('Speichern'),
                                 actionButton('exportButton', 'Daten in PIA schreiben'),
                                 htmlOutput('last_saved'),
                                 helpText('wählen sie diese Funktion nach dem CSV Import, um ihre Bankdaten mit bereits vorhandenen Daten zusammenzuführen und permanent in der PIA zu speichern')
                        ),

# PIA =====================================================
                        tabPanel("PIA", 
                            h3('Authentifizierung'),
                            textInput('bank_url', 'Adresse:', saved_url),
                            textInput('bank_app_key', 'ID (Kontoentwicklung):', saved_app_key),
                            textInput('bank_app_secret', 'Secret (Kontoentwicklung):', saved_app_secret),
                            checkboxInput("localBankSave", label = "Zugriffsinformationen lokal speichern", value = FALSE),
                            hr(),
                            htmlOutput("bank_token"),
                            htmlOutput("bank_records")
                        ),

# Scheduler ===============================================
                        tabPanel("Benachrichtigung", 
                                 h3('Benachrichtigung'),
                                 textInput('email', 'Emailadresse:'),
                                 htmlOutput("email_status"),
                                 helpText('Wenn sie hier ihre Emailadresse eingeben, erhalten sie jeden Monatsanfang eine Email mit der Erinnerung einen aktuellen Kontoexport hochzuladen.'),
                                 hr(),
                                 h3('Email Konfiguration'),
                                 htmlOutput("mail_config"),
                                 textInput('mailer_address', 'Mail Server:'),
                                 numericInput('mailer_port', 'Port:', 0),
                                 textInput('mailer_user', 'Benutzer:'),
                                 passwordInput('mailer_password', 'Passwort')
                        )
            )
    ),

# Main Panel ==============================================
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
