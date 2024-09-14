# =====================================================
# TeRRaDuDE Auto-announcement TVmaze show script
# Version: v1.0.0
# Last Updated: 2024-09-14
# =====================================================
#
# v1.0.0 - 2024-09-14
# - Extra Initial version witout a trigger.
# - Schedule the next auto-announcement in 1 hour.
# - Change #channelname where you want the output.
# - !setautochan #channelname specified channel / default announce in #defaultchannel
# =====================================================

# Required packages
package require http
package require json

# Global variable for the channel to announce in
set auto_announce_channel "#defaultchannel"

# Auto-announcement setup
proc auto_announce {channel} {
    global auto_announce_channel
    
    set now [clock seconds]
    set hour [clock format $now -format "%H"]   ;# Get the current hour
    set date [clock format $now -format "%Y-%m-%d"]  ;# Get today's date
    set countryCode "US"  ;# Default country is US. You can change it or make it configurable.

    # If no channel is provided, fall back to the default
    if {$channel eq ""} {
        set channel $auto_announce_channel
    }
    
    # TVMaze API call for the current hour
    set url "http://api.tvmaze.com/schedule?country=$countryCode&hour=$hour&date=$date"
    set response [http::geturl $url]
    set data [http::data $response]
    set shows [json::json2dict $data]

    # Announce shows starting this hour
    putquick "PRIVMSG $channel : \00314Auto-announcement: TV shows starting this hour (\00304$date \00314at \00304$hour:00\003):"

    set count 0
    foreach show $shows {
        set show_info [dict get $show "show"]
        set name [dict get $show_info "name"]
        set network_info [dict get $show_info "network"]
        set episode_title [dict get $show "name"]
        set season [dict get $show "season"]
        set number [dict get $show "number"]
        set time [dict get $show "airtime"]

        if {$network_info eq "null"} {
            set network "n/a"
        } else {
            set network [dict get $network_info "name"]
        }

        # Skip shows that start with a year (e.g., "2024 XYZ Show")
        if {[regexp {^[0-9]{4}} $name]} {
            continue
        }

        # Skip episodes where the season number is a year (e.g., S2024)
        if {[regexp {^[0-9]{4}$} $season]} { 
            continue
        }

        # Pad season and episode with leading zero if they are single digits
        if {[string length $season] == 1} {
            set season "0$season"
        }
        if {[string length $number] == 1} {
            set number "0$number"
        }

        # Pad number if the API is empty; replace (S)=Special to E00
        if {$number eq "null"} {
            set number "00"
        }

        # Announce the show
        putquick "PRIVMSG $channel : \00304$name\003 (\00314S$season/E$number\003 \"$episode_title\") \00304airs at\003 \00314$time\003 \00304on\003 (\00314$network\003)"
        incr count
    }

    if {$count == 0} {
        putquick "PRIVMSG $channel : \00314No shows starting this hour."
    } else {
        putquick "PRIVMSG $channel : \00314End of auto-announcement for shows starting at \00304$hour:00\003."
    }

    # Schedule the next auto-announcement after 3600 seconds (1 hour)
    after 3600000 [list auto_announce $channel]
}

# Command to set the auto-announcement channel
proc set_auto_announce_channel {nick host handle chan arg} {
    global auto_announce_channel

    # Get the new channel name from the user's command
    set new_channel [lindex $arg 0]
    
    if {$new_channel ne "" && [string first "#" $new_channel] == 0} {
        set auto_announce_channel $new_channel
        putquick "PRIVMSG $chan : \00314Auto-announcement channel set to\003 \00304$auto_announce_channel\003."
    } else {
        putquick "PRIVMSG $chan : \00304Invalid channel name! Please include a valid #channelname."
    }
}

# Start the first auto-announcement in the default or specified channel
auto_announce $auto_announce_channel

# Command bindings
bind pub - !setautochan set_auto_announce_channel

# EOF
# !!!+++ This Script Comes Without any Support +++!!!
# ./Just enjoy it.
