# OYD: Template - last update:2016-07-28

shinyServer(function(input, output, session) {
        source('srvBase.R', local=TRUE)
        source('srvBaseShiny.R', local=TRUE)
        source('srvInit.R', local=TRUE)
        source('srvUi.R', local=TRUE)
        source('srvExtension.R', local=TRUE)
        source('srvStore.R', local=TRUE)
        source('appLogic.R', local=TRUE)
        session$sendCustomMessage(type='finishInit', NA)
})
