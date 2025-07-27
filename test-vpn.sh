#!/bin/bash

# Цвета для красивого вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# Function for beautiful header
print_header() {
    echo -e "${BOLD}${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BOLD}${CYAN}║                    VPN PROXY TESTING                          ║${NC}"
    echo -e "${BOLD}${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

# Function for result output
print_result() {
    local status=$1
    local message=$2
    if [ "$status" = "SUCCESS" ]; then
        echo -e "${GREEN}[SUCCESS] $message${NC}"
    elif [ "$status" = "FAIL" ]; then
        echo -e "${RED}[FAIL] $message${NC}"
    elif [ "$status" = "INFO" ]; then
        echo -e "${BLUE}[INFO] $message${NC}"
    elif [ "$status" = "WARNING" ]; then
        echo -e "${YELLOW}[WARNING] $message${NC}"
    fi
}

# Function to get IP and geolocation
get_ip_info() {
    local ip=$(curl -s --connect-timeout 10 http://httpbin.org/ip | grep -o '"origin": "[^"]*"' | cut -d'"' -f4)
    if [ -n "$ip" ]; then
        local location=$(curl -s --connect-timeout 10 "http://ip-api.com/json/$ip" | grep -o '"country": "[^"]*"' | cut -d'"' -f4)
        local city=$(curl -s --connect-timeout 10 "http://ip-api.com/json/$ip" | grep -o '"city": "[^"]*"' | cut -d'"' -f4)
        echo "$ip|$location|$city"
    else
        echo "ERROR|ERROR|ERROR"
    fi
}

# Function to check internet availability
check_internet() {
    if docker exec vpn-wireguard curl -s --connect-timeout 5 http://httpbin.org/ip > /dev/null 2>&1; then
        echo "SUCCESS"
    else
        echo "FAIL"
    fi
}

# Main testing function
main() {
    print_header
    
    echo -e "${BOLD}${PURPLE}TEST 1: VPN Connection Check${NC}"
    echo "=================================================="
    
    # Check container status
    print_result "INFO" "Checking container status..."
    if docker compose ps | grep -q "Up"; then
        print_result "SUCCESS" "All containers are running"
    else
        print_result "FAIL" "Not all containers are running"
        exit 1
    fi
    
    echo ""
    
    # Check real IP (without VPN)
    print_result "INFO" "Getting real IP (without VPN)..."
    real_ip_info=$(curl -s --connect-timeout 10 http://httpbin.org/ip 2>/dev/null)
    if [ -n "$real_ip_info" ]; then
        real_ip=$(echo "$real_ip_info" | grep -o '"origin": "[^"]*"' | cut -d'"' -f4)
        print_result "SUCCESS" "Real IP: $real_ip"
        
        # Get real IP geolocation
        real_location=$(curl -s --connect-timeout 10 "http://ip-api.com/json/$real_ip" 2>/dev/null)
        real_country=$(echo "$real_location" | grep -o '"country": "[^"]*"' | cut -d'"' -f4)
        real_city=$(echo "$real_location" | grep -o '"city": "[^"]*"' | cut -d'"' -f4)
        
        if [ -n "$real_country" ] && [ "$real_country" != "ERROR" ]; then
            print_result "SUCCESS" "Real location: $real_city, $real_country"
        else
            # Try alternative API
            alt_real_location=$(curl -s --connect-timeout 10 "https://ipapi.co/$real_ip/json/" 2>/dev/null)
            alt_real_country=$(echo "$alt_real_location" | grep -o '"country_name": "[^"]*"' | cut -d'"' -f4)
            alt_real_city=$(echo "$alt_real_location" | grep -o '"city": "[^"]*"' | cut -d'"' -f4)
            
            if [ -n "$alt_real_country" ]; then
                print_result "SUCCESS" "Real location: $alt_real_city, $alt_real_country"
            else
                print_result "WARNING" "Could not determine real location"
            fi
        fi
    else
        print_result "FAIL" "Could not get real IP"
    fi
    
    echo ""
    
    # Check IP through VPN
    print_result "INFO" "Getting IP through VPN (wireguard)..."
    vpn_ip_info=$(docker exec vpn-wireguard curl -s --connect-timeout 10 http://httpbin.org/ip 2>/dev/null)
    if [ -n "$vpn_ip_info" ]; then
        vpn_ip=$(echo "$vpn_ip_info" | grep -o '"origin": "[^"]*"' | cut -d'"' -f4)
        print_result "SUCCESS" "VPN IP: $vpn_ip"
        
        # Get VPN IP geolocation
        vpn_location=$(curl -s --connect-timeout 10 "http://ip-api.com/json/$vpn_ip" 2>/dev/null)
        vpn_country=$(echo "$vpn_location" | grep -o '"country": "[^"]*"' | cut -d'"' -f4)
        vpn_city=$(echo "$vpn_location" | grep -o '"city": "[^"]*"' | cut -d'"' -f4)
        
        if [ -n "$vpn_country" ] && [ "$vpn_country" != "ERROR" ]; then
            print_result "SUCCESS" "VPN Location: $vpn_city, $vpn_country"
        else
            # Try alternative API
            alt_location=$(curl -s --connect-timeout 10 "https://ipapi.co/$vpn_ip/json/" 2>/dev/null)
            alt_country=$(echo "$alt_location" | grep -o '"country_name": "[^"]*"' | cut -d'"' -f4)
            alt_city=$(echo "$alt_location" | grep -o '"city": "[^"]*"' | cut -d'"' -f4)
            
            if [ -n "$alt_country" ]; then
                print_result "SUCCESS" "VPN Location: $alt_city, $alt_country"
            else
                print_result "WARNING" "Could not determine VPN location"
            fi
        fi
    else
        print_result "FAIL" "Could not get VPN IP"
    fi
    
    echo ""
    echo -e "${BOLD}${PURPLE}TEST 2: Kill Switch Check${NC}"
    echo "=================================================="
    
    # Check current internet access
    print_result "INFO" "Checking current internet access..."
    current_internet=$(check_internet)
    if [ "$current_internet" = "SUCCESS" ]; then
        print_result "SUCCESS" "Internet is available"
    else
        print_result "FAIL" "Internet is not available"
    fi
    
    echo ""
    print_result "INFO" "Disabling WireGuard for Kill Switch testing..."
    
    # Disable WireGuard
    docker exec vpn-wireguard wg-quick down wg0 2>/dev/null
    
    # Wait a bit
    sleep 3
    
    # Check internet access after VPN disconnection
    print_result "INFO" "Checking internet access after VPN disconnection..."
    after_disconnect=$(check_internet)
    
    if [ "$after_disconnect" = "FAIL" ]; then
        print_result "SUCCESS" "Kill Switch works! Internet is blocked"
    else
        print_result "FAIL" "Kill Switch does not work! Internet is available"
    fi
    
    echo ""
    print_result "INFO" "Restoring WireGuard connection..."
    
    # Restore WireGuard by restarting container
    docker compose restart wireguard >/dev/null 2>&1
    
    # Wait for connection
    sleep 10
    
    # Check restoration
    print_result "INFO" "Checking VPN connection restoration..."
    restored_internet=$(check_internet)
    
    if [ "$restored_internet" = "SUCCESS" ]; then
        print_result "SUCCESS" "VPN connection restored"
    else
        print_result "FAIL" "VPN connection not restored"
    fi
    
    echo ""
    echo -e "${BOLD}${GREEN}TESTING COMPLETED!${NC}"
    echo ""
    
    # Final summary
    echo -e "${BOLD}${CYAN}SUMMARY:${NC}"
    echo "=================="
    if [ -n "$real_ip" ]; then
        echo -e "${BLUE}• Real IP:${NC} $real_ip"
        if [ -n "$real_country" ] && [ "$real_country" != "ERROR" ]; then
            echo -e "${BLUE}• Real location:${NC} $real_city, $real_country"
        elif [ -n "$alt_real_country" ]; then
            echo -e "${BLUE}• Real location:${NC} $alt_real_city, $alt_real_country"
        fi
    fi
    
    if [ -n "$vpn_ip" ]; then
        echo -e "${BLUE}• VPN IP:${NC} $vpn_ip"
        if [ -n "$vpn_country" ] && [ "$vpn_country" != "ERROR" ]; then
            echo -e "${BLUE}• VPN location:${NC} $vpn_city, $vpn_country"
        elif [ -n "$alt_country" ]; then
            echo -e "${BLUE}• VPN location:${NC} $alt_city, $alt_country"
        fi
    fi
    
    # IP comparison
    if [ -n "$real_ip" ] && [ -n "$vpn_ip" ]; then
        if [ "$real_ip" != "$vpn_ip" ]; then
            echo -e "${GREEN}• VPN Status:${NC} Working [SUCCESS] (IP changed)"
        else
            echo -e "${RED}• VPN Status:${NC} Not working [FAIL] (IP not changed)"
        fi
    fi
    
    if [ "$after_disconnect" = "FAIL" ]; then
        echo -e "${GREEN}• Kill Switch:${NC} Working [SUCCESS]"
    else
        echo -e "${RED}• Kill Switch:${NC} Not working [FAIL]"
    fi
    
    echo ""
    echo -e "${YELLOW}For browser proxy settings:${NC}"
    echo "   • HTTP proxy: 127.0.0.1"
    echo "   • Port: 1080"
    echo "   • Type: SOCKS5"
}

# Запуск тестирования
main 