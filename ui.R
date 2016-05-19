# Setup and config ========================================
library(shiny)
library(shinyBS) #https://ebailey78.github.io/shinyBS/index.html
library(jsonlite)

source("oyd_helpers.R")

saved <- getPiaConnection('bank')
saved_url        <- saved[['url']]
saved_app_key    <- saved[['app_key']]
saved_app_secret <- saved[['app_secret']]

# Shiny UI ================================================
shinyUI(navbarPage(HTML(paste0('<a href=',shQuote(saved_url), '>', '<img height="25px" src="data:image/png;base64,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"></a>', ' <a href=',shQuote(saved_url), '>OwnYourData', '</a>')), id="page", collapsible=TRUE, inverse=FALSE,
                   tabPanel('Kontoentwicklung',
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
                   ),
navbarMenu('Infos',
           tabPanel(HTML("Version</a></li><li><a href=\"https://github.com/OwnYourData/app-bank/blob/master/README.md\">Anleitung"),
                    sidebarLayout(
                            sidebarPanel(
                                    p('Support: ', 
                                      a(href="mailto:office@ownyourdata.eu", 
                                        "office@ownyourdata.eu")),
                                    p('Bugtracking: ',
                                      a(href="https://github.com/OwnYourData/app-bank/issues",
                                        "Github")),
                                    hr(),
                                    p('entwickelt von ',
                                      a(href="https://www.ownyourdata.eu",
                                        'https://OwnYourData.eu')),
                                    p('MIT Lizenz, 2016')),
                            mainPanel(
                                    h2('akutelle Version: 0.4.1'),
                                    htmlOutput('upgradeLink'),
                                    hr(),
                                    h3('Versionsverlauf'),
                                    p(strong('Version 0.4.1')),
                                    p('UI Update (Menüleiste)'),
                                    p(strong('Version 0.4.0')),
                                    p('Kontoimport für IngDiBa und Erste Group hinzugefügt'),
                                    p(strong('Version 0.3.0')),
                                    p('erstes Release'))
                    )))
))
