function wait_for([string]$arg1)
{
    $url = $(print_url $arg1)
	echo "Info: Attempting to connect to: $arg1"
	for ($i=0; $i -le 300; $i++){
		$ret = Invoke-WebRequest -Method Get -Uri $arg1 -UseBasicParsing
		if ($ret.StatusCode -eq 200){
			echo "Info: $url is accessible"
			break
		}
		Else{
			echo "Error: $url is not accessible"
			Start-Sleep -s 2
			if ($i -eq 299) {
				echo "Error: Could not reach $url. Giving up"
				exit
			}
		}
	}
}

function print_url([string]$arg1)
{
	$arg1 -match "http:\/\/(?:[0-9]{1,3}\.){3}[0-9]{1,3}:[0-9]+" | Out-Null
	return $Matches[0]
}

function read_env_from_image
{
	echo "Info: Reading environment from windows-agent"
	$inspect = docker -H "$env:DEFAULT_GATEWAY" inspect windows-agent | ConvertFrom-Json
	foreach ($env in $inspect.Config.Env) {
		$a, $b = $env.split("=", 2)
		if ($a -eq "CATTLE_URL"){
			$script:CATTLE_URL = $b
		}
		ElseIf($a -eq "CATTLE_AGENT_IP"){
			$script:CATTLE_AGENT_IP = $b
		}
		ElseIf($a -eq "CATTLE_ACCESS_KEY"){
			$script:CATTLE_ACCESS_KEY = $b
		}
		ElseIf($a -eq "CATTLE_SECRET_KEY"){
			$script:CATTLE_SECRET_KEY = $b
		}
	}
}

function setup_cattle_url([string]$arg1)
{
	if ($arg1 -eq "register") {
		if (!$RANCHER_URL) {
			echo "no RANCHER_URL environment variable, exiting"
			exit
		}
	$script:CATTLE_URL = $RANCHER_URL
	}
	ElseIf ($arg1 -eq "upgrade") {
		read_env_from_image
	}
	Else {
		$script:CATTLE_URL = $arg1
	}
}

function setup_env([string]$arg1)
{
	if ($arg1 -ne "upgrade") {
		foreach ($env in $(C:\register-tool.exe --load-url $CATTLE_URL)) {
		        Invoke-Expression $env
		}
		$script:CATTLE_REGISTRATION_ACCESS_KEY = [environment]::GetEnvironmentVariable("CATTLE_REGISTRATION_ACCESS_KEY", "Machine")
		$script:CATTLE_REGISTRATION_SECRET_KEY = [environment]::GetEnvironmentVariable("CATTLE_REGISTRATION_SECRET_KEY", "Machine")
	}	
	
	if (!$CATTLE_ACCESS_KEY -Or !$CATTLE_SECRET_KEY){
		echo "Info: Running registration"
		register
		$script:CATTLE_URL = [environment]::GetEnvironmentVariable("CATTLE_URL", "Machine")
		$script:CATTLE_AGENT_IP = [environment]::GetEnvironmentVariable("CATTLE_AGENT_IP", "Machine")
		$script:CATTLE_ACCESS_KEY = [environment]::GetEnvironmentVariable("CATTLE_ACCESS_KEY", "Machine")
		$script:CATTLE_SECRET_KEY = [environment]::GetEnvironmentVariable("CATTLE_SECRET_KEY", "Machine")
	}
	Else{
		echo "Info: Skipping registration"
	}
	echo "Printing Environment variable"
	echo "Env: CATTLE_URL $CATTLE_URL"
	echo "Env: CATTLE_AGENT_IP $CATTLE_AGENT_IP"
 	echo "Env: CATTLE_ACCESS_KEY $CATTLE_ACCESS_KEY"
    echo "Env: CATTLE_SECRET_KEY *******************" 
}

function register()
{
	$url = print_url $CATTLE_URL
	echo $url
	foreach ($env in $(C:\register-tool.exe --windows $url","$CATTLE_REGISTRATION_ACCESS_KEY","$CATTLE_REGISTRATION_SECRET_KEY)) { 
		Invoke-Expression $env 
	}
}

function cleanup_windows_agent
{
	docker -H "$env:DEFAULT_GATEWAY" inspect windows-agent 2>&1 | Out-Null
	if ($LASTEXITCODE -ne 0) {
		return
	}
	for($i=0;$i -le 300;$i++){
		try {
			docker -H "$env:DEFAULT_GATEWAY" rm -f windows-agent 2>&1 | Out-Null
			if ($LASTEXITCODE -eq 0) {
				break
			}
		}
		catch{
			echo "Info: can't remove windows-agent. try again 2s later"
			Start-Sleep 2
		}
	}
}

function get_internal_gateway
{
	$obj = ipconfig | Select-String "Default Gateway"
	$ip = [regex]::match($obj, '(?:[0-9]{1,3}\.){3}[0-9]{1,3}').Value
	$env:DEFAULT_GATEWAY = $ip
	echo "Default gateway $env:DEFAULT_GATEWAY"
}
function launch_agent
{
	docker -H "$env:DEFAULT_GATEWAY" run `
	-d `
	-v c:/Cattle:c:/Cattle `
	--name rancher-agent `
	--restart=always `
	--privileged `
	-e "CATTLE_URL=$CATTLE_URL" `
	-e "CATTLE_AGENT_IP=$CATTLE_AGENT_IP" `
	-e "CATTLE_ACCESS_KEY=$CATTLE_ACCESS_KEY" `
	-e "CATTLE_SECRET_KEY=$CATTLE_SECRET_KEY" `
	-e "DEFAULT_GATEWAY=$env:DEFAULT_GATEWAY" `
	rancher/agent run`
}

if ($Args -eq 0){
	 echo "One parameter required" 
	 exit
}

if ($Args[0] -eq "run")
{
	echo "Cattle_Url: $env:CATTLE_URL"
	$url = $env:CATTLE_URL + "/scripts/api.crt"
	if ( !(Test-Path "C:\Cattle\etc\cattle")) {
		New-Item C:\Cattle\etc\cattle -type directory
	}
	Invoke-WebRequest -Uri $url -OutFile "C:\Cattle\etc\cattle\api.crt"
	if ( !(Test-Path "C:\Cattle\containers")) {
		New-Item C:\Cattle\containers -type directory
	}
	& "C:\agent.exe"
}
Elseif ($Args[0] -match "http.*" -Or $Args[0] -eq "register" -Or $Args[0] -eq "upgrade") 
{
	echo $http_proxy $https_proxy
	get_internal_gateway
	setup_cattle_url $Args[0]
	if ($Args[0] -eq "upgrade") {
		echo "Info: Running upgrade"
	}
	Else {
		echo "Info Running Agent Registration Process, CATTLE_URL = $(print_url $CATTLE_URL)"
	}
	if ($Args[0] -ne "upgrade") {
		wait_for $Args[0]
	}
	setup_env $Args[0]
	cleanup_windows_agent 
	$ID=$(launch_agent) 
	echo "Info: Launched Rancher Agent $ID"
	echo "Deleting Bootstrap Agent"
}
