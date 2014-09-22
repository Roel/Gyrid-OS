#!/usr/bin/python
#-*- coding: utf-8 -*-

import bz2
import glob
import re
import sys

def unzip(regex, filename, output):
    try:
        if 'bz2' in filename:
            fle = bz2.BZ2File(filename, 'r')
        else:
            fle = open(filename, 'r')
    except:
        return 0

    try:
        for line in fle:
            if regex.match(line):
                output.write(line)
    finally:
        fle.close()

if len(sys.argv) <= 1:
    sys.exit(1)

output = sys.argv[1].rstrip('/')

logs = [{'files' : 'scan*',
         'regex' : r'^[0-9]{8}-[0-9]{6}\.[0-9]{3}-[A-Za-z]*,[0-9A-Fa-f]+,[0-9]*,(in|out|pass)$',
         'header' : 'timestamp,deviceid,deviceclass,movement',
         'outputfile' : 'bt-scan.log'},
        {'files' : 'rssi*',
         'regex' : r'^[0-9]{8}-[0-9]{6}\.[0-9]{3}-[A-Za-z]*,[0-9A-Fa-f]+,[0-9]*,-?[0-9]*,-[0-9]+$',
         'header' : 'timestamp,deviceid,deviceclass,txpower,rssi',
         'outputfile' : 'bt-rssi.log'},
        {'files' : 'inquiry*',
         'regex' : r'^[0-9]{8}-[0-9]{6}\.[0-9]{3}-[A-Za-z]*,[0-9]+\.?[0-9]*,[0-9]+$',
         'header' : 'timestamp_end,length_s,responsecount',
         'outputfile' : 'bt-inquiry.log'},
        {'files' : 'wifi-ACP*',
         'regex' : r'^[0-9]{8}-[0-9]{6}\.[0-9]{3}-[A-Za-z]*,[0-9A-Fa-f]+,(in|out)$',
         'header' : 'timestamp,deviceid,movement',
         'outputfile' : 'wifi-acp.log'},
        {'files' : 'wifi-DEV*',
         'regex' : r'^[0-9]{8}-[0-9]{6}\.[0-9]{3}-[A-Za-z]*,[0-9A-Fa-f]+,(in|out)$',
         'header' : 'timestamp,deviceid,movement',
         'outputfile' : 'wifi-dev.log'},
        {'files' : 'wifi-RAW*',
         'regex' : r'^[0-9]{8}-[0-9]{6}\.[0-9]{3}-[A-Za-z]*,[0-9]{4},(MGMT|CTRL|DATA),.*$',
         'header' : 'timestamp,frequency_hz,frametype,framesubtype,destination,origin,rssi,retry,info|',
         'outputfile' : 'wifi-raw.log'},
        {'files' : 'wifi-DRW*',
         'regex' : r'^[0-9]{8}-[0-9]{6}\.[0-9]{3}-[A-Za-z]*,[0-9]{4},[0-9A-Fa-f]+,-[0-9]+$',
         'header' : 'timestamp,frequency_hz,deviceid,rssi',
         'outputfile' : 'wifi-drw.log'},
        {'files' : 'wifi-frequency*',
         'regex' : r'^[0-9]{8}-[0-9]{6}\.[0-9]{3}-[A-Za-z]*,[0-9]+\.?[0-9]*,[0-9]+[0-9,]*$',
         'header' : 'timestamp_end,timeperfreq_s,frequency|',
         'outputfile' : 'wifi-freq.log'}]

for l in logs:
    files = glob.glob(l['files'])
    if len(files) > 0:
        outputfile = open(output + '/' + l['outputfile'], 'a')
        r = re.compile(l['regex'])

        for f in files:
            unzip(r, f, outputfile)

        outputfile.close()
