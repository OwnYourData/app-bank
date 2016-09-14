#source("appStatusItemDefault.R")

uiStatusItemsFixed <- function(){
        tabsetPanel(type='tabs',
                    tabPanel('Konto Chart',
                             #plotOutput(outputId = 'bankPlot', height = '300px'),
                             br(),
                             plotlyOutput('bankPlot')
                             # ,
                             # ggvisOutput('bankPlot')
                             # ,
                             # uiOutput("bankPlot_ui")
                    )
                    
#                appStatusItemDefaultUI('desktopStatusItems'),
#                appStatusItemDefault(),
#                uiStatusItemConfig()
        )
}
