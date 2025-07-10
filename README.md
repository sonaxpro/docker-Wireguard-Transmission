# docker-Wireguard-Transmission

A docker compose setup for torrenting through a VPN tunnel, using Transmission as the torrent client and WireGuard as the VPN tunnel. This project is a fork of [chadek/docker-Wireguard-Transmission](https://github.com/chadek/docker-Wireguard-Transmission) with more precise settings and adjustments.

## Changes in This Fork
- Updated the docker-compose file with adjusted paths for easier configuration.
- Disabled IPv6 by default (IPv4-only setup). To enable IPv6, uncomment the relevant lines in the `docker-compose.yml` file.
- Tested and optimized for WSL (Windows Subsystem for Linux), which bypasses Windows firewalls, TCP stack issues, and Defender for better performance compared to native `.exe` applications.
- Recommended using [Transmission Remote GUI (transgui)](https://github.com/transmission-remote-gui/transgui) for a simple and effective way to manage Transmission remotely via a browser or desktop app.

## Requirements
Docker and docker compose are required to run this setup.

To enable **IPv6** (if needed), configure the Docker daemon by editing `/etc/docker/daemon.json` and restart Docker.

## Running This Tool
The WireGuard configuration sample provided here should be filled with proper values and mapped to the WireGuard image by placing it into [./wireguard/wg0.conf](https://github.com/chadek/docker-Wireguard-Transmission/blob/main/wireguard/wg0.conf).
The WireGuard config includes a network post-up script to correctly NAT IPv4 through interfaces.

After configuring WireGuard, run the following to start everything:

```
docker compose up
```

Or to run as a daemon in the background:

```
docker compose up -d
```

To verify that the torrent client is connected to your VPN IP, run:

```
docker exec transmission sh -c 'curl -4 ifconfig.io'
```

For IPv6 (if enabled):

```
docker exec transmission sh -c 'curl -6 ifconfig.io'
```
To check VPN stability with multiple attempts, run the `test-vpn.sh` script located in the repository root.


## Managing Transmission
You can manage Transmission via its web interface in a browser (simple UI) or use [Transmission Remote GUI (transgui)](https://github.com/transmission-remote-gui/transgui) for a more convenient desktop experience.

## Notes
- This setup works particularly well on WSL, as it avoids Windows-specific issues like firewalls, TCP stack conflicts, and Windows Defender interference.
- If you want to re-enable IPv6, simply uncomment the relevant lines in the `docker-compose.yml` file.
