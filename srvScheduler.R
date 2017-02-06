# functions for setting up recurring tasks
# last update:2016-10-13

readSchedulerItems <- reactive({
        app <- currApp()
        if(length(app) > 0){
                url <- itemsUrl(app[['url']], schedulerKey)
                allItems <- readItems(app, url)
                if(nrow(allItems) == 0){
                        data.frame()
                } else {
                        allItems[allItems$app == app[['app_key']] & 
                                 !is.na(allItems$app), ]
                }
        } else {
                data.frame()
        }
})