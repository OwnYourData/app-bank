# initialize UI
# last update:2016-10-06

uiInit <- function(){
        tagList(
                initStore("store", "oydStore"),
                tags$script('setInterval(avoidIdle, 5000);
                            function avoidIdle() 
                            { Shiny.onInputChange("myData", 0) }'
                ),
                tags$script(paste0(
                        # JavaScript to hide initial "Wait"-Animation
                        # 'Shiny.addCustomMessageHandler("finishInit", function(x) {
                        #         $(".init-animation").fadeOut("slow");
                        # })'
                        "$(window).load(function(){
                        var url = window.location.href;
                        if(url.indexOf('PIA_URL=') == -1){
                        if(localStorage['oydStore\\\\pia_url'] === undefined) {
                        $('#startConfig').modal('show');
                        } else {
                        if(JSON.parse(localStorage['oydStore\\\\pia_url']).data === null) {
                        $('#startConfig').modal('show');
                        }
                        }
                        }
                        $('button:contains(\"Close\")').html('Schließen');
                        $('.dropdown-menu').attr('class', 'dropdown-menu pull-right');
                        $('a').filter(function(index) { return $(this).text() === \"", appTitle, "\"; }).css('display', 'none');
                        $('a').filter(function(index) { return $(this).text() === \"hidden\"; }).css('display', 'none');
                        });")),
                tags$script(
                        'Shiny.addCustomMessageHandler("setPiaUrl", function(x) {      
                                $("#returnPIAlink").attr("href", x);
                        })'
                ),
                tags$script(
                        'Shiny.addCustomMessageHandler("setMobileUrl", function(x) {      
                        $("#mobile_url").attr("href", x);
                })'),
                tags$script(
                        'Shiny.addCustomMessageHandler("openUrlInNewTab", function(x) {      
                                var win = window.open(x, "_blank");
                                win.focus();
                        })'
                ),
                tags$script(
                        'Shiny.addCustomMessageHandler("setDisplayButton", function(x) { 
                        var id = "#" + x;
                        $("#buttonVisual").css("background-color", "#f5f5f5");
                        $("#buttonVisual").css("color", "black");
                        $("#buttonSource").css("background-color", "#f5f5f5");
                        $("#buttonSource").css("color", "black");
                        $("#buttonStore").css("background-color", "#f5f5f5");
                        $("#buttonStore").css("color", "black");
                        $(id).css("background-color", "#45b79e");
                        $(id).css("color", "white");
                        });'
                ),
                tags$head(
                        tags$style(HTML(".navbar .navbar-nav {float: right}"))
                )
                )
}