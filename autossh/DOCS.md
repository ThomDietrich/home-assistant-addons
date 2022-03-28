# Home Assistant Add-on: Autossh

Use SSH to make ports of your local Home Assistant setup available at or through a remote system.
This forms yet another way to make the Lovelace UI and other services accessible from another network or the public internet.
If you do not have the authority to open ports into your local network, and a VPN solutions seems overkill, this add-on might just be the solution for you.

The solution is only useful to those with access to a publicly available SSH server and some administrative privileges on that system.

Autossh is a well known tool to establish an SSH connection and keep it connected over hours and months.
SSH is known for its high security and the ability to set up port forwardings in both directions through the SSH connection.
In combination, this add-on offers tunneled port forwarding functionality.

The solution works reliably and without disruptions.

## TL;DR;

Set `hostname` and `username`, start once to generate a key pair, copy key pair over to remote server, start again, check log for success or error messages.

## Setup

The installation of this add-on is pretty straightforward and not different in comparison to installing any other Home Assistant add-on.

After installation and first start, check the logs of the add-on to see further instructions and status details.
The add-on creates an SSH keypair and uses it to connect to the given host.
The public key can be found in the log after the first startup and **must** be copied to the destination server for this add-on to work.
On your typical Linux system the public key is added to `~/.ssh/authorized_keys`.

## Remote Server Configuration

By default, forwarded ports can only be bound to localhost.
To make it available on a public interface, either reconfigure SSH or set up a reverse proxy. A docker solution is given as the most secure and the cleanest solution overall.

### SSH GatewayPorts

Consider to set `GatewayPorts clientspecified` in sshd-config if you would like to open ports on other interfaces than localhost.

### Reverse Proxy

Use a reverse proxy to make ports accessible on public interfaces.
Software like Caddy can be used to not only set up the redirect, it will also automatically retrieve a Let's Encrypt certificate (https) if you own a domain name.

### Docker based solution

The recommeded way to provide a secured SSH server for the purpose of this addon is a dedicated container on the remote server. The example below also shows how you would nicely combine this with traefik as one reverse proxy option.

```yaml
version: '3.1'
services:
  homeassistant-autossh:
    image: linuxserver/openssh-server:latest
    restart: unless-stopped
    ports:
      - 217.61.249.244:2244:2222  # External SSH port, to be used with autossh by homeassistant
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
      #- USER_PASSWORD=abc123
      - PUBLIC_KEY_FILE=/authorized_keys
    volumes:
      - ./openssh_config:/config  # Enable AllowTcpForwarding and GatewayPorts after creation during first run
      - ./authorized_keys:/authorized_keys:ro  # Store the generated ssh key here
    labels:
      traefik.enable: "true"

      traefik.http.routers.homeassistant-myhome.rule: Host(`myhome.domain.tld`)
      traefik.http.routers.homeassistant-myhome.tls.certresolver: resolver-gandi
      traefik.http.routers.homeassistant-myhome.service: homeassistant-myhome
      traefik.http.services.homeassistant-myhome.loadbalancer.server.port: 8001

networks:
  traefik:
    external: true
```

The respective addon config for this looks similar to this:

```yaml
hostname: ssh.domain.tld  # or public IP
ssh_port: 2244
username: homeassistant
remote_forwarding:
  - 127.0.0.1:8001:172.17.0.1:8123
```

## Configuration

### Option: `hostname`

The hostname of your SSH server (DNS or IP).

### Option: `ssh_port`

The SSH port on your SSH server (typically 22).

### Option: `username`

The username to be connected as on the SSH server.
Remember to store the generated public key in `~/.ssh/authorized_keys` of this users home.

### Option: `remote_forwarding`

A list of SSH remote forwadings to be applied.
For this add-on, the most meaningful setting is `127.0.0.1:8123:172.17.0.1:8123`.
This line forwards the Lovelace UI to the remote server localhost on the port 8123.
If you decided to go with `GatewayPorts`, you should know what to change.

### Option: `other_ssh_options`

Additional `ssh` options that will be added.
This is optional and for testing purposes a verbose output enabled by `-v` can be useful.

### Option: `force_keygen`

A key pair is generated when the container is first initialized in your environment.
Set this to `true` if you even need to urge to regenerate a key.

