proc pub:announce {nick host handle chan arg} {
    set time [clock format [clock seconds] -format "%H:%M"]
    set country "US"
    if {$arg eq "NL"} {
        set country "NL"
    }
    set url "http://api.tvmaze.com/schedule?country=$country&start_time=$time"
    set response [http::geturl $url]
    set data [http::data $response]
    set shows [json::json2dict $data]
    set count 0
    set skip_words { "Episode" "0 and 2."}
    putquick "PRIVMSG $chan :  Here is the TV schedule for today:"
    foreach show $shows {
        if {$count == 50} {
            after 2000
        }
        set show_info [dict get $show "show"]
        set name [dict get $show_info "name"]
        set network_info [dict get $show_info "network"]
        if {$network_info eq "null"} {
            set network "Not Available"
        } else {
            set network [dict get $network_info "name"]
        }
        set season [dict get $show "season"]
        set number [dict get $show "number"]
        set time [dict get $show "airtime"]
        if {[lsearch -exact $skip_words $name] == -1} {
            putquick "PRIVMSG $chan :  $name \(S$season E$number\) airs at $time on $network"
            incr count
        }
    }
}
