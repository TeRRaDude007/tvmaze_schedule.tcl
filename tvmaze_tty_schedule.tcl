# =====================================================
# TeRRaDuDE TV Schedule Announcement Script
# Version: v2.0.0
# Last Updated: 2024-09-13
# =====================================================
#
# Changelog:
# V2.0.0
# - Trigger update(s)
#   /!today [country_code] → Announces today’s schedule starting from the current hour.
#   /!tomorrow [country_code] → Announces tomorrow’s schedule starting from the current hour.
#   /!yesterday [country_code] → Announces yesterday’s schedule starting from the current hour.
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

# Bind commands to specific IRC triggers
bind pub - !today pub:announceToday
bind pub - !tomorrow pub:announceTomorrow
bind pub - !yesterday pub:announceYesterday

# Helper procedure to announce TV schedule based on date
proc pub:announceSchedule {nick host handle chan arg date} {
    set countryCode [string toupper $arg]
    
    # Default to US if no country code is provided or invalid input
    if {[string length $countryCode] != 2} {
        set countryCode "US"
        putquick "PRIVMSG $chan : Invalid or missing country code. Defaulting to US."
    }

    # Get the current hour
    set currentHour [clock format [clock seconds] -format %H]
    
    # Build the URL using the current hour, date, and country code
    set url "http://api.tvmaze.com/schedule?country=$countryCode&hour=$currentHour&date=$date"
    
    set response [http::geturl $url]
    set data [http::data $response]
    set shows [json::json2dict $data]
    
    set count 0
    set maxBeforeDelay 10
    set skip_words { "Episode" "News" }
    
    putquick "PRIVMSG $chan : Announcing TV schedule for $countryCode on $date from hour $currentHour!"
    
    foreach show $shows {
        set show_info [dict get $show "show"]
        set name [dict get $show_info "name"]
        set season [dict get $show "season"]
        set number [dict get $show "number"]
        set time [dict get $show "airtime"]
        set network_info [dict get $show_info "network"]
        set network [dict get $network_info "name"]
        
        # Skip shows that match unwanted patterns (e.g., year in season, specific words)
        if {[regexp {^S[0-9]{4}} "S$season"] || [lsearch -exact $skip_words $name] != -1} {
            continue
        }
        
        # Ensure season and episode numbers are properly formatted
        if {[string length $season] == 1} {set season "0$season"}
        if {[string length $number] == 1} {set number "0$number"}
        
        # Announce show information
        putquick "PRIVMSG $chan : $name \00314(S$season/E$number)\017 airs at $time on $network"
        
        # Delay after every 10 announcements
        incr count
        if {$count % $maxBeforeDelay == 0} {
            after 3000
        }
    }
}

# Command to announce today's schedule
proc pub:announceToday {nick host handle chan arg} {
    set today [clock format [clock seconds] -format %Y-%m-%d]
    pub:announceSchedule $nick $host $handle $chan $arg $today
}

# Command to announce tomorrow's schedule
proc pub:announceTomorrow {nick host handle chan arg} {
    set tomorrow [clock format [expr {[clock seconds] + 86400}] -format %Y-%m-%d]
    pub:announceSchedule $nick $host $handle $chan $arg $tomorrow
}

# Command to announce yesterday's schedule
proc pub:announceYesterday {nick host handle chan arg} {
    set yesterday [clock format [expr {[clock seconds] - 86400}] -format %Y-%m-%d]
    pub:announceSchedule $nick $host $handle $chan $arg $yesterday
}
# EOF
# !!!+++ This Script Comes Without any Support +++!!!
# ./Just enjoy it.
