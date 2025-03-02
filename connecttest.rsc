# tests a layer 3 network connection via ping to a designated IP address
# version 1.0-20250302.2/mz
# add to Scheduler with something like: /system/scheduler/add name=ConnTest disabled=yes on-event="/system script run \"connecttest.rsc\"" interval=3

# future changes:
# add: fallback destination IP adress(es) if next hop is offline
# add: include destination IP in log msgs
# change: "WAN" to "Connection" or so .. make it rather universally usable 
# change: write only one line to log if only one packet was dropped
# consider: minimum packet loss before writing to log at all - aka "threshold"
# consider: changing all debug msgs to log to debug msgs to global variables. Would need some management.
# consider: writing log msgs to separate log (file?)
# consider: a mode switch which let the script itself run in a loop and won't need a scheduler
# consider: better names for local and global variable, esp. for debugging!
# note: something like this surely exists somewhere already, doesn't it? (if so, consider this an exercise!)

# setting up below:  v - - - - - - - - - - v 
:local setupDestIP 83.216.32.162

:global CNNCTTSTnextHopIP ; # insert the next hop's IP towards $CNNCTTSTdestIP here!
:if ([:typeof $CNNCTTSTnextHopIP] = "nothing") do={:set CNNCTTSTnextHopIP 192.168.0.1}; # so, var can be changed outside!
#                                               change default value here ^^^

:local revdMsgStr "noitcennoc NAW --"; # start of log-msg reversed for cleaner find in logs
# setting up above:  ^ - - - - - - - - - - ^

:global CNNCTTSTdestIP ; # change IP address you want to check to your needs in WinBox's environment! 
:global CNNCTTSTisOutage
:global CNNCTTSToutageStart
:global CNNCTTSTnumLostPackets
:if ([:typeof $CNNCTTSTdestIP] = "nothing") do={:set CNNCTTSTdestIP $setupDestIP} # so, var can be changed outside!

:local nextHopOn [/ping $CNNCTTSTnextHopIP count=1]
:if ($nextHopOn = 1) do={ # continue testing $CNNCTTSTdestIP in main section

:local FrevString do={      # reverses given string
    :local inpStr $1
    :local revdStr ""
    :for i from=([:len $inpStr] - 1) to=0 do={
        :set revdStr ($revdStr . [:pick $inpStr $i])
 }
    :return $revdStr
}
:local logMsgStr [$FrevString $revdMsgStr]

:local pingResult [/ping $CNNCTTSTdestIP count=1];
#:log info "Ping result: $pingResult"
#:log info "Current CNNCTTSTisOutage value before checking: $CNNCTTSTisOutage"

:if ($pingResult = 0) do={  
    #:log info "Ping failed"
    #:log info "CNNCTTSTisOutage value before inner check: $CNNCTTSTisOutage"
    :if (!$CNNCTTSTisOutage) do={         # an unset boolean returns 'false'!
        #:log info "Connection outage detected!"
        :set CNNCTTSTisOutage true
        :set CNNCTTSToutageStart [/system clock get time]
        :set CNNCTTSTnumLostPackets 1; # first package already sent! 
        :log info "$logMsgStr lost at $CNNCTTSToutageStart !"
    } else={
        #:log info "before incrementing CNNCTTSTnumLostPackets"
        :set CNNCTTSTnumLostPackets ($CNNCTTSTnumLostPackets + 1)
    }
} else={
    #:log info "Ping successful"
    #:log info "CNNCTTSTisOutage value before setting to false: $CNNCTTSTisOutage"
    :if ($CNNCTTSTisOutage) do={
        #:log info "no more outage!"
        :set CNNCTTSTisOutage false
        :local outageEnd [/system clock get time]
        :log info "$logMsgStr restored at $outageEnd. $CNNCTTSTnumLostPackets packets dropped."
    }
}
} else={    # end main / would need indenting of above main section
        :global NextHopERROR ([/system clock get time] . ": next hop $CNNCTTSTnextHopIP not reachable!");
              # msg as global variable saves flooding the router's log
}
#:log info "End of Script - CNNCTTSTisOutage value: $CNNCTTSTisOutage"
