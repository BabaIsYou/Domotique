-- Alexandre DUBOIS – 2014
-- Adaptation Hugues Mercusot - 2017
-- Ce script vérifie la présence du périphérique réseau tun0 pour voir si un VPN OpenVPN est actif.
-- La vérification est effectuée une fois par minute tant qu'aucun tun0 n'est trouvé,
-- puis une fois toute les 5 minutes quand le périphérique est trouvé afin de ne pas trop stresser la machine.
-- Device Dummy PIA_OpenVPN cré dans Domoticz et configuration OpenVPN aussi


commandArray = {}

--Cette fonction calcule la différence de temps (en secondes) entre maintenant
--et la date passée en paramètre.
function timedifference (s)
  year = string.sub(s, 1, 4)
  month = string.sub(s, 6, 7)
  day = string.sub(s, 9, 10)
  hour = string.sub(s, 12, 13)
  minutes = string.sub(s, 15, 16)
  seconds = string.sub(s, 18, 19)
  t1 = os.time()
  t2 = os.time{year=year, month=month, day=day, hour=hour, min=minutes, sec=seconds}
  difference = os.difftime (t1, t2)
  return difference
end

--Si le tun0 n'est pas détecté ou qu'il est présent depuis plus de 5 minutes (300 secondes),
--alors on vérifie à nouveau sa présence
if (otherdevices['PIA_OpenVPN']=='Off' or (otherdevices['PIA_OpenVPN']=='On' and timedifference(otherdevices_lastupdate['PIA_OpenVPN']) > 300)) then
	ping_success_tel1=os.execute('ifconfig tun0')
	
	if ping_success_tel1 then
		if ( otherdevices['PIA_OpenVPN'] == 'Off') then -- Passage du switch ON que s'il était OFF avant
	  	commandArray['PIA_OpenVPN']='On'
		end
	else
	  if otherdevices['PIA_OpenVPN']=='On' then --On ne passe l'interrupteur virtuel à Off que s'il est sur On.
             commandArray['PIA_OpenVPN']='Off'
          end
	end
end

return commandArray
