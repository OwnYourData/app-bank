uiStatusItems <- function(){
        source('uiStatusItemsFixed.R')
        # uiStatusItemsFixed()
        tagList(
                bsAlert('dataStatus'),
                uiStatusItemsFixed()
                # uiOutput('desktopUiStatusItemsRender')
        )
}
