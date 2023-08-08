 #!/bin/bash
 
 # Settings
 # NAS_N-Station.sh executé par tâche planifiée toutes les 5 min.
 # Executé sous root avec comme ligne de commande :
 # sh /volume1/Documents/Download/Domotique/Domoticz/Scripts-prod/NAS_N-Station.sh >  /volume1/Documents/Download/Domotique/Domoticz/Scripts-prod/NAS_N-Station.log 2>&1
 
 NASIP="127.0.0.1"         # NAS IP Address
 PASSWORD="public"           # SNMP Password
 DOMO_IP="192.168.x.yyy"       # Domoticz IP Address
 DOMO_PORT="8084"            # Domoticz Port
 NAS_IDX="79"                 # NAS Switch IDX
 NAS_HD1_TEMP_IDX="84"        # NAS HD1 Temp IDX
 NAS_HD2_TEMP_IDX="85"        # NAS HD2 Temp IDX
 NAS_HD_SPACE_IDX="86"        # NAS HD Space IDX in Go
 NAS_HD_SPACE_PERC_IDX="81"   # NAS HD Space IDX in %
 NAS_CPU_IDX="83"             # NAS CPU IDX
 NAS_MEM_IDX="82"             # NAS MEM IDX
 
 
 # Check if NAS in online 
 
 PINGTIME=`ping -c 1 -q $NASIP | awk -F"/" '{print $5}' | xargs`
 
 echo $PINGTIME
 if expr "$PINGTIME" '>' 0
 then
   curl -s "http://$DOMO_IP:$DOMO_PORT/json.htm?type=command&param=getdevices&rid=$NAS_IDX" | grep "Status" | grep "On" > /dev/null
 
       if [ $? -eq 0 ] ; then
        echo "NAS already ON"
 
        # Temperature HD1
        HDtemp1=`snmpwalk -v 2c -c $PASSWORD -O qv $NASIP 1.3.6.1.4.1.6574.2.1.1.6.0`
        # Send data
        echo "MAJ Temp HD1"
        curl -s -i -H "Accept: application/json" "http://$DOMO_IP:$DOMO_PORT/json.htm?type=command&param=udevice&idx=$NAS_HD1_TEMP_IDX&nvalue=0&svalue=$HDtemp1"
 
        # Temperature HD2
        HDtemp2=`snmpwalk -v 2c -c $PASSWORD -O qv $NASIP 1.3.6.1.4.1.6574.2.1.1.6.1`
        # Send data
        echo "MAJ Temp HD2"
        curl -s -i -H "Accept: application/json" "http://$DOMO_IP:$DOMO_PORT/json.htm?type=command&param=udevice&idx=$NAS_HD2_TEMP_IDX&nvalue=0&svalue=$HDtemp2"
 
        # Free space volume in Go !! # Last OID digits based on snmpwalk -v 2c -c"password" "NAS IP" 1.3.6.1.2.1.25.2.3.1 
        tmpHDUnit=`snmpwalk -v 2c -c $PASSWORD -O qv $NASIP 1.3.6.1.2.1.25.2.3.1.4.41`  # Change OID to .38 on DSM 5.1 or .41 on DSM 6.0+
        HDUnit=${tmpHDUnit%% *}  
        HDTotal=`snmpwalk -v 2c -c $PASSWORD -O qv $NASIP 1.3.6.1.2.1.25.2.3.1.5.41` # Change OID to .38 on DSM 5.1 or .41 on DSM 6.0+
        HDUsed=`snmpwalk -v 2c -c $PASSWORD -O qv $NASIP 1.3.6.1.2.1.25.2.3.1.6.41`  # Change OID to .38 on DSM 5.1 or .41 on DSM 6.0+
        HDFree=$((($HDTotal - $HDUsed) * $HDUnit / 1024 / 1024 / 1024))
 
        # Send data
        echo "MAJ dispo Go"
        curl -s -i -H "Accept: application/json" "http://$DOMO_IP:$DOMO_PORT/json.htm?type=command&param=udevice&idx=$NAS_HD_SPACE_IDX&nvalue=0&svalue=$HDFree"
 
        # Free space volume in percent
        HDTotal=`snmpwalk -c $PASSWORD -v2c -O qv $NASIP .1.3.6.1.2.1.25.2.3.1.5.41` # Change OID to .38 on DSM 5.1 or .41 on DSM 6.0+
        HDUsed=`snmpwalk -c $PASSWORD -v2c -O qv $NASIP .1.3.6.1.2.1.25.2.3.1.6.41`  # Change OID to .38 on DSM 5.1 or .41 on DSM 6.0+
     	HDFreePerc=$(((($HDTotal - $HDUsed) * 100) / $HDTotal))
        # Send data
                echo "MAJ dispo pourcent"
        curl -s -i -H "Accept: application/json" "http://$DOMO_IP:$DOMO_PORT/json.htm?type=command&param=udevice&idx=$NAS_HD_SPACE_PERC_IDX&nvalue=0&svalue=$HDFreePerc"
 
	# CPU utilisation
        CpuUser=`snmpwalk -v 2c -c $PASSWORD -O qv $NASIP 1.3.6.1.4.1.2021.11.9.0`
	CpuSystem=`snmpwalk -v 2c -c $PASSWORD -O qv $NASIP 1.3.6.1.4.1.2021.11.10.0`
	CpuUse=$(($CpuUser + $CpuSystem))
        # Send data
                echo "MAJ util CPU"
        curl -s -i -H "Accept: application/json" "http://$DOMO_IP:$DOMO_PORT/json.htm?type=command&param=udevice&idx=$NAS_CPU_IDX&nvalue=0&svalue=$CpuUse"
 
	# Memory Used in %
	tmpMemAvailable=`snmpwalk -v 2c -c $PASSWORD -O qv $NASIP 1.3.6.1.4.1.2021.4.6.0`
	MemAvailable=${tmpMemAvailable%% *}
	tmpMemtotal=`snmpwalk -v 2c -c $PASSWORD -O qv $NASIP 1.3.6.1.4.1.2021.4.5.0`
	Memtotal=${tmpMemtotal%% *}
	tmpMemShared=`snmpwalk -v 2c -c $PASSWORD -O qv $NASIP 1.3.6.1.4.1.2021.4.13.0`
	MemShared=${tmpMemShared%% *}
	tmpMemBuffer=`snmpwalk -v 2c -c $PASSWORD -O qv $NASIP 1.3.6.1.4.1.2021.4.14.0`
	MemBuffer=${tmpMemBuffer%% *}
	tmpMemCached=`snmpwalk -v 2c -c $PASSWORD -O qv $NASIP 1.3.6.1.4.1.2021.4.15.0`
	MemCached=${tmpMemCached%% *}
	MemFREE=$(($MemAvailable + $MemShared + $MemBuffer + $MemCached))
	MemUsepercent=$(((($Memtotal - $MemFREE) * 100) / $Memtotal))
	#// For Available use MemUsepercent=$(((($MemFREE) * 100) / $Memtotal))      
	# Send data
	        echo "MAJ mem dispo"
  	curl -s -i -H "Accept: application/json" "http://$DOMO_IP:$DOMO_PORT/json.htm?type=command&param=udevice&idx=$NAS_MEM_IDX&nvalue=0&svalue=$MemUsepercent" 
else
        echo "NAS ON"
        # Send data
        curl -s -i -H "Accept: application/json" "http://$DOMO_IP:$DOMO_PORT/json.htm?type=command&param=switchlight&idx=$NAS_IDX&switchcmd=On"
 
        # Temperature HD1
        HDtemp1=`snmpwalk -v 2c -c $PASSWORD -O qv $NASIP 1.3.6.1.4.1.6574.2.1.1.6.0`
        # Send data
        curl -s -i -H "Accept: application/json" "http://$DOMO_IP:$DOMO_PORT/json.htm?type=command&param=udevice&idx=$NAS_HD1_TEMP_IDX&nvalue=0&svalue=$HDtemp1"
 
        # Temperature HD2
        HDtemp2=`snmpwalk -v 2c -c $PASSWORD -O qv $NASIP 1.3.6.1.4.1.6574.2.1.1.6.1`
        # Send data
        curl -s -i -H "Accept: application/json" "http://$DOMO_IP:$DOMO_PORT/json.htm?type=command&param=udevice&idx=$NAS_HD2_TEMP_IDX&nvalue=0&svalue=$HDtemp2"
 
        # Free space volume in Go !! # Last OID digit based on snmpwalk -v 2c -c"password" "NAS IP" 1.3.6.1.2.1.25.2.3.1 
        tmpHDUnit=`snmpwalk -v 2c -c $PASSWORD -O qv $NASIP 1.3.6.1.2.1.25.2.3.1.4.41`  # Change OID to .38 on DSM 5.1 or .41 on DSM 6.0+
        HDUnit=${tmpHDUnit%% *}
        HDTotal=`snmpwalk -v 2c -c $PASSWORD -O qv $NASIP 1.3.6.1.2.1.25.2.3.1.5.41` # Change OID to .38 on DSM 5.1 or .41 on DSM 6.0+
        HDUsed=`snmpwalk -v 2c -c $PASSWORD -O qv $NASIP 1.3.6.1.2.1.25.2.3.1.6.41`  # Change OID to .38 on DSM 5.1 or .41 on DSM 6.0+
        HDFree=$((($HDTotal - $HDUsed) * $HDUnit / 1024 / 1024 / 1024))
 
        # Send data
        curl -s -i -H "Accept: application/json" "http://$DOMO_IP:$DOMO_PORT/json.htm?type=command&param=udevice&idx=$NAS_HD_SPACE_IDX&nvalue=0&svalue=$HDFree"
 
        # Free space volume in percent
        HDTotal=`snmpwalk -c $PASSWORD -v2c -O qv $NASIP .1.3.6.1.2.1.25.2.3.1.5.41` # Change OID to .38 on DSM 5.1 or .41 on DSM 6.0+
        HDUsed=`snmpwalk -c $PASSWORD -v2c -O qv $NASIP .1.3.6.1.2.1.25.2.3.1.6.41`  # Change OID to .38 on DSM 5.1 or .41 on DSM 6.0+
     	HDFreePerc=$(((($HDTotal - $HDUsed) * 100) / $HDTotal))
        # Send data
        curl -s -i -H "Accept: application/json" "http://$DOMO_IP:$DOMO_PORT/json.htm?type=command&param=udevice&idx=$NAS_HD_SPACE_PERC_IDX&nvalue=0&svalue=$HDFreePerc"
 
	# CPU utilisation
        CpuUser=`snmpwalk -v 2c -c $PASSWORD -O qv $NASIP 1.3.6.1.4.1.2021.11.9.0`
	CpuSystem=`snmpwalk -v 2c -c $PASSWORD -O qv $NASIP 1.3.6.1.4.1.2021.11.10.0`
	CpuUse=$(($CpuUser + $CpuSystem))
        # Send data
        curl -s -i -H "Accept: application/json" "http://$DOMO_IP:$DOMO_PORT/json.htm?type=command&param=udevice&idx=$NAS_CPU_IDX&nvalue=0&svalue=$CpuUse"
 
        # Memory Used in %                                                                    
        tmpMemAvailable=`snmpwalk -v 2c -c $PASSWORD -O qv $NASIP 1.3.6.1.4.1.2021.4.6.0`     
        MemAvailable=${tmpMemAvailable%% *}                                                   
        tmpMemtotal=`snmpwalk -v 2c -c $PASSWORD -O qv $NASIP 1.3.6.1.4.1.2021.4.5.0`         
        Memtotal=${tmpMemtotal%% *}                                                           
        tmpMemShared=`snmpwalk -v 2c -c $PASSWORD -O qv $NASIP 1.3.6.1.4.1.2021.4.13.0`       
        MemShared=${tmpMemShared%% *}                                                         
        tmpMemBuffer=`snmpwalk -v 2c -c $PASSWORD -O qv $NASIP 1.3.6.1.4.1.2021.4.14.0`       
        MemBuffer=${tmpMemBuffer%% *}                                                         
        tmpMemCached=`snmpwalk -v 2c -c $PASSWORD -O qv $NASIP 1.3.6.1.4.1.2021.4.15.0`       
        MemCached=${tmpMemCached%% *}                                                         
	MemFREE=$(($MemAvailable + $MemShared + $MemBuffer + $MemCached))
	MemUsepercent=$(((($Memtotal - $MemFREE) * 100) / $Memtotal))
	#// For Available use MemUsepercent=$(((($MemFREE) * 100) / $Memtotal))      
	# Send data
	curl -s -i -H "Accept: application/json" "http://$DOMO_IP:$DOMO_PORT/json.htm?type=command&param=udevice&idx=$NAS_MEM_IDX&nvalue=0&svalue=$MemUsepercent" 
      fi
 
 else
        curl -s "http://$DOMO_IP:$DOMO_PORT/json.htm?type=command&param=getdevices&rid=$NAS_IDX" | grep "Status" | grep "Off" > /dev/null
        if [ $? -eq 0 ] ; then
                echo "NAS already OFF"
                exit
        else
                echo "NAS OFF"
                # Send data
                curl -s -i -H "Accept: application/json" "http://$DOMO_IP:$DOMO_PORT/json.htm?type=command&param=switchlight&idx=$NAS_IDX&switchcmd=Off"
        fi
#fi
 fi
