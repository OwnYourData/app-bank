# top-level file for UI with option to switch between desktop and mobile
# last update:2016-10-06
shinyUI(
        uiDesktop()
        # tagList(
        #         conditionalPanel(
        #                 condition=(isDesktop),
        #                 uiDesktop()),
        #         conditionalPanel(
        #                 condition=(isMobile),
        #                 uiMobile())
        # )
)
