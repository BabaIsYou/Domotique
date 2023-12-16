 #!/bin/bash
 # PIA_OpenVPN-N-Station.sh
 # This script test if a VPN is up by testing presence of tun0: device and update the
 # associated virtual device (IDX 47) in Domoticz (192.168.x.yyy:8084)
 # Assuming that we are authorized to update in Domoticz via JSON API
 
 # Settings

 DOMO_IP="192.168.x.yyy"       	# Domoticz IP Address
 DOMO_PORT="8084"              	# Domoticz Port
 VPN_IDX="47"                  	# PIA_OpenVPN IDX
 PINGTIME=99					# 
  
 
 # Check if Domoticz node in online 
 
 PINGTIME=`ping -c 1 -q $DOMO_IP | awk -F"/" '{print $5}' | xargs`
 
 #echo $PINGTIME
 if expr "$PINGTIME" '>' 0
 then
   ifconfig tun0 > /dev/null
	if [ $? -eq 0 ]
	then
        VPN_STATUS="On"
        echo "VPN seems to be UP"
	else
		VPN_STATUS="Off"
		echo "VPN seems to be DOWN"
	fi
   
   DOMOTICZ_STATUS=`curl -s "http://$DOMO_IP:$DOMO_PORT/json.htm?type=command&param=getdevices&rid=$VPN_IDX" | grep "Status" | awk -F '"' '{print $4}'`
 
    if [ $DOMOTICZ_STATUS == "On" ] && [ $VPN_STATUS == "On" ]
	then
        echo "VPN status already On in Domoticz"
	elif [ $DOMOTICZ_STATUS == "Off" ] && [ $VPN_STATUS == "Off" ]
	then
		echo "VPN status already Down in Domoticz"
	else
		echo "Updating PIA_OpenVPN virtual switch in Domoticz"
		curl -s -i -H "Accept: application/json" "http://$DOMO_IP:$DOMO_PORT/json.htm?type=command&param=switchlight&idx=$VPN_IDX&switchcmd=$VPN_STATUS"
	fi
	else
        echo "Domoticz isn't up on $DOMO_IP ?!"
        
 fi
