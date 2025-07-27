# Docker WireGuard Transmission with SOCKS5 Proxy

A comprehensive Docker Compose setup for secure torrenting through a VPN tunnel with SOCKS5 proxy support. This project provides a complete solution for anonymous torrenting with automatic kill switch protection and browser proxy capabilities.

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
│   Host (WSL)    │    │   WireGuard      │    │   Internet      │
│                 │    │   Container      │    │                 │
│ ┌─────────────┐ │    │ ┌──────────────┐ │    │                 │
│ │ Firefox     │◄┼────┼►│ VPN Tunnel   │◄┼────┼►│ Torrent Sites  │
│ │ SOCKS5:1080 │ │    │ │ Kill Switch  │ │    │ │ Web Services   │
│ └─────────────┘ │    │ └──────────────┘ │    │ └───────────────┘
│                 │    │ ┌──────────────┐ │    │                 │
│ ┌─────────────┐ │    │ │ Transmission │ │    │                 │
│ │ Test Script │◄┼────┼►│ Torrent      │◄┼────┼►│ Downloads      │
│ │ IP Check    │ │    │ │ Client       │ │    │ │ Uploads        │
│ └─────────────┘ │    │ └──────────────┘ │    │ └───────────────┘
└─────────────────┘    └──────────────────┘    └─────────────────┘
```

## Quick Start

### Prerequisites
- Docker and Docker Compose
- WireGuard configuration file (`wg0.conf`)

### Installation

1. **Clone the repository:**
   ```bash
   git clone <repository-url>
   cd docker-Wireguard-Transmission
   ```

2. **Configure WireGuard:**
   - Place your `wg0.conf` file in the `wireguard/wg_confs/` directory
   - The configuration includes kill switch rules for security

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
- **vpn-transmission**: Transmission torrent client
- **vpn-socks5proxy**: SOCKS5 proxy server
- **vpn-gateway**: SOCKS5 proxy gateway for host access

### Network Configuration

- All containers use `network_mode: service:wireguard` for VPN routing
- SOCKS5 proxy exposed on `127.0.0.1:1080` for browser access
- Kill switch prevents traffic leaks when VPN disconnects

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

Configure your browser to use the SOCKS5 proxy:

- **Proxy Type**: SOCKS5
- **Address**: 127.0.0.1
- **Port**: 1080

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
- Automatically blocks all traffic when VPN disconnects
- Prevents IP leaks during connection drops
- Allows local network access while blocking external traffic

### VPN Health Monitoring
- Automatic detection of VPN disconnections
- Container restart on connection failures
- Continuous monitoring with health checks

### SOCKS5 Proxy Security
- Isolated proxy container with VPN routing
- No direct host network access
- Encrypted traffic through WireGuard tunnel

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

### WSL Benefits
- Bypasses Windows firewall restrictions
- Avoids TCP stack conflicts
- Better performance than native Windows applications
- Direct access to Linux networking stack

### Resource Usage
- Minimal memory footprint (~200MB total)
- Efficient container networking
- Optimized for low-resource environments

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