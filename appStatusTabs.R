defaultStatTabUI <- "
        tabPanel('Tab Titel',
                 textInput(inputId=ns('defaultInput'), '--Eingaben:'),
                 htmlOutput(outputId = ns('defaultStatusItem'))
        )
"

defaultSrcTabUI <- "
        tabPanel('Email', 
                 p('hello world')
        )
"
