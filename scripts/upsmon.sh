#!/bin/bash

#This script pulls ups information from the synology NAS
#and from the other Cyberpower UPS.

#The time we are going to sleep between readings
#Also used to calculate the current usage on the interface
#30 seconds seems to be ideal, any more frequent and the data
#gets really spikey.  Since we are calculating on total octets
#you will never loose data by setting this to a larger value.
sleeptime=30

get_ups_info () {
    COUNTER=0
    while [  $COUNTER -lt 4 ]; do
        #-- Synology NAS --
        #UPS Battery Voltage
        syno_battvoltage=`snmpget -v 2c -c public 192.168.1.3 1.3.6.1.4.1.6574.4.3.2.1.0 -Ov`
        #UPS Battery Charge
        syno_battcharge=`snmpget -v 2c -c public 192.168.1.3 1.3.6.1.4.1.6574.4.3.1.1.0 -Ov`
        #UPS Load
        syno_battload=`snmpget -v 2c -c public 192.168.1.3 1.3.6.1.4.1.6574.4.2.12.1.0 -Ov`
        #UPS Input Voltage
        syno_inputvoltage=`snmpget -v 2c -c public 192.168.1.3 1.3.6.1.4.1.6574.4.4.1.1.0 -Ov`
        #UPS Runtime
        syno_runtime=`snmpget -v 2c -c public 192.168.1.3 1.3.6.1.4.1.6574.4.3.6.1.0 -Ov`

        syno_battvoltage=$(echo $syno_battvoltage | cut -c 16-)
        syno_battcharge=$(echo $syno_battcharge | cut -c 16-)
        syno_battload=$(echo $syno_battload | cut -c 16-)
        syno_inputvoltage=$(echo $syno_inputvoltage | cut -c 16-)
        syno_runtime=$(echo $syno_runtime | cut -c 10-)

        # syno_battvoltage=$(printf "%.0f" $syno_battvoltage)
        # syno_battcharge=$(printf "%.0f" $syno_battcharge)
        # syno_battload=$(printf "%.0f" $syno_battload)
        # syno_inputvoltage=$(printf "%.0f" $syno_inputvoltage)

        if [[ $syno_battvoltage -le 0 || $syno_battcharge -le 0 || $syno_battload -le 0 || $syno_inputvoltage -le 0 || $syno_runtime -le 0 ]];
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
    echo "Synology UPS Battery Voltage: $syno_battvoltage"
    echo "Synology UPS Battery Charge: $syno_battcharge"
    echo "Synology UPS Load: $syno_battload"
    echo "Synology UPS Input Voltage: $syno_inputvoltage"
    echo "Synology UPS Runtime: $syno_runtime"
}

write_data () {
    #Write the data to the database
    curl -i -XPOST 'http://192.168.1.3:8086/write?db=home' --data-binary "ups_data,host=synology,sensor=battvoltage value=$syno_battvoltage"
    curl -i -XPOST 'http://192.168.1.3:8086/write?db=home' --data-binary "ups_data,host=synology,sensor=battcharge value=$syno_battcharge"
    curl -i -XPOST 'http://192.168.1.3:8086/write?db=home' --data-binary "ups_data,host=synology,sensor=battload value=$syno_battload"
    curl -i -XPOST 'http://192.168.1.3:8086/write?db=home' --data-binary "ups_data,host=synology,sensor=inputvoltage value=$syno_inputvoltage"
    curl -i -XPOST 'http://192.168.1.3:8086/write?db=home' --data-binary "ups_data,host=synology,sensor=runtime value=$syno_runtime"
}

#Prepare to start the loop and warn the user
echo "Press [CTRL+C] to stop..."
while :
do

    get_ups_info

    if [[ $syno_battvoltage -le 0 || $syno_battcharge -le 0 || $syno_battload -le 0 || $syno_inputvoltage -le 0 || $syno_runtime -le 0 ]];
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