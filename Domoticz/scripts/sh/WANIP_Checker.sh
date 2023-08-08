 #!/bin/bash
 # WANIP_Checker_N-Station.sh
 # This script get the external IP address of this system (N-Station) and update the
 # associated virtual device (IDX iii) in Domoticz (192.168.x.yyy:8084)
 # Assuming that we are authorized to update in Domoticz via JSON API
 
 # Settings

 DOMO_IP="192.168.x.yyy"       	# Domoticz IP Address
 DOMO_PORT="8084"              	# Domoticz Port
 IP_IDX="iii"                  	# External IP address IDX
 IP_VALUE=""                   	# Currently known IP value in Domoticz
 EXT_IP="Inconnue?"            	# Actual external IP address
 PINGTIME=99					# 
  
 
 # Check if Domoticz node in online 
 
 PINGTIME=`ping -c 1 -q $DOMO_IP | awk -F"/" '{print $5}' | xargs`
 
 #echo $PINGTIME
 if expr "$PINGTIME" '>' 0
 then
   IP_VALUE=`curl -s "http://$DOMO_IP:$DOMO_PORT/json.htm?type=command&param=getdevices&rid=$IP_IDX" | grep '"Data" :' | awk -F '"' '{print $4}'`
 
    if [ $? -eq 0 ] 
	then
        echo "We got the currently known value from Domoticz $IP_VALUE"
	else
		echo "We couldn't get currently known value from Domoticz ?!"
	fi
 
    # Get external IP
    EXT_IP=`curl --connect-timeout 15 -m 20 -s http://myexternalip.com/raw`
	if [ $? -eq 0 ]
	then
				echo "We got the actual external IP address $EXT_IP"
	else
				echo "Couldn't get the actual external IP address ?!"
				EXT_IP="Inconnue?"
	fi
	if [ "$IP_VALUE" != "$EXT_IP" ]
	then
			# Send data
			echo "IP value changed from $IP_VALUE to $EXT_IP, updating Domoticz virtual device"
			curl -s -i -H "Accept: application/json" "http://$DOMO_IP:$DOMO_PORT/json.htm?type=command&param=udevice&idx=$IP_IDX&nvalue=0&svalue=$EXT_IP"
	else
			echo "Same external IP address as already known value $EXT_IP, nothing to update"
	fi
else
        echo "Domoticz isn't up on $DOMO_IP ?!"
        
 fi
