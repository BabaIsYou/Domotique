#!/bin/bash

# Script to be used as Action On or Action Off on a dummy switch to activate display on 
# thermostats dispaly that support /config attribute "ledindication" via Deconz REST-API
# Could be adapted for any attribute that is writable in DeCONZ REST-API

# PARAMS
# 1 : enable | disable | check
# 2 : DeCONZ ID of Thermostat (not Domoticz IDx)
# 3 : IDx of corresponding Domoticz dummy switch (used only with $1 = check)

# No params given = stop script
[[ -z "$1" ]] && { echo "Parameter 1 is empty" ; exit 1; }
[[ -z "$2" ]] && { echo "Parameter 2 is empty" ; exit 1; }
[[ -z "$3" ]] && { echo "Parameter 3 is empty" ; exit 1; }

# User defined vars
DeconzAPIkey="XXXXXXXXXX"       # API key used to access DeCONZ REST-API
DeconzIP="127.0.0.1"            # IP address of the DeCONZ REST-API server. Usually the same with port 80
domoticz_url="127.0.0.1:8084"   # eg 127.0.0.1:8080

url="http://${DeconzIP}/api/${DeconzAPIkey}/sensors/${2}/config"

		# Do actions
		# Enable action
		if [[ $1 == 'enable' ]]; then
			# Enable trough DeConz API
				curlResult=$(curl -H 'Content-Type: application/json' -X PUT -d '{"ledindication": true}' "${url}")
                if [[ $(echo "$curlResult" | grep "error") ]]; then 
									echo "Error on enabling display on thermostat ${2}"
									exit 0
		        fi

		# Disable action
		elif [[ $1 == 'disable' ]]; then
				# Enable trough DeConz API
				curlResult=$(curl -H 'Content-Type: application/json' -X PUT -d '{"ledindication": false}' "${url}")
				if [[ $(echo "$curlResult" | grep "error") ]]; then 
						echo "Error on disabling display on thermostat ${2}"
						exit 0
				fi
   # Check action (can be used to sync virtual device with actual DeConz state)
		elif [[ $1 == 'check' ]]; then
				# Get status of the Thermostat display
				url="http://${DeconzIP}/api/${DeconzAPIkey}/sensors${THidx}/${2}"
				curlResult=$(curl -s "${url}")
#				echo "$curlResult"
#				echo $curlResult | jq -r '.config.ledindication'
				# Get status of the dummy switch
				curlResultDomo=$(curl -s "http://${domoticz_url}/json.htm?type=devices&rid=${3}")
#				echo $curlResultDomo | jq -r '.result[].Status'
				# Thermostat display is false and dummy is On
				if [ $(echo "$curlResult" | jq -r '.config.ledindication') == 'false' ] && [ $(echo "$curlResultDomo" | jq -r '.result[].Status') == 'On' ]; then 
					curl -s "http://${domoticz_url}/json.htm?type=command&param=udevice&idx=${3}&nvalue=0&svalue=" > /dev/null 2>&1
					# Thermostat display is true and dummy is Off
				elif [ $(echo "$curlResult" | jq -r '.config.ledindication') == 'true' ] && [ $(echo "$curlResultDomo" | jq -r '.result[].Status') == 'Off' ]; then 
					curl -s "http://${domoticz_url}/json.htm?type=command&param=udevice&idx=${3}&nvalue=1&svalue=" > /dev/null 2>&1
				fi
		fi

