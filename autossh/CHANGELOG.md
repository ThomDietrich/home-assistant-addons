# Changelog

## 1.1.0

- Please beware that the change in v1.0.9 is not breaking but you might want to set `other_ssh_options`to "-v -N" or even just "-N" (N: no login, just a tunneling connection, v: verbose logging),
- Replace "config.json" by "config.yaml"
- Add changelog file

## 1.0.9

- Move ssh argument `-N` to default configurable options so it can be removed (fixes #1)

## 1.0.8

- Switch key type to ed25519 (see #6)

## 1.0.0

- No change. Add-on has been stable for two years
