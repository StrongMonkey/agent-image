#!/usr/bin/env python
import sys
import os
import logging
import binascii
import urllib2

from cattle import from_env

os.environ["CATTLE_URL"] = sys.argv[3]
try:
    client = from_env(access_key=sys.argv[1],
                    secret_key=sys.argv[2])
except KeyError:
    logging.exception('Missing CATTLE_REGISTRATION_ACCESS_KEY or CATTLE_REGISTRATION_SECRET_KEY')
    sys.exit(1)


if not client.valid():
    print "echo Invalid API credentials; exit 1"
    sys.exit(1)


if not os.path.exists("c:\Cattle\.registration_token"):
    f = open("c:\Cattle\.registration_token", 'a')
    f.write(binascii.b2a_hex(os.urandom(15)))

with open("c:\Cattle\.registration_token", 'r') as token_file:
    key = token_file.read()

if "CATTLE_ACCESS_KEY" not in os.environ or "CATTLE_SECRET_KEY" not in os.environ:
    rs = client.list_register(key=key)

    if len(rs) > 0:
        r = rs[0]
        r = client.wait_success(r)
        r = client.list_register(key=key)[0]
    else:
        r = client.create_register(key=key)
        r = client.wait_success(r)
        r = client.list_register(key=key)[0]
    print "[Environment]::SetEnvironmentVariable(\"CATTLE_ACCESS_KEY\", \"{}\", \"Machine\")".format(r.accessKey)
    print "[Environment]::SetEnvironmentVariable(\"CATTLE_SECRET_KEY\", \"{}\", \"Machine\")".format(r.secretKey)
