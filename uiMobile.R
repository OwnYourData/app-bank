# top-level framework for mobile version
# last update:2016-10-06

uiMobile <- function(){
        navbarPage(
                uiOutput('hdrImageLinkMobile'),
                id='page',
                collapsible=TRUE,
                inverse=FALSE,
                windowTitle=paste0(appTitle, ' | OwnYourData'),
                tabPanel('Chart',
                         p('hello mobile world')),
                tabPanel('Datenblatt',
                         rHandsontableOutput('mobileDataSheet'),
                         br(),
                         htmlOutput('mobileDataSheetDirty', inline = TRUE),
                         conditionalPanel(
                                 condition = 'output.mobileDataSheetDirty != \"\"',
                                 tagList(actionButton('mobileSaveSheet', 
                                                      'Daten in PIA speichern', 
                                                      icon=icon('save'))))
                         
                ),
                tabPanel('PIA Einrichtung',
                         h3('PIA Einrichtung'),
                         textInput('pia_urlMobile', 'Adresse:'),
                         textInput('app_keyMobile', 'Key:'),
                         textInput('app_secretMobile', 'Secret:'),
                         actionButton('mobilePiaSave', 'Speichern'),
                         uiOutput('mobileToken'),
                         conditionalPanel(
                                 condition = "output.mobileToken != ''",
                                 actionButton('disconnectPIAmobile', 'Verbindung zu PIA trennen', 
                                              icon('chain-broken'))
                         )
                         
                )
        )
        # uiOutput('mobileUiStatusItemsRender')
}