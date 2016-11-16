
FROM microsoft/windowsservercore

RUN powershell.exe -Command \
    $ErrorActionPreference = 'Stop'; \
    Invoke-WebRequest -Uri 'https://get.docker.com/builds/Windows/x86_64/docker-1.12.0.zip' -OutFile "$env:TEMP\docker-1.12.0.zip" -UseBasicParsing; \
    Expand-Archive -Path "$env:TEMP\docker-1.12.0.zip" -DestinationPath $env:ProgramFiles; \
    [Environment]::SetEnvironmentVariable('Path', $env:Path + ';C:\Program Files\Docker', [EnvironmentVariableTarget]::Machine); \
    ;

RUN powershell.exe -Command \
    $ErrorActionPreference = 'Stop'; \
    Invoke-WebRequest -Uri 'https://github.com/StrongMonkey/agent/releases/download/v1.0.1/agent.exe' -OutFile "c:/agent.exe" -UseBasicParsing;

RUN powershell.exe -Command \
    $ErrorActionPreference = 'Stop'; \
    Invoke-WebRequest -Uri 'https://github.com/StrongMonkey/register-tool/releases/download/v1.0/register-tool.exe' -OutFile "c:/register-tool.exe" -UseBasicParsing;

RUN powershell New-Item -ItemType directory -Path c:/Cattle
COPY run.ps1 c:/
ENTRYPOINT ["powershell", "c:/run.ps1"]
LABEL "io.rancher.container.system"="rancher-agent"
