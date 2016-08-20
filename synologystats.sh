#!/bin/bash

#This script pulls storage information from the Synology NAS

#The time we are going to sleep between readings
#Also used to calculate the current usage on the interface
#30 seconds seems to be ideal, any more frequent and the data
#gets really spikey.  Since we are calculating on total octets
#you will never loose data by setting this to a larger value.
sleeptime=30

get_volume_usage () {
    COUNTER=0
    while [  $COUNTER -lt 4 ]; do
        # Allocation Block size (8192)
        # INTEGER: 8192 Bytes
        syno_volblocksize=`snmpget -v 2c -c public 192.168.1.3 1.3.6.1.2.1.25.2.3.1.4.50 -Ov | cut -c 10- | grep -o '[0-9]*'`

        # Total Data Size
        # HOST-RESOURCES-MIB::hrStorageSize.50 = INTEGER: 1918724446
        # INTEGER: 1918724446
        syno_volcapacity=`snmpget -v 2c -c public 192.168.1.3 1.3.6.1.2.1.25.2.3.1.5.50 -Ov | cut -c 10-`


        # Used Data Size
        # HOST-RESOURCES-MIB::hrStorageUsed.50 = INTEGER: 1378018689
        # INTEGER: 1378017377
        syno_volused=`snmpget -v 2c -c public 192.168.1.3 1.3.6.1.2.1.25.2.3.1.6.50 -Ov | cut -c 10-`

        # Calculation to TB is =(DataSize*AllocationSize)/1024/1024/1024/1024
        if [[ $syno_volblocksize -le 0 || $syno_volcapacity -le 0 || $syno_volused -le 0 ]];
            then
                echo "Retry getting data - received some invalid data from the read"
            else
                #We got good data - exit this loop
                COUNTER=10
        fi
        let COUNTER=COUNTER+1
    done
}

get_drive_temps () {
    counter=0
    numdrives=4
    while [  $counter -lt $numdrives ]; do

        #Get Drive Name
        syno_drivename=`snmpget -v 2c -c public 192.168.1.3 1.3.6.1.4.1.6574.2.1.1.2.$counter -Ov | cut -c 10-`
        syno_drivename=${syno_drivename::-1}
        syno_drivename=${syno_drivename// /_}

        #Get Health Status
        syno_healthstatus=`snmpget -v 2c -c public 192.168.1.3 1.3.6.1.4.1.6574.2.1.1.5.$counter -Ov | cut -c 10-`

        #Get Health Status
        syno_drivetemps=`snmpget -v 2c -c public 192.168.1.3 1.3.6.1.4.1.6574.2.1.1.6.$counter -Ov | cut -c 10-`

        echo "Drive Name: $syno_drivename"
        echo "Health Status: $syno_healthstatus"
        echo "Drive Temps: $syno_drivetemps"

        # write to database here
        curl -i -XPOST 'http://192.168.1.3:8086/write?db=home' --data-binary "storage_data,host=synology,diskname=$syno_drivename disktemperature=$syno_drivetemps"
        curl -i -XPOST 'http://192.168.1.3:8086/write?db=home' --data-binary "storage_data,host=synology,diskname=$syno_drivename diskstatus=$syno_healthstatus"

        let counter=counter+1
    done
}

print_data () {
    echo "Synology Vol Used: $syno_volused"
    echo "Synology Vol Capacity: $syno_volcapacity"
    echo "Synology Vol Block Size: $syno_volblocksize"
}

write_data () {
    #Write the data to the database
    curl -i -XPOST 'http://192.168.1.3:8086/write?db=home' --data-binary "storage_data,host=synology,sensor=volused value=$syno_volused"
    curl -i -XPOST 'http://192.168.1.3:8086/write?db=home' --data-binary "storage_data,host=synology,sensor=volcapacity value=$syno_volcapacity"
    curl -i -XPOST 'http://192.168.1.3:8086/write?db=home' --data-binary "storage_data,host=synology,sensor=volblocksize value=$syno_volblocksize"
}

#Prepare to start the loop and warn the user
echo "Press [CTRL+C] to stop..."
while :
do
    get_drive_temps
    get_volume_usage

    if [[ $syno_volblocksize -le 0 || $syno_volcapacity -le 0 || $syno_volused -le 0 ]];
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