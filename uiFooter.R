# footer of the app
# last update:2016-10-06

uiFooter <- function() {
        fluidRow(
                column(1),
                column(5, style='margin:-14px 0 0 10px',
                       a(href='https://www.ownyourdata.eu', img(src='oyd.jpg',width='65px')),
                       div(htmlOutput('displayVisual'), style='color:white'),
                       div(htmlOutput('displaySource'), style='color:white'),
                       div(htmlOutput('displayStore'), style='color:white')),
                column(5,
                       helpText(a(href='mailto:support@ownyourdata.eu', 'kontaktiere uns'), 'bei Fragen oder Anregungen',
                                style='float:right;margin-right:25px;'))
        )
}