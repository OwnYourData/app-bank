# dialog with assisstant to configure connection to PIA and other items
# last update:2016-10-29

uiStart <- function(){
        bsModal('startConfig', 'Assistent zur Konfiguration', 'launchDialog', size='large',
                bsCollapse(id = "collapse", open = "Willkommen",
                           bsCollapsePanel("Willkommen (Schritt 1 von 4)",
                                           value="Willkommen",
                                           "Dieser Assistent hilft dir dabei die App einzurichten. Klicke auf 'Weiter', um zum nächsten Schritt zu gelangen!",
                                           br(),br(),
                                           actionButton("p1next", "Weiter"),
                                           style = "primary"),
                           bsCollapsePanel("Datentresor (Schritt 2 von 4)",
                                           value="PIA",
                                           "Trage hier die Verbindungdaten zu deinem Datentresor und den darin gespeicherten Daten ein. Du findest diese Informationen im Datentresor bei jeder App unter 'Details'.",
                                           br(),br(),
                                           fluidRow(
                                                   column(6,
                                                          textInput('modalPiaUrl', 'URL:'),
                                                          textInput('modalPiaId', 'ID:'),
                                                          textInput('modalPiaSecret', 'Secret:')
                                                   ),
                                                   column(6,
                                                          uiOutput('currentToken'),
                                                          conditionalPanel(
                                                                  condition = "output.currentToken != ''",
                                                                  actionButton('disconnectPIA', 'Verbindung zum Datentresor trennen', 
                                                                               icon('chain-broken'))
                                                          ),
                                                          br(),
                                                          uiOutput('connectError')
                                                   )
                                           ),
                                           br(),
                                           actionButton('p2prev', 'Zurück'),
                                           actionButton('p2next', 'Speichern & Weiter'),
                                           style = "info"),
                           bsCollapsePanel("Email-Konfiguration - Optional (Schritt 3 von 4)",
                                           value = "Email",
                                           "Falls du ein eigenes Emailkonto zum Versenden und Empfangen von Emails verwenden möchtest, kannst du hier die notwendigen Verbindungsdaten eingeben. Falls die Konfiguration leer bleibt, wird der Emailserver von OwnYourData verwendet.",
                                           br(),br(),
                                           textInput('modalMailerAddress', 'Mail Server:'),
                                           numericInput('modalMailerPort', 'Port:', 0),
                                           textInput('modalMailerUser', 'Benutzer:'),
                                           passwordInput('modalMailerPassword', 'Passwort'),
                                           br(),
                                           actionButton('p3prev', 'Zurück'),
                                           actionButton('p3next', 'Speichern & Weiter'),
                                           actionButton('p3skip', 'Überspringen'),
                                           style = "info"),
                           bsCollapsePanel("Fertig (Schritt 4 von 4)",
                                           value="Fertig",
                                           "Gratulation! Du hast alle notwendigen Einstellungen vorgenommen und kannst nun die App verwenden. Solltest du später eine Änderung vornehmen wollen, findest du alle Konfigurationsmöglichkeiten im Bereich 'Einstellungen'.",
                                           br(),br(),
                                           actionButton('p4prev', 'Zurück'),
                                           actionButton('p4close', 'Fertig'),
                                           style = "info")
                )
        )
}