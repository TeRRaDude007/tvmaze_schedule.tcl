package require http
package require json

bind pub - !tv pub:announce

set priv_msg_enabled 1

proc pub:announce {nick host handle chan arg} {
    set now [clock seconds]
    set date [clock format $now -format "%Y-%m-%d"]
    set time [clock format $now -format "%H:%M"]
    set url "http://api.tvmaze.com/schedule?country=US&start_time=$time"
    set response [http::geturl $url]
    set data [http::data $response]
    set shows [json::json2dict $data]
    set count 0
    set skip_words { "Episode" "0 and 2."}
    
    # Determine the output location: channel or private message
    set output_location [expr {$priv_msg_enabled ? "PRIVMSG $nick" : "PRIVMSG $chan"}]
    
    # Initial message
    putquick "$output_location :Here is the TV schedule for today:"
    
    foreach show $shows {
        if {$count == 10} {
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
        
        # Skip shows that start with a year (e.g., 2022, 2023)
        if {[regexp {^\d{4}} $name]} {
            continue
        }
        
        # Skip shows based on predefined words
        if {[lsearch -exact $skip_words $name] == -1} {
            putquick "$output_location :$name (S$season E$number) airs at $time on $network"
            incr count
        }
    }
}
