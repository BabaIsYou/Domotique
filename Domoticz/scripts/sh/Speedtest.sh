 #!/bin/bash
 # Speedtest.sh
 # This script  use speedtest.py to get Download, Upload speeds, ping value, Provider an external IP address
 # Updating the corresponding devices in Domoticz
 # Settings
 
 DOMO_IP="192.168.x.yyy"       	# Domoticz IP Address
 DOMO_PORT="8084"              	# Domoticz Port
 DOWN_IDX="376"					# Download speed value IDX
 UP_IDX="377"						# Upload speed value IDX
 PING_IDX="375"					# Ping value IDX
 TEMP_FILE="./speedtest.txt"    # Temp file used to store speedtest values
 TMP_VAR=""         			# Temp variable
 
 # Check if Domoticz node in online 
 
 PINGTIME=`ping -c 1 -q $DOMO_IP | awk -F"/" '{print $5}' | xargs`
 
 #echo $PINGTIME
 if expr "$PINGTIME" '>' 0
 then
	TEMP_FILE=`/volume1/Documents/Download/Domotique/Domoticz/Scripts-prod/speedtest.py --simple > /volume1/Documents/Download/Domotique/Domoticz/Scripts-prod/speedtest.txt`

      if [ $? -eq 0 ] 
	then
        echo "We got the speedtest.py results"
		TMP_VAR=`cat /volume1/Documents/Download/Domotique/Domoticz/Scripts-prod/speedtest.txt | grep "Download" | awk -F" " '{print $2}' | xargs`
			echo "updating Domoticz virtual device for Download speed : $TMP_VAR"
			curl -s -i -H "Accept: application/json" "http://$DOMO_IP:$DOMO_PORT/json.htm?type=command&param=udevice&idx=$DOWN_IDX&nvalue=0&svalue=$TMP_VAR"
			
		TMP_VAR=`cat /volume1/Documents/Download/Domotique/Domoticz/Scripts-prod/speedtest.txt | grep "Upload" | awk -F" " '{print $2}' | xargs`
			echo "updating Domoticz virtual device for Upload speed : $TMP_VAR"
			curl -s -i -H "Accept: application/json" "http://$DOMO_IP:$DOMO_PORT/json.htm?type=command&param=udevice&idx=$UP_IDX&nvalue=0&svalue=$TMP_VAR"
			
		TMP_VAR=`cat /volume1/Documents/Download/Domotique/Domoticz/Scripts-prod/speedtest.txt | grep "Ping" | awk -F" " '{print $2}' | xargs`
			echo "updating Domoticz virtual device for ping value : $TMP_VAR"
			curl -s -i -H "Accept: application/json" "http://$DOMO_IP:$DOMO_PORT/json.htm?type=command&param=udevice&idx=$PING_IDX&nvalue=0&svalue=$TMP_VAR"
		
		rm /volume1/Documents/Download/Domotique/Domoticz/Scripts-prod/speedtest.txt
	else
		echo "We couldn't get speedtest.py results ?!"
	fi
else
        echo "Domoticz isn't up on $DOMO_IP ?!"
fi
