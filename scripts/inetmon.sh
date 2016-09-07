#!/bin/bash

#This script get the current bandwidth usage for both the main
#Internet interface as well as the guest interface and
#writes them to the InfluxDB instance running on this machine.

#The time we are going to sleep between readings
#Also used to calculate the current usage on the interface
#30 seconds seems to be ideal, any more frequent and the data
#gets really spikey.  Since we are calculating on total octets
#you will never loose data by setting this to a larger value.
sleeptime=30

#We need to get a baseline for the traffic before starting the loop
#otherwise we have nothing to base out calculations on.

# Use SNMP Walk to determine octets for ethernets
# snmpwalk -v 2c -c public 192.168.1.1
# iso.1.3.6.1.2.1.31.1.1.1.1.1 = STRING: "lo"
# iso.1.3.6.1.2.1.31.1.1.1.1.2 = STRING: "eth0" WAN
# iso.1.3.6.1.2.1.31.1.1.1.1.3 = STRING: "eth1" Wifi 2.4G
# iso.1.3.6.1.2.1.31.1.1.1.1.4 = STRING: "eth2" Wifi 5G
# iso.1.3.6.1.2.1.31.1.1.1.1.5 = STRING: "vlan1" LAN Switch
# iso.1.3.6.1.2.1.31.1.1.1.1.6 = STRING: "vlan2"
# iso.1.3.6.1.2.1.31.1.1.1.1.7 = STRING: "br0" Bridge
# iso.1.3.6.1.2.1.31.1.1.1.1.56 = STRING: "tun22" VPN

#Get in and out octets
old_lo_in=`snmpget -v 2c -c public 192.168.1.1 1.3.6.1.2.1.2.2.1.10.1 -Ov`
old_lo_out=`snmpget -v 2c -c public 192.168.1.1 1.3.6.1.2.1.2.2.1.16.1 -Ov`
old_eth0_in=`snmpget -v 2c -c public 192.168.1.1 1.3.6.1.2.1.2.2.1.10.2 -Ov`
old_eth0_out=`snmpget -v 2c -c public 192.168.1.1 1.3.6.1.2.1.2.2.1.16.2 -Ov`
old_eth1_in=`snmpget -v 2c -c public 192.168.1.1 1.3.6.1.2.1.2.2.1.10.3 -Ov`
old_eth1_out=`snmpget -v 2c -c public 192.168.1.1 1.3.6.1.2.1.2.2.1.16.3 -Ov`
old_eth2_in=`snmpget -v 2c -c public 192.168.1.1 1.3.6.1.2.1.2.2.1.10.4 -Ov`
old_eth2_out=`snmpget -v 2c -c public 192.168.1.1 1.3.6.1.2.1.2.2.1.16.4 -Ov`
old_vlan1_in=`snmpget -v 2c -c public 192.168.1.1 1.3.6.1.2.1.2.2.1.10.5 -Ov`
old_vlan1_out=`snmpget -v 2c -c public 192.168.1.1 1.3.6.1.2.1.2.2.1.16.5 -Ov`
old_vlan2_in=`snmpget -v 2c -c public 192.168.1.1 1.3.6.1.2.1.2.2.1.10.6 -Ov`
old_vlan2_out=`snmpget -v 2c -c public 192.168.1.1 1.3.6.1.2.1.2.2.1.16.6 -Ov`
old_br0_in=`snmpget -v 2c -c public 192.168.1.1 1.3.6.1.2.1.2.2.1.10.7 -Ov`
old_br0_out=`snmpget -v 2c -c public 192.168.1.1 1.3.6.1.2.1.2.2.1.16.7 -Ov`
old_tun22_in=`snmpget -v 2c -c public 192.168.1.1 1.3.6.1.2.1.2.2.1.10.56 -Ov`
old_tun22_out=`snmpget -v 2c -c public 192.168.1.1 1.3.6.1.2.1.2.2.1.16.56 -Ov`

#Strip out the value from the string
old_lo_in=$(echo $old_lo_in | cut -c 12-)
old_lo_out=$(echo $old_lo_out | cut -c 12-)
old_eth0_in=$(echo $old_eth0_in | cut -c 12-)
old_eth0_out=$(echo $old_eth0_out | cut -c 12-)
old_eth1_in=$(echo $old_eth1_in | cut -c 12-)
old_eth1_out=$(echo $old_eth1_out | cut -c 12-)
old_eth2_in=$(echo $old_eth2_in | cut -c 12-)
old_eth2_out=$(echo $old_eth2_out | cut -c 12-)
old_vlan1_in=$(echo $old_vlan1_in | cut -c 12-)
old_vlan1_out=$(echo $old_vlan1_out | cut -c 12-)
old_vlan2_in=$(echo $old_vlan2_in | cut -c 12-)
old_vlan2_out=$(echo $old_vlan2_out | cut -c 12-)
old_br0_in=$(echo $old_br0_in | cut -c 12-)
old_br0_out=$(echo $old_br0_out | cut -c 12-)
old_tun22_in=$(echo $old_tun22_in | cut -c 12-)
old_tun22_out=$(echo $old_tun22_out | cut -c 12-)

#Prepare to start the loop and warn the user
echo "Press [CTRL+C] to stop..."
while :
do
    #We need to wait between readings to have something to compare to
    sleep "$sleeptime"

    #Get in and out octets
    lo_in=`snmpget -v 2c -c public 192.168.1.1 1.3.6.1.2.1.2.2.1.10.1 -Ov`
    lo_out=`snmpget -v 2c -c public 192.168.1.1 1.3.6.1.2.1.2.2.1.16.1 -Ov`
    eth0_in=`snmpget -v 2c -c public 192.168.1.1 1.3.6.1.2.1.2.2.1.10.2 -Ov`
    eth0_out=`snmpget -v 2c -c public 192.168.1.1 1.3.6.1.2.1.2.2.1.16.2 -Ov`
    eth1_in=`snmpget -v 2c -c public 192.168.1.1 1.3.6.1.2.1.2.2.1.10.3 -Ov`
    eth1_out=`snmpget -v 2c -c public 192.168.1.1 1.3.6.1.2.1.2.2.1.16.3 -Ov`
    eth2_in=`snmpget -v 2c -c public 192.168.1.1 1.3.6.1.2.1.2.2.1.10.4 -Ov`
    eth2_out=`snmpget -v 2c -c public 192.168.1.1 1.3.6.1.2.1.2.2.1.16.4 -Ov`
    vlan1_in=`snmpget -v 2c -c public 192.168.1.1 1.3.6.1.2.1.2.2.1.10.5 -Ov`
    vlan1_out=`snmpget -v 2c -c public 192.168.1.1 1.3.6.1.2.1.2.2.1.16.5 -Ov`
    vlan2_in=`snmpget -v 2c -c public 192.168.1.1 1.3.6.1.2.1.2.2.1.10.6 -Ov`
    vlan2_out=`snmpget -v 2c -c public 192.168.1.1 1.3.6.1.2.1.2.2.1.16.6 -Ov`
    br0_in=`snmpget -v 2c -c public 192.168.1.1 1.3.6.1.2.1.2.2.1.10.7 -Ov`
    br0_out=`snmpget -v 2c -c public 192.168.1.1 1.3.6.1.2.1.2.2.1.16.7 -Ov`
    tun22_in=`snmpget -v 2c -c public 192.168.1.1 1.3.6.1.2.1.2.2.1.10.56 -Ov`
    tun22_out=`snmpget -v 2c -c public 192.168.1.1 1.3.6.1.2.1.2.2.1.16.56 -Ov`
    
    #Strip out the value from the string
    lo_in=$(echo $lo_in | cut -c 12-)
    lo_out=$(echo $lo_out | cut -c 12-)
    eth0_in=$(echo $eth0_in | cut -c 12-)
    eth0_out=$(echo $eth0_out | cut -c 12-)
    eth1_in=$(echo $eth1_in | cut -c 12-)
    eth1_out=$(echo $eth1_out | cut -c 12-)
    eth2_in=$(echo $eth2_in | cut -c 12-)
    eth2_out=$(echo $eth2_out | cut -c 12-)
    vlan1_in=$(echo $vlan1_in | cut -c 12-)
    vlan1_out=$(echo $vlan1_out | cut -c 12-)
    vlan2_in=$(echo $vlan2_in | cut -c 12-)
    vlan2_out=$(echo $vlan2_out | cut -c 12-)
    br0_in=$(echo $br0_in | cut -c 12-)
    br0_out=$(echo $br0_out | cut -c 12-)
    tun22_in=$(echo $tun22_in | cut -c 12-)
    tun22_out=$(echo $tun22_out | cut -c 12-)
    
    #Get the difference between the old and current
    diff_lo_in=$((lo_in - old_lo_in))
    diff_lo_out=$((lo_out - old_lo_out))
    diff_eth0_in=$((eth0_in - old_eth0_in))
    diff_eth0_out=$((eth0_out - old_eth0_out))
    diff_eth1_in=$((eth1_in - old_eth1_in))
    diff_eth1_out=$((eth1_out - old_eth1_out))
    diff_eth2_in=$((eth2_in - old_eth2_in))
    diff_eth2_out=$((eth2_out - old_eth2_out))
    diff_vlan1_in=$((vlan1_in - old_vlan1_in))
    diff_vlan1_out=$((vlan1_out - old_vlan1_out))
    diff_vlan2_in=$((vlan2_in - old_vlan2_in))
    diff_vlan2_out=$((vlan2_out - old_vlan2_out))
    diff_br0_in=$((br0_in - old_br0_in))
    diff_br0_out=$((br0_out - old_br0_out))
    diff_tun22_in=$((tun22_in - old_tun22_in))
    diff_tun22_out=$((tun22_out - old_tun22_out))
    
    #Calculate the bytes-per-second
    lo_in_bps=$((diff_lo_in / sleeptime))
    lo_out_bps=$((diff_lo_out / sleeptime))
    eth0_in_bps=$((diff_eth0_in / sleeptime))
    eth0_out_bps=$((diff_eth0_out / sleeptime))
    eth1_in_bps=$((diff_eth1_in / sleeptime))
    eth1_out_bps=$((diff_eth1_out / sleeptime))
    eth2_in_bps=$((diff_eth2_in / sleeptime))
    eth2_out_bps=$((diff_eth2_out / sleeptime))
    vlan1_in_bps=$((diff_vlan1_in / sleeptime))
    vlan1_out_bps=$((diff_vlan1_out / sleeptime))
    vlan2_in_bps=$((diff_vlan2_in / sleeptime))
    vlan2_out_bps=$((diff_vlan2_out / sleeptime))
    br0_in_bps=$((diff_br0_in / sleeptime))
    br0_out_bps=$((diff_br0_out / sleeptime))
    tun22_in_bps=$((diff_tun22_in / sleeptime))
    tun22_out_bps=$((diff_tun22_out / sleeptime))

    #Seems we need some basic data validation - can't have values less than 0!
    if [[ $lo_in_bps -lt 0 || $lo_out_bps -lt 0 || $eth0_in_bps -lt 0 ||  $eth0_out_bps -lt 0 || 
        $eth1_in_bps -lt 0 || $eth1_out_bps -lt 0 || $eth2_in_bps -lt 0 || 
        $eth2_out_bps -lt 0 || $vlan1_in_bps -lt 0 || $vlan1_out_bps -lt 0 || 
        $vlan2_in_bps -lt 0 || $vlan2_out_bps -lt 0 || $br0_in_bps -lt 0 || 
        $br0_out_bps -lt 0 || $tun22_in_bps -lt 0 || $tun22_out_bps -lt 0 ]];
    then
        #There is an issue with one or more readings, get fresh ones
        #then wait for the next loop to calculate again.
        echo "We have a problem...moving to plan B"
        
        #Get in and out octets
        old_lo_in=`snmpget -v 2c -c public 192.168.1.1 1.3.6.1.2.1.2.2.1.10.1 -Ov`
        old_lo_out=`snmpget -v 2c -c public 192.168.1.1 1.3.6.1.2.1.2.2.1.16.1 -Ov`
        old_eth0_in=`snmpget -v 2c -c public 192.168.1.1 1.3.6.1.2.1.2.2.1.10.2 -Ov`
        old_eth0_out=`snmpget -v 2c -c public 192.168.1.1 1.3.6.1.2.1.2.2.1.16.2 -Ov`
        old_eth1_in=`snmpget -v 2c -c public 192.168.1.1 1.3.6.1.2.1.2.2.1.10.3 -Ov`
        old_eth1_out=`snmpget -v 2c -c public 192.168.1.1 1.3.6.1.2.1.2.2.1.16.3 -Ov`
        old_eth2_in=`snmpget -v 2c -c public 192.168.1.1 1.3.6.1.2.1.2.2.1.10.4 -Ov`
        old_eth2_out=`snmpget -v 2c -c public 192.168.1.1 1.3.6.1.2.1.2.2.1.16.4 -Ov`
        old_vlan1_in=`snmpget -v 2c -c public 192.168.1.1 1.3.6.1.2.1.2.2.1.10.5 -Ov`
        old_vlan1_out=`snmpget -v 2c -c public 192.168.1.1 1.3.6.1.2.1.2.2.1.16.5 -Ov`
        old_vlan2_in=`snmpget -v 2c -c public 192.168.1.1 1.3.6.1.2.1.2.2.1.10.6 -Ov`
        old_vlan2_out=`snmpget -v 2c -c public 192.168.1.1 1.3.6.1.2.1.2.2.1.16.6 -Ov`
        old_br0_in=`snmpget -v 2c -c public 192.168.1.1 1.3.6.1.2.1.2.2.1.10.7 -Ov`
        old_br0_out=`snmpget -v 2c -c public 192.168.1.1 1.3.6.1.2.1.2.2.1.16.7 -Ov`
        old_tun22_in=`snmpget -v 2c -c public 192.168.1.1 1.3.6.1.2.1.2.2.1.10.56 -Ov`
        old_tun22_out=`snmpget -v 2c -c public 192.168.1.1 1.3.6.1.2.1.2.2.1.16.56 -Ov`

        old_lo_in=$(echo $old_lo_in | cut -c 12-)
        old_lo_out=$(echo $old_lo_out | cut -c 12-)
        old_eth0_in=$(echo $old_eth0_in | cut -c 12-)
        old_eth0_out=$(echo $old_eth0_out | cut -c 12-)
        old_eth1_in=$(echo $old_eth1_in | cut -c 12-)
        old_eth1_out=$(echo $old_eth1_out | cut -c 12-)
        old_eth2_in=$(echo $old_eth2_in | cut -c 12-)
        old_eth2_out=$(echo $old_eth2_out | cut -c 12-)
        old_vlan1_in=$(echo $old_vlan1_in | cut -c 12-)
        old_vlan1_out=$(echo $old_vlan1_out | cut -c 12-)
        old_vlan2_in=$(echo $old_vlan2_in | cut -c 12-)
        old_vlan2_out=$(echo $old_vlan2_out | cut -c 12-)
        old_br0_in=$(echo $old_br0_in | cut -c 12-)
        old_br0_out=$(echo $old_br0_out | cut -c 12-)
        old_tun22_in=$(echo $old_tun22_in | cut -c 12-)
        old_tun22_out=$(echo $old_tun22_out | cut -c 12-)

    else
        #Output the current traffic
        echo "Current traffic to lo_in: $lo_in_bps bps"
        echo "Current traffic to lo_out: $lo_out_bps bps"
        echo "Current traffic to eth0_in: $eth0_in_bps bps"
        echo "Current traffic to eth0_out: $eth0_out_bps bps"
        echo "Current traffic to eth1_in: $eth1_in_bps bps"
        echo "Current traffic to eth1_out: $eth1_out_bps bps"
        echo "Current traffic to eth2_in: $eth2_in_bps bps"
        echo "Current traffic to eth2_out: $eth2_out_bps bps"
        echo "Current traffic to vlan1_in: $vlan1_in_bps bps"
        echo "Current traffic to vlan1_out: $vlan1_out_bps bps"
        echo "Current traffic to vlan2_in: $vlan2_in_bps bps"
        echo "Current traffic to vlan2_out: $vlan2_out_bps bps"
        echo "Current traffic to br0_in: $br0_in_bps bps"
        echo "Current traffic to br0_out: $br0_out_bps bps"
        echo "Current traffic to tun22_in: $tun22_in_bps bps"
        echo "Current traffic to tun22_out: $tun22_out_bps bps"
        
        #todo
        #Write the data to the database
        curl -i -XPOST 'http://192.168.1.3:8086/write?db=dev' --data-binary "network_traffic,host=asus_rt_ac66u,interface=lo,direction=inbound value=$lo_in_bps"
        curl -i -XPOST 'http://192.168.1.3:8086/write?db=dev' --data-binary "network_traffic,host=asus_rt_ac66u,interface=lo,direction=outbound value=$lo_out_bps"
        curl -i -XPOST 'http://192.168.1.3:8086/write?db=dev' --data-binary "network_traffic,host=asus_rt_ac66u,interface=eth0,direction=inbound value=$eth0_in_bps"
        curl -i -XPOST 'http://192.168.1.3:8086/write?db=dev' --data-binary "network_traffic,host=asus_rt_ac66u,interface=eth0,direction=outbound value=$eth0_out_bps"
        curl -i -XPOST 'http://192.168.1.3:8086/write?db=dev' --data-binary "network_traffic,host=asus_rt_ac66u,interface=eth1,direction=inbound value=$eth1_in_bps"
        curl -i -XPOST 'http://192.168.1.3:8086/write?db=dev' --data-binary "network_traffic,host=asus_rt_ac66u,interface=eth1,direction=outbound value=$eth1_out_bps"
        curl -i -XPOST 'http://192.168.1.3:8086/write?db=dev' --data-binary "network_traffic,host=asus_rt_ac66u,interface=eth2,direction=inbound value=$eth2_in_bps"
        curl -i -XPOST 'http://192.168.1.3:8086/write?db=dev' --data-binary "network_traffic,host=asus_rt_ac66u,interface=eth2,direction=outbound value=$eth2_out_bps"
        curl -i -XPOST 'http://192.168.1.3:8086/write?db=dev' --data-binary "network_traffic,host=asus_rt_ac66u,interface=vlan1,direction=inbound value=$vlan1_in_bps"
        curl -i -XPOST 'http://192.168.1.3:8086/write?db=dev' --data-binary "network_traffic,host=asus_rt_ac66u,interface=vlan1,direction=outbound value=$vlan1_out_bps"
        curl -i -XPOST 'http://192.168.1.3:8086/write?db=dev' --data-binary "network_traffic,host=asus_rt_ac66u,interface=vlan2,direction=inbound value=$vlan2_in_bps"
        curl -i -XPOST 'http://192.168.1.3:8086/write?db=dev' --data-binary "network_traffic,host=asus_rt_ac66u,interface=vlan2,direction=outbound value=$vlan2_out_bps"
        curl -i -XPOST 'http://192.168.1.3:8086/write?db=dev' --data-binary "network_traffic,host=asus_rt_ac66u,interface=br0,direction=inbound value=$br0_in_bps"
        curl -i -XPOST 'http://192.168.1.3:8086/write?db=dev' --data-binary "network_traffic,host=asus_rt_ac66u,interface=br0,direction=outbound value=$br0_out_bps"
        curl -i -XPOST 'http://192.168.1.3:8086/write?db=dev' --data-binary "network_traffic,host=asus_rt_ac66u,interface=tun22,direction=inbound value=$tun22_in_bps"
        curl -i -XPOST 'http://192.168.1.3:8086/write?db=dev' --data-binary "network_traffic,host=asus_rt_ac66u,interface=tun22,direction=outbound value=$tun22_out_bps"

        #Move the current variables to the old ones
        old_lo_in=$lo_in
        old_lo_out=$lo_out
        old_eth0_in=$eth0_in
        old_eth0_out=$eth0_out
        old_eth1_in=$eth1_in
        old_eth1_out=$eth1_out
        old_eth2_in=$eth2_in
        old_eth2_out=$eth2_out
        old_vlan1_in=$vlan1_in
        old_vlan1_out=$vlan1_out
        old_vlan2_in=$vlan2_in
        old_vlan2_out=$vlan2_out
        old_br0_in=$br0_in
        old_br0_out=$br0_out
        old_tun22_in=$tun22_in
        old_tun22_out=$tun22_out
    fi
    
done