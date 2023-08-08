VARNAME = 'WanIP_IP'
GETIP = 'curl -s https://4.ifcfg.me/'
TMPFILE = '/volume1/@appstore/domoticz/var/scripts/wanip.txt'
PTPPREFIX = '>>> [WanIP checker] >>> '
IDLESECS = 1800  -- 30 mn

function timeDiff(dName)
    t1 = os.time()
    updTime = uservariables_lastupdate[dName]
    year = string.sub(updTime, 1, 4)
    month = string.sub(updTime, 6, 7)
    day = string.sub(updTime, 9, 10)
    hour = string.sub(updTime, 12, 13)
    minutes = string.sub(updTime, 15, 16)
    seconds = string.sub(updTime, 18, 19)
   
    t2 = os.time{year=year, month=month, day=day, hour=hour, min=minutes, sec=seconds}
   
    tDiff = os.difftime(t1,t2)
    return tDiff
end

CURRWNIP = uservariables[VARNAME]
IDLETIME = tonumber(timeDiff(VARNAME))

commandArray = {}
    if IDLETIME > IDLESECS then
        os.execute(GETIP..' > '..TMPFILE)
        wanip = io.open(TMPFILE):read()
       
        if not wanip then
            print (PTPPREFIX..'Impossible de récupérer WAN IP')
        else
            if wanip ~= CURRWNIP then
                print (PTPPREFIX..'Actualisation de WAN IP: '..wanip)
                commandArray['Variable:'..VARNAME] = wanip
                os.execute('rm /volume1/@appstore/domoticz/var/scripts/wanip.txt')
            end
        end
    end
return commandArray
