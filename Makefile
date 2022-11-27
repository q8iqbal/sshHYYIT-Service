SHELL := /bin/bash
.PHONY = install uninstall check_root change_permission

config_path := /etc/ssh-telemetry-agent/
script_path := /opt/ssh-telemetry-agent/
units_path := /etc/systemd/system/ssh-telemetry-agent.target.wants/
services := log-telemetry.service user-telemetry.timer
scripts := src/ssh-log-parser.sh src/w-parser.sh

default: install

install: check_root change_permission
	@echo "Copy bash scripts to $(script_path)";
	@mkdir -p $(script_path)
	@cp -r src $(script_path)

	@echo "Copy config file to $(config_path)";
	@mkdir -p $(config_path)
	@cp -r configs $(config_path)

	@echo "Copy unit files to $(units_path)";
	@mkdir -p $(units_path)
	@cp -r units $(units_path)

	@echo "Start & Enable services";
	@systemctl daemon-reload
	@systemctl enable --now $(services)

uninstall: check_root
	@echo "Stop & Disable services"
	@systemctl disable --now $(services)

	@echo "Delete bash scripts to $(script_path)";
	@rm -rf $(script_path)

	@echo "Delete config file to $(config_path)";
	@rm -rf $(config_path)

	@echo "Delete unit files to $(units_path)";
	@rm -rf $(units_path)
	@systemctl daemon-reload

check_root:
	@if ! [ "$(shell id -u)" = 0 ];\
		then echo "You are not root, run this file as root please";\
		exit 1;\
	fi;

change_permission:
	@chmod 754 $(scripts)