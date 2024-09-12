package require http
package require json

bind pub - !tv pub:announce

proc pub:announce {nick host handle chan arg} {
    #set date "2023-01-04"
    set now [clock seconds]
    set date [clock format $now -format "%Y-%m-%d"]
    set url "http://api.tvmaze.com/schedule?country=US&date=$date"
    set response [http::geturl $url]
    set data [http::data $response]
    set shows [json::json2dict $data]
    set count 0
    set exclude {"Episode"}
    putquick "PRIVMSG $chan :  Here is the TV schedule for today:"
    foreach show $shows {

        if {$count == 10} {
            after 5000
        }

        set name [dict get $show "name"]

        # Skip show if name starts with any of the strings in the exclude list
        set match 0
        foreach string $exclude {
            if {[regexp -nocase "^$string" $name]} {
                set match 1
                break
            }
        }
        if {$match} {
            continue
        }

        set season [dict get $show "season"]
        set number [dict get $show "number"]
        set time [dict get $show "airtime"]
        putquick "PRIVMSG $chan :  $name \(\00307E$number\003)\(\00307S$season\003) airs at $time"

        incr count
    }
}
