# functions for setting up recurring tasks
# last update:2016-10-13

readSchedulerItems <- function(){
        app <- currApp()
        if(length(app) > 0){
                url <- itemsUrl(app[['url']], schedulerKey)
                allItems <- readItems(app, url)
                allItems[allItems$app == app[['app_key']], ]
        } else {
                data.frame()
        }
}