appStatusItemDefaultUI <- function(id) {
        ns <- NS(id)
        tabPanel('Tab Titel',
                 textInput(inputId=ns('defaultInput'), 'Eingabe fix:'),
                 htmlOutput(outputId = ns('defaultStatusItem'))
        )
}
