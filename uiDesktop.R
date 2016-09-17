source('uiStart.R')
source('uiApp.R')
source('uiMenu.R')
source('uiFooter.R')

uiDesktop <- function(){
        tagList(
                uiInit(),
                uiStart(),
                navbarPage(
                        uiOutput('hdrImageLinkDesktop'),
                                id='mainPage',
                                selected = appName,
                                collapsible=TRUE,
                                inverse=FALSE,
                                windowTitle=paste0(appTitle, ' | OwnYourData'),
                        tabPanel(HTML(paste0('hidden', 
                                             '</a></li>',
                                             '<li><a id="returnPIAlink" href="#">zurück zur PIA'))
                        ),
                        tabPanel(appTitle,
                                 value = appName,
                                 fluidRow(
                                         column(1),
                                         column(10,
                                                tagList(
                                                        bsAlert('urlStatus'),
                                                        bsAlert('piaStatus'))
                                         )
                                 ),
                                 uiApp()
                        ),
                        navbarMenu(icon('cog'),
                                   uiMenu()
                        ),
                        footer=uiFooter()
                )
        )
}