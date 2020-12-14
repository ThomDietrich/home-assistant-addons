# Home Assistant Community Add-on: Autossh

## About

Use SSH to make ports of your local Home Assistant setup available at a remote system.
This forms yet another way to make services on your local system (e.g. the Lovelace UI) accessible from the public internet.
If you do not have the authority to open ports into your local network, and a VPN solutions seems overkill, this add-on might just be the solution for you.

This add-on is only useful to those with access to a publicly available SSH server and some administrative privileges on that system.

Autossh is a well known tool to establish an SSH connection and keep it connected over hours and months.
SSH is known for its high security and the ability to set up port forwardings in both directions through the SSH connection.
In combination, this add-on offers tunneled port forwarding functionality.

## Installation

The installation of this add-on is pretty straightforward and not different in comparison to installing any other Home Assistant add-on.

1. Search for the add-on in the Supervisor add-on store.
1. Install the add-on.
1. Start the add-on.
1. Check the logs of the add-on to see further instructions and status details.

The add-on creates an SSH keypair and uses it to connect to the given host.
The public key can be found in the log after the first startup.

## Remote Server Configuration

By default, forwarded ports can only be bound to localhost.
To make it available on a public interface, either reconfigure SSH or set up a reverse proxy.

### SSH GatewayPorts

Consider to set `GatewayPorts clientspecified` in sshd-config if you would like to open ports on other interfaces than localhost.

### Reverse Proxy

We recommend to use a reverse proxy to make ports accessible on public interfaces.
Software like Caddy can be used to not only set up the redirect, it will also automatically retrieve a Let's Encrypt certificate if you own a domain name.
