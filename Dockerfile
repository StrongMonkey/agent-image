
FROM microsoft/windowsservercore

RUN powershell.exe -Command \
    $ErrorActionPreference = 'Stop'; \
    Invoke-WebRequest -Uri 'https://get.docker.com/builds/Windows/x86_64/docker-1.12.0.zip' -OutFile "$env:TEMP\docker-1.12.0.zip" -UseBasicParsing; \
    Expand-Archive -Path "$env:TEMP\docker-1.12.0.zip" -DestinationPath $env:ProgramFiles; \
    [Environment]::SetEnvironmentVariable('Path', $env:Path + ';C:\Program Files\Docker', [EnvironmentVariableTarget]::Machine); \
    ;

RUN powershell.exe -Command \
    $ErrorActionPreference = 'Stop'; \
    wget https://www.python.org/ftp/python/2.7.12/python-2.7.12.msi -OutFile c:\python-2.7.12.msi ; \
    Start-Process c:\python-2.7.12.msi -ArgumentList '/quiet InstallAllUsers=1 PrependPath=1' -Wait ; \
    Remove-Item c:\python-2.7.12.msi -Force; \
    wget https://bootstrap.pypa.io/get-pip.py -OutFile c:\get-pip.py; \
    ;

RUN ["c:/Python27/python", "c:/get-pip.py"]

RUN ["c:/Python27/Scripts/pip", "install", "cattle"]

RUN powershell New-Item -ItemType directory -Path c:/Cattle
COPY resolve_url.py register.py run.ps1 c:/
ENTRYPOINT ["powershell", "c:/run.ps1"]
LABEL "io.rancher.container.system"="rancher-agent"