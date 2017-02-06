# top-level file for server logic
# last update: 2016-10-07

shinyServer(function(input, output, session) {
        source('srvBase.R', local=TRUE)
        source('appBaseShiny.R', local=TRUE)
        source('srvInit.R', local=TRUE)
        source('srvUi.R', local=TRUE)
        # source('srvExtension.R', local=TRUE)
        source('srvStore.R', local=TRUE)
        source('appLogic.R', local=TRUE)
})
