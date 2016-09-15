#!/usr/bin/env python
import sys
import os
import logging
import binascii
import urllib2

from cattle import from_env

url = sys.argv[1]
response = urllib2.urlopen(url)
for line in response.readlines():
            if "CATTLE_REGISTRATION_ACCESS_KEY" in line: 
                value = line.split('=')[1]
                print "[Environment]::SetEnvironmentVariable(\"CATTLE_REGISTRATION_ACCESS_KEY\", \"{}\", \"Machine\")".format(value[1:len(value)-2])
            elif "CATTLE_REGISTRATION_SECRET_KEY" in line:
                value = line.split('=')[1]
                print "[Environment]::SetEnvironmentVariable(\"CATTLE_REGISTRATION_SECRET_KEY\", \"{}\", \"Machine\")".format(value[1:len(value)-2])
            elif "CATTLE_URL" in line:
                value = line.split('=')[1]
                print "[Environment]::SetEnvironmentVariable(\"CATTLE_URL\", \"{}\", \"Machine\")".format(value[1:len(value)-2])
            elif "DETECTED_CATTLE_AGENT_IP" in line: 
                if "CATTLE_AGENT_IP" not in os.environ: 
                    value = line.split('=')[1] 
                    print "[Environment]::SetEnvironmentVariable(\"CATTLE_AGENT_IP\", \"{}\", \"Machine\")".format(value[1:len(value)-2])
