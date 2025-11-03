# Home Assistant Add-on: **Autossh**

**Make your Home Assistant accessible from anywhere — securely, through an SSH tunnel.**

Autossh lets you forward local ports (like your Home Assistant UI) through a remote SSH server.
It’s a simple alternative to VPNs or complex network setups — perfect if you can’t open ports on your home network.

You need access to a publicly available SSH server and some administrative privileges on that system.

The solution works reliably and without disruptions for a multitude of users.

## Quick Start (TL;DR)

1. Set `hostname` and `username` in the add-on config.
2. Start the add-on once → it generates a fresh SSH key pair.
3. Copy the **public key** provided via logs to your remote server’s `authorized_keys`.
4. **Important:** Add the `trusted_proxy` configuration to your Home Assistant's `configuration.yaml`.
5. Start the add-on again and check logs for success or error messages.

----

## Setup Guide

### 1. Prepare Home Assistant Network Configuration

Add this to your Home Assistant `configuration.yaml` (replace the IP with your HA host IP):

```yaml
http:
  use_x_forwarded_for: true
  trusted_proxies:
    - 192.168.0.2
```

This allows Home Assistant to trust forwarded connections from the SSH tunnel.
More info: [Trusted Proxies — Home Assistant Docs](https://www.home-assistant.io/integrations/http/#trusted_proxies)

### 2. SSH Key Generation & Setup

After installation and first start, check the logs of the add-on to see further instructions and status details.
The add-on creates an SSH keypair and uses it to connect to the given host.
The public key can be found in the log after the first startup and must be copied to the remote server.

On your typical remote server Linux system the public key is added to `<users home>/.ssh/authorized_keys`.
Do NOT add the key to the root user's `authorized_keys` file.
We recommend a dedicated user that doesn't have access to anything that isn't needed.
Consider the Docker solution provided below.

**Security Note**
For additional security, we prepend some restrictions to the public key that [disallow anything](https://manpages.debian.org/experimental/openssh-server/authorized_keys.5.en.html#restrict) other than port forwarding on the remote server.
For this to work, you **must** leave the `-N` in the `other_ssh_options` section of the default config.
If you do not want to use these additional security measures, you can remove everything before the `ssh-ed25519 ...` part of the key printout.

Be aware that anyone with access to your local Home Assistant's file system (and thus the private key) will be able to log in to your remote server and can execute any command if the restrictions are not set.

----

## Remote Server Configuration

The remote server is the machine hosting the SSH Server and the counterpart for your tunnel connection.
Most users might want to bind a domain name dedicated to their Home Assistant instance to this server's address.  

By default, forwarded ports can only be bound to localhost.
To make it available on a public interface, either reconfigure SSH or set up a reverse proxy.
A docker solution is given as the most secure and the cleanest solution overall.
You can expose ports in three main ways:

### Option 1: Enable SSH GatewayPorts

On the remot server edit `/etc/ssh/sshd_config`:

```
GatewayPorts clientspecified
```

This allows forwarded ports to bind to interfaces other than localhost.

### Option 2: Use a Reverse Proxy

Run a reverse proxy (e.g. **Caddy**, **Traefik**, **NGINX**) to:

* Expose the service publicly, and
* Automatically manage SSL certificates (e.g. via Let’s Encrypt).

### Option 3: Use a Docker-based SSH Server (Recommended)

Set up a dedicated SSH server isolated within a docker container on the remote server. This solution minimizes the attack surface of the overall solution tremendously.

The code below shows a suited `docker-compose.yml` configuration, including an example how you would nicely combine this with traefik as a reverse proxy option.

```yaml
services:
  homeassistant-autossh:
    image: linuxserver/openssh-server:latest
    restart: unless-stopped
    ports:
      - 1.2.3.4:2222:2222
    networks:
      - traefik
      - default
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=Europe/Berlin
      - USER_NAME=homeassistant
      - PASSWORD_ACCESS=false
      - SUDO_ACCESS=false
      - PUBLIC_KEY_FILE=/authorized_keys
    volumes:
      - ./openssh_config:/config               # Enable AllowTcpForwarding and GatewayPorts after creation during first run
      - ./authorized_keys:/authorized_keys:ro  # Store the generated ssh key from the add-on logs here
    labels:
      traefik.enable: "true"
      traefik.http.routers.homeassistant-myhome.rule: Host(`myhome.domain.tld`)
      traefik.http.routers.homeassistant-myhome.tls.certresolver: resolver-gandi
      traefik.http.routers.homeassistant-myhome.service: homeassistant-myhome
      traefik.http.services.homeassistant-myhome.loadbalancer.server.port: 8123

networks:
  traefik:
    external: true
```

The respective addon config might look similar to this:

```yaml
hostname: myserver.domain.tld
ssh_port: 2222
username: homeassistant
remote_ip_address: "127.0.0.1"
remote_port: 8123
```

----

## Configuration Options

| Option                    | Description                                                                                                                | Examples                                  |
| ------------------------- | -------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------- |
| `hostname`                | The remote server’s hostname or IP address.                                                                                | `myserver.domain.tld`, `1.2.3.4`          |
| `ssh_port`                | SSH port on the remote server.                                                                                             | `2222`                                    |
| `username`                | SSH username used to connect.                                                                                              | `homeassistant`                           |
| `remote_ip_address`       | IP address on the remote server to bind the Home Assistant UI on.                                                          | `127.0.0.1`                               |
| `remote_port`             | Port on the remote server to bind the Home Assistant UI on.                                                                | `8123`                                    |
| <br>**Secondary and Optional:** | |
| `force_keygen`            | Force regeneration of SSH key pair on next start.                                                                          | `true` or `false` (default)               |
| `other_ssh_options`       | Additional SSH options (e.g., `-v` for verbose output for troubleshooting). Under normal conditions, this should be `-N`.  | `-N -v` or `-N` (default)                 |
| `skip_remote_host_checks` | Disable host checks (useful if SSH server rate-limits connections).                                                        | `true` or `false` (default)               |
| `local_ip_address`        | Local IP to reach the Home Assistant UI. Not needed on standard HA OS setups.                                              | `home-assistant` (default), `172.30.32.1` |
| `local_port`              | Local port to reach the Home Assistant UI. Not needed on standard HA OS setups.                                            | `8123` (default)                          |
| `remote_forwarding`       | Custom SSH remote forwardings, in addition to the Home Assistant UI. If not needed, leave empty with `[]`                  | `[]` (default)<br>`- 127.0.0.1:1883:core-mosquitto:1883` |
