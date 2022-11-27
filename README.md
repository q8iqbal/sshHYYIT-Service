# SSH Telemetry Agent
## Dependency  
- make
- systemd
- w
- openssh-server 
- curl

## Provided file
/etc/systemd/system/ssh-telemetry-agent.target.wants/user-telemetry.service
/etc/systemd/system/ssh-telemetry-agent.target.wants/log-telemetry.service
/etc/ssh-telemetry-agent/default.cfg
/opt/ssh-telemetry-agent/

## 1. How to install
`# make install`

## 2. How to uninstall
`# make uninstall`