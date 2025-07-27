# Docker WireGuard Transmission with SOCKS5 Proxy

A comprehensive Docker Compose setup for selective VPN routing with SOCKS5 proxy support. This project solves the problem of routing only specific applications (torrents and browser) through VPN while keeping other traffic on the local network.

## 🎯 Problem Statement

### The Challenge
Traditional VPN solutions route **all system traffic** through the VPN tunnel, which is often unnecessary and can cause:
- **Performance issues**: Slower local network access
- **Service conflicts**: Problems with local services, printers, NAS
- **Geolocation issues**: Banking, streaming services detecting VPN
- **Resource waste**: VPN bandwidth for local traffic

### The Solution
This project provides **selective VPN routing** where only specific applications use the VPN:
- **Torrent traffic**: All Transmission downloads/uploads through VPN
- **Browser traffic**: Firefox SOCKS5 proxy through VPN  
- **Local traffic**: Everything else remains on local network

### Evolution from VM to Native
Previously, this required dedicated virtual machines for VPN tasks. This Docker setup provides:
- **Native performance**: No VM overhead
- **WSL integration**: Seamless Windows integration
- **Resource efficiency**: Minimal resource usage
- **Easy management**: Simple Docker commands

## Features

- **WireGuard VPN**: Secure VPN tunnel with automatic kill switch
- **Transmission**: Torrent client with web interface
- **SOCKS5 Proxy**: Browser proxy support for complete anonymity
- **Kill Switch**: Automatic traffic blocking when VPN disconnects
- **Health Monitoring**: Automatic VPN reconnection
- **Comprehensive Testing**: Built-in testing script with IP comparison
- **WSL Optimized**: Tested and optimized for Windows Subsystem for Linux

## Architecture

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   Host (WSL)    │    │   WireGuard      │    │   VPN Internet  │
│                 │    │   Container      │    │   (Encrypted)   │
│ ┌─────────────┐ │    │ ┌──────────────┐ │    │                 │
│ │ Firefox     │◄┼────┼►│ VPN Tunnel   │◄┼────┼►│ Torrent Sites  │
│ │ SOCKS5:1080 │ │    │ │ Kill Switch  │ │    │ │ Web Services   │
│ └─────────────┘ │    │ └──────────────┘ │    │ └───────────────┘
│                 │    │ ┌──────────────┐ │    │                 │
│ ┌─────────────┐ │    │ │ SOCKS5 Proxy │ │    │                 │
│ │ Test Script │◄┼────┼►│ Server       │ │    │                 │
│ │ IP Check    │ │    │ └──────────────┘ │    │                 │
│ └─────────────┘ │    │ ┌──────────────┐ │    │                 │
│                 │    │ │ Transmission │ │    │                 │
│                 │    │ │ Torrent      │◄┼────┼►│ Downloads      │
│                 │    │ │ Client       │ │    │ │ Uploads        │
│                 │    │ └──────────────┘ │    │ └───────────────┘
└─────────────────┘    └──────────────────┘    └─────────────────┘
```

## 🔒 Traffic Flow Analysis

### Primary VPN Channel (Main Traffic)
```
Transmission → WireGuard Container → VPN Server → Internet
```
- **Direct VPN routing**: Transmission uses `network_mode: service:wireguard`
- **All torrent traffic**: Downloads, uploads, tracker communication
- **Kill Switch protection**: Blocks all non-VPN traffic

### Secondary SOCKS5 Channel (Browser Traffic)
```
Any Browser → SOCKS5 Gateway → SOCKS5 Proxy → WireGuard Container → VPN Server → Internet
```
- **Browser proxy**: Any browser configured to use SOCKS5 proxy
- **Gateway routing**: SOCKS5 Gateway (socat) routes traffic to SOCKS5 Proxy
- **Proxy processing**: SOCKS5 Proxy handles protocol and routes through WireGuard
- **Same VPN tunnel**: All traffic goes through same encrypted channel

### Security Architecture
```
┌─────────────────────────────────────────────────────────────┐
│                    KILL SWITCH ZONE                        │
│  ┌─────────────────┐    ┌──────────────────┐              │
│  │   Host (WSL)    │    │   WireGuard      │              │
│  │                 │    │   Container      │              │
│  │ ┌─────────────┐ │    │ ┌──────────────┐ │              │
│  │ │ Any Browser │◄┼────┼►│ VPN Tunnel   │ │              │
│  │ │ SOCKS5:1080 │ │    │ │ Kill Switch  │ │              │
│  │ └─────────────┘ │    │ └──────────────┘ │              │
│  │                 │    │ ┌──────────────┐ │              │
│  │ ┌─────────────┐ │    │ │ SOCKS5 Proxy │ │              │
│  │ │ Test Script │◄┼────┼►│ Server       │ │              │
│  │ │ IP Check    │ │    │ └──────────────┘ │              │
│  │ └─────────────┘ │    │ ┌──────────────┐ │              │
│  │                 │    │ │ Transmission │ │              │
│  │                 │    │ │ Torrent      │ │              │
│  │                 │    │ │ Client       │ │              │
│  │                 │    │ └──────────────┘ │              │
│  └─────────────────┘    └──────────────────┘              │
└─────────────────────────────────────────────────────────────┘
                                │
                                ▼
                        ┌─────────────────┐
                        │   VPN Server    │
                        │   (Encrypted)   │
                        └─────────────────┘
                                │
                                ▼
                        ┌─────────────────┐
                        │   Internet      │
                        │   (Public)      │
                        └─────────────────┘
```

### Parallel Internet Connections
```
┌─────────────────────────────────────────────────────────────┐
│                    HOST SYSTEM                             │
│  ┌─────────────────┐    ┌──────────────────┐              │
│  │   Applications  │    │   VPN Container  │              │
│  │                 │    │   (Isolated)     │              │
│  │ ┌─────────────┐ │    │ ┌──────────────┐ │              │
│  │ │ Other Apps  │ │    │ │ Any Browser  │ │              │
│  │ │ (Native)    │ │    │ │ SOCKS5:1080  │ │              │
│  │ │ Banking     │ │    │ └──────────────┘ │              │
│  │ │ Streaming   │ │    │ ┌──────────────┐ │              │
│  │ │ Local NAS   │ │    │ │ Transmission │ │              │
│  │ │ Printers    │ │    │ │ Torrent      │ │              │
│  │ └─────────────┘ │    │ └──────────────┘ │              │
│  └─────────────────┘    └──────────────────┘              │
│           │                        │                       │
│           ▼                        ▼                       │
│  ┌─────────────────┐    ┌──────────────────┐              │
│  │   Local Network │    │   VPN Server     │              │
│  │   (Direct)      │    │   (Encrypted)    │              │
│  └─────────────────┘    └──────────────────┘              │
│           │                        │                       │
│           ▼                        ▼                       │
│  ┌─────────────────┐    ┌──────────────────┐              │
│  │   Internet      │    │   Internet       │              │
│  │   (Real IP)     │    │   (VPN IP)       │              │
│  │   Your ISP      │    │   VPN Location   │              │
│  └─────────────────┘    └──────────────────┘              │
└─────────────────────────────────────────────────────────────┘
```

**Key Points:**
- **Real IP**: Host applications use your actual ISP IP address
- **VPN IP**: Container applications use VPN server IP address  
- **Separate Connections**: Two independent internet connections
- **No Traffic Mixing**: Each connection maintains its own identity
- **Geolocation**: Host apps see your real location, VPN apps see VPN location

### Network Isolation Strategy
- **Selective Routing**: Only specific applications use VPN tunnel
- **Parallel Connections**: Host system maintains direct internet access
- **Container Isolation**: VPN applications isolated in containers
- **Kill Switch**: Only affects VPN container traffic, not host system
- **Service Mode**: Transmission and SOCKS5 proxy share WireGuard's network namespace
- **Gateway Isolation**: SOCKS5 gateway provides controlled host access

## Quick Start

### Prerequisites
- **Docker and Docker Compose**: Required for container orchestration
- **WireGuard configuration file** (`wg0.conf`): Your VPN server configuration
- **WSL2 (Windows)**: Tested and optimized for Windows Subsystem for Linux
- **Linux**: Native support for Linux environments

### Installation

1. **Clone the repository:**
   ```bash
   git clone <repository-url>
   cd docker-Wireguard-Transmission
   ```

2. **Configure WireGuard:**
   - Place your `wg0.conf` file in the `wireguard/wg_confs/` directory
   - **IMPORTANT**: Your `wg0.conf` must include kill switch rules in the `[Interface]` section:
   ```ini
   [Interface]
   # ... your existing configuration ...
   
   # Kill Switch Rules (REQUIRED)
   PostUp = DROUTE=$(ip route | grep default | awk '{print $3}'); HOMENET=192.168.0.0/16; HOMENET3=172.16.0.0/12; ip route add $HOMENET3 via $DROUTE; ip route add $HOMENET via $DROUTE; iptables -I OUTPUT -d $HOMENET -j ACCEPT; iptables -A OUTPUT -d $HOMENET3 -j ACCEPT; iptables -A OUTPUT ! -o %i -m mark ! --mark $(wg show %i fwmark) -m addrtype ! --dst-type LOCAL -j REJECT
   PostDown = HOMENET=192.168.0.0/16; HOMENET3=172.16.0.0/12; ip route del $HOMENET3 via $DROUTE; ip route del $HOMENET via $DROUTE; iptables -D OUTPUT ! -o %i -m mark ! --mark $(wg show %i fwmark) -m addrtype ! --dst-type LOCAL -j REJECT; iptables -D OUTPUT -d $HOMENET -j ACCEPT; iptables -D OUTPUT -d $HOMENET3 -j ACCEPT
   ```
   - Without these rules, the kill switch will not work and your real IP may be exposed

3. **Start the services:**
   ```bash
   docker compose up -d
   ```

4. **Test the setup:**
   ```bash
   ./test-vpn.sh
   ```

## Configuration

### Docker Compose Services

- **vpn-wireguard**: WireGuard VPN container with kill switch
- **vpn-transmission**: Transmission torrent client (uses `network_mode: service:wireguard`)
- **vpn-socks5proxy**: SOCKS5 proxy server (uses `network_mode: service:wireguard`)
- **vpn-gateway**: SOCKS5 proxy gateway for host access (exposes port 1080)

### Network Configuration

#### Primary VPN Channel
- **WireGuard Container**: Main VPN container with kill switch rules and encrypted tunnel
- **Transmission**: Uses `network_mode: service:wireguard` for direct VPN routing
- **All torrent traffic**: Downloads, uploads, and tracker communication go through VPN

#### Secondary Browser Channel  
- **SOCKS5 Proxy Server**: Runs inside WireGuard container's network namespace
- **SOCKS5 Gateway**: Uses bridge network to provide controlled host access
- **Firefox Integration**: Browser traffic routed through same VPN tunnel
- **Port Exposure**: SOCKS5 proxy exposed on `127.0.0.1:1080` for browser access

#### Security Isolation
- **Kill Switch**: Implemented via iptables rules in WireGuard configuration
- **No Direct Access**: All containers must go through VPN tunnel
- **Service Mode**: Transmission and SOCKS5 proxy share WireGuard's network namespace
- **Gateway Isolation**: SOCKS5 gateway provides controlled host access without direct network exposure

### Volume Mappings

```yaml
volumes:
  - ./wireguard:/config          # WireGuard configuration
  - ./transmission-config:/config # Transmission settings
  - /path/to/downloads:/downloads # Download directory
  - /path/to/watch:/watch        # Watch directory
```

## Usage

### Browser Proxy Configuration

Configure **any browser** to use the SOCKS5 proxy:

- **Proxy Type**: SOCKS5
- **Address**: 127.0.0.1
- **Port**: 1080

**Supported Browsers:**
- **Firefox**: Settings → Network Settings → Manual proxy configuration
- **Chrome/Edge**: Requires extension (e.g., Proxy SwitchyOmega)
- **Safari**: Preferences → Advanced → Proxies
- **Opera**: Settings → Advanced → System → Proxy
- **Any SOCKS5-compatible application**: Email clients, download managers, etc.

### Transmission Web Interface

Access Transmission at: `http://localhost:9091`

### Testing and Monitoring

Run the comprehensive test script:

```bash
./test-vpn.sh
```

This script will:
- Compare real IP vs VPN IP
- Test kill switch functionality
- Verify SOCKS5 proxy operation
- Check automatic VPN reconnection

## Security Features

### Kill Switch
- **Implementation**: Uses iptables rules in WireGuard configuration
- **Function**: Automatically blocks all traffic when VPN disconnects
- **Security**: Prevents IP leaks during connection drops
- **Local Access**: Allows local network access while blocking external traffic
- **Requirements**: Must include PostUp/PostDown rules in `wg0.conf` (see Quick Start section)

### VPN Health Monitoring
- Automatic detection of VPN disconnections
- Container restart on connection failures
- Continuous monitoring with health checks

### SOCKS5 Proxy Security
- **Architecture**: Proxy server runs inside WireGuard container's network namespace
- **Isolation**: No direct host network access, all traffic goes through VPN
- **Encryption**: All traffic encrypted through WireGuard tunnel
- **Gateway**: Host connects via socat gateway container for isolation

## Troubleshooting

### Common Issues

1. **VPN not connecting:**
   - Check WireGuard configuration in `wireguard/wg_confs/wg0.conf`
   - Verify server endpoint and keys

2. **SOCKS5 proxy not working:**
   - Ensure containers are running: `docker compose ps`
   - Check proxy logs: `docker logs vpn-gateway`

3. **Kill switch too restrictive:**
   - Modify iptables rules in WireGuard configuration
   - Add specific network exceptions if needed

### Logs and Debugging

```bash
# Check container status
docker compose ps

# View WireGuard logs
docker logs vpn-wireguard

# Test VPN connection
docker exec vpn-wireguard curl http://httpbin.org/ip

# Test SOCKS5 proxy
curl --socks5 127.0.0.1:1080 http://httpbin.org/ip
```

## Performance Optimization

### Environment Support

#### WSL2 (Windows Subsystem for Linux)
- **Primary target**: Tested and optimized for WSL2
- **Windows integration**: Seamless access to Windows file system
- **Firewall bypass**: Avoids Windows firewall restrictions
- **TCP stack**: Uses Linux networking stack (more reliable)
- **Performance**: Better than native Windows VPN applications

#### Native Linux
- **Full support**: All features work natively
- **Direct access**: No virtualization layer
- **Maximum performance**: Minimal overhead
- **Network stack**: Direct Linux networking

#### Windows Native (Not Recommended)
- **Limited testing**: Not the primary target
- **Potential issues**: Windows firewall, Defender interference
- **Performance**: May have TCP stack conflicts
- **Recommendation**: Use WSL2 instead

### Resource Usage
- **Minimal footprint**: ~200MB total (vs 2-4GB for VM)
- **Efficient networking**: Container-level isolation
- **Low overhead**: No virtualization layer
- **Fast startup**: Seconds vs minutes for VM

### Advantages Over VM Approach
- **No VM overhead**: Direct container performance
- **Easy management**: Docker commands vs VM management
- **Resource efficiency**: Shared kernel, minimal duplication
- **WSL integration**: Seamless Windows file system access
- **Quick deployment**: Minutes vs hours for VM setup

## Contributing

This project is a fork of [chadek/docker-Wireguard-Transmission](https://github.com/chadek/docker-Wireguard-Transmission) with significant improvements:

- Added SOCKS5 proxy support
- Implemented comprehensive kill switch
- Enhanced testing and monitoring
- Improved documentation and examples
- WSL optimization and testing

## License

This project is licensed under the GNU General Public License v3.0 - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- Original project by [chadek](https://github.com/chadek)
- LinuxServer.io for Docker images
- WireGuard project for VPN technology
- Transmission team for torrent client

## Support

For issues and questions:
1. Check the troubleshooting section
2. Review container logs
3. Run the test script for diagnostics
4. Open an issue with detailed information

## Disclaimer

**Disclaimer**: This project is intended for educational and testing purposes. The author is not responsible for any misuse of this software.