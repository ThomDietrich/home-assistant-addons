# Changelog

## 1.3.0

- Added a more streamlined and intuitive way to define the forwarding local/remote sockets: https://github.com/ThomDietrich/home-assistant-addons/pull/16

## 1.2.1

- Switched from the invalid test user 'test' to the known '$USERNAME' for the sake of fail2ban: https://github.com/ThomDietrich/home-assistant-addons/pull/18
- Added the printout of local IPs to help with https://github.com/ThomDietrich/home-assistant-addons/issues/14

## 1.2.0

- Changed default port forwarding rule to be compatible with HassOS 9.4+ (https://github.com/home-assistant/operating-system/pull/2246)
- Breaking with HassOS 9.4: Existing users will lose their connectivity due to the changed network settings. You have to change the port forwarding rules after or directly prior to the OS upgrade 

## 1.1.0

Attention: v1.0.9 introduced a change you should pay attention to during an update.
Please set `other_ssh_options` to `-N` or `-N -v` (`N`: no login, just a tunneling connection; `v`: verbose logging)

- Replaced "config.json" by "config.yaml"
- Added changelog file

## 1.0.9

- Moved ssh argument `-N` to default configurable options so it can be removed (fixes #1)

## 1.0.8

- Switch key type to ed25519 (see #6)

## 1.0.0

- No change. Add-on has been stable for two years
