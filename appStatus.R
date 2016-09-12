source("uiStatusDateSelect.R")
source("uiStatusItems.R")
source("uiStatusItemConfig.R")

appStatus <- function(){
        fluidRow(
                column(12, 
                       uiStatusDateSelect(),
                       bsAlert('dataStatus'),
                       uiStatusItems()
                )
        )
}

defaultStatTabsName <- c('Plot')

defaultStatTabsUI <- c(
        "
        tabPanel('Plot',
                 plotOutput(outputId = ns('bank2Plot'), height = '300px')
        )
        "
)

defaultStatTabsLogic <- c(
        "
        output$bank2Plot <- renderPlot({
                data <- currData()
                plot(x=data$date, y=data$value, type='l', 
                        xlab='Datum', ylab='Euro')
        
        })
        "
)
