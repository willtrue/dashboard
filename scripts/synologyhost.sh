#!/bin/bash

#This script pulls system information from the Synology NAS

#The time we are going to sleep between readings
#Also used to calculate the current usage on the interface
#30 seconds seems to be ideal, any more frequent and the data
#gets really spikey.  Since we are calculating on total octets
#you will never loose data by setting this to a larger value.
sleeptime=30

get_uptime () {
    COUNTER=0
    while [  $COUNTER -lt 4 ]; do
        # System uptime
        syno_uptime=`snmpwalk -v 2c -c public 192.168.1.3 1.3.6.1.2.1.1.3 -Ovt`

        if [[ $syno_uptime -le 0 ]];
            then
                echo "Retry getting data - received some invalid data from the read"
            else
                #We got good data - exit this loop
                COUNTER=10
        fi
        let COUNTER=COUNTER+1
    done
}

print_data () {
    echo "Synology Uptime: $syno_uptime"
}

write_data () {
    #Write the data to the database
    curl -i -XPOST 'http://192.168.1.3:8086/write?db=home' --data-binary "host_data,host=synology,sensor=uptime value=$syno_uptime"
}

#Prepare to start the loop and warn the user
echo "Press [CTRL+C] to stop..."
while :
do
    get_uptime

    if [[ $syno_uptime -le 0 ]];
        then
            echo "Skip this datapoint - something went wrong with the read"
        else
            #Output console data for future reference
            print_data
            write_data
    fi

    #Sleep between readings
    sleep "$sleeptime"

done