# hassio-addons

https://home-assistant.io/hassio

## Autossh [![](https://images.microbadger.com/badges/version/odinuge/hassio-addon-autossh-armhf.svg)](https://microbadger.com/images/odinuge/hassio-addon-autossh-armhf "Get your own version badge on microbadger.com")
Simple autossh addon. The addon creates a ssh keypair, and uses it
to connect to to the given host. The public key can be found in the
log after the first startup.

Remember to set `GatewayPorts clientspecified` in sshd-config if you
would like to open ports on other interfaces than localhost.

**IMPORTANT**: If you set `GatewayPorts yes`, all forwarded ports will
listen on all interfaces, `0.0.0.0`. `GatewayPorts clientspecified`
is preferable.

### Licence
MIT (c) Odin Ugedal
