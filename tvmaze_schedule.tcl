# =====================================================
# TeRRaDuDE TV Schedule Announcement Script
# Version: v1.2.0
# Last Updated: 2024-09-12
# =====================================================
# Changelog:
#
# v1.2.0 - 2024-09-12
# - Added !tomorrow trigger to fetch tomorrow's TV schedule.
# - Automatically adjusted start hour based on the country's local time.
# - Skipped episodes with season numbers formatted as years (e.g., S2024).
#
# v1.1.0 - 2024-09-06
# - Added support for custom country codes (e.g., !today UK or !today NL).
# - Limited announcements to a max of 10 per batch with a 2-second delay.
# - Skipped shows with specific keywords in their titles (e.g., News, FOX).
#
# v1.0.0 - 2024-09-01
# - Initial version with basic !today trigger.
# - Announced the TV schedule for US only, with season/episode information.
# =====================================================

package require http
package require json

bind pub - !today pub:announce_today
bind pub - !tomorrow pub:announce_tomorrow

# Announce today's schedule
proc pub:announce_today {nick host handle chan arg} {
    announce_schedule $nick $chan $arg 0
}

# Announce tomorrow's schedule
proc pub:announce_tomorrow {nick host handle chan arg} {
    announce_schedule $nick $chan $arg 1
}

# Main announcement function for both today and tomorrow
proc announce_schedule {nick chan arg day_offset} {
    set priv_msg_enabled 0   ;# Set 1 for PM, 0 for channel
    set now [clock seconds]

    # Calculate the date, with the day_offset (0 for today, 1 for tomorrow)
    set date [clock format [expr {$now + ($day_offset * 86400)}] -format "%Y-%m-%d"]
    set hour [clock format $now -format "%H"]   ;# Get the current hour

    # Default country is US, but accept a custom country code from the argument (like !today UK)
    if {[llength $arg] > 0} {
        set countryCode [lindex $arg 0]  ;# Get the country code from the user's command (e.g., UK, NL, etc.)
    } else {
        set countryCode "US"  ;# Default to US if no country code is provided
    }

    # Query shows starting from the current hour in the chosen country
    set url "http://api.tvmaze.com/schedule?country=$countryCode&hour=$hour&date=$date"
    set response [http::geturl $url]
    set data [http::data $response]
    set shows [json::json2dict $data]

    set count 0
    set announcement_count 0
    set skip_words { "Episode" "0 and 2." }

    # Determine whether to send message to channel or in PM
    if {$priv_msg_enabled == 1} {
        set output_location "PRIVMSG $nick"
        putquick "PRIVMSG $nick : Here is the TV schedule for [expr {$day_offset == 0 ? "today" : "tomorrow"}] in country $countryCode:"
    } else {
        set output_location "PRIVMSG $chan"
        putquick "PRIVMSG $chan : Here is the TV schedule for [expr {$day_offset == 0 ? "today" : "tomorrow"}] in country $countryCode:"
    }

    # Loop through the shows and process them
    foreach show $shows {
        if {$announcement_count == 15} {
            putquick "$output_location : \00315Hold on, there is more to process...\003"
            after 5000  ;# Pause for 5 seconds
            set announcement_count 0
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

        # Skip shows that start with a year (e.g., "2024 XYZ Show")
        if {[regexp {^[0-9]{4}} $name]} {
            continue
        }

        # Skip episodes where the season number is a year (e.g., S2024)
        if {[regexp {^[0-9]{4}$} $season]} {
            continue
        }

        # Skip shows based on the skip_words list
        if {[lsearch -exact $skip_words $name] == -1} {

            # Pad season and episode with leading zero if they are single digits
            if {[string length $season] == 1} {
                set season "0$season"
            }
            if {[string length $number] == 1} {
                set number "0$number"
            }

            putquick "$output_location : \00304$name\003 \00314(S$season/E$number)\003 \00304airs at\003 \00314$time\003 \00304on\003 (\00314$network\003)"
            incr count
            incr announcement_count
        }
    }

    # Final message when all shows have been processed
    putquick "$output_location : \00315End of TV schedule list for [expr {$day_offset == 0 ? "today" : "tomorrow"}] in country $countryCode. Checking for new shows again soon...\003"
}
