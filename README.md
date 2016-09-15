# agent-image
Docker file and scripts to run agent on windows server

# Description
The agent image is launched as a bootstrap image in windows server. It will inject access key and secret key to the real windows-agent.

# Usage

To register a windows host in cattle run:
$ docker run --rm rancher-agent [registration_url] 

To upgrade to the newest windows-agent run:
$ docker run --rm rancher-agent upgrade

Windows-agent is the real image that have all binaries in it. Everytime we do an update we just need to update the windows-agent image and rerun upgrade command above.
