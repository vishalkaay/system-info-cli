#!/bin/bash

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# ASCII Art
echo -e "${CYAN}"
cat << "EOF"
   _____ __  __ ____ ___  _   _   ___ _   _ _____ 
  / ____|  \/  |___ \__ \| \ | | |__ \ | | |____|
 | (___ | \  / | __) | ) |  \| |    ) | | |     
  \___ \| |\/| |__ < / / | . ` |   / /| | |     
  ____) | |  | |___) / /_| |\  |  / /_| |_|     
 |_____/|_|  |_|____/____|_| \_| |____|\___/     
EOF
echo -e "${NC}"

# System Info
echo -e "${YELLOW}⚡ ${BLUE}System Information${NC}"
echo -e "${GREEN}----------------------------------------${NC}"

# OS Info with distro logo
os_logo() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        case $ID in
            ubuntu) echo -e "  ____  _   _  ____  _   _  ___ "; echo " | __ )| | | || __ )| | | |/ _ \ "; echo " |  _ \| | | ||  _ \| | | | | | |"; echo " | |_) | |_| || |_) | |_| | |_| |"; echo " |____/ \___/ |____/ \___/ \___/ ";;
            debian) echo -e "  ____  _____ ____ ___ _   _ "; echo " |  _ \| ____|  _ \_ _| \ | |"; echo " | | | |  _| | | | | ||  \| |"; echo " | |_| | |___| |_| | || |\  |"; echo " |____/|_____|____/___|_| \_|";;
            fedora) echo -e "  _____     ____  _____  ____  ___ "; echo " |  ___|   / ___|| ____||  _ \| _ \ "; echo " | |_     | |    |  _|  | | | | | | |"; echo " |  _|    | |___ | |___ | |_| | |_| |"; echo " |_|       \____||_____||____/ \___/ ";;
            arch) echo -e "     _       _     _   "; echo "    / \   __| | __| | "; echo "   / _ \ / _\` |/ _\` |"; echo "  / ___ \ (_| | (_| |"; echo " /_/   \_\__,_|\__,_|";;
            *) echo "$PRETTY_NAME";;
        esac
    else
        echo "Unknown OS"
    fi
}

os_logo
echo -e "${YELLOW}OS:${NC} $(lsb_release -d | cut -f2-)"
echo -e "${YELLOW}Kernel:${NC} $(uname -r)"
echo -e "${YELLOW}Hostname:${NC} $(hostname)"
echo -e "${YELLOW}Uptime:${NC} $(uptime -p | sed 's/up //')"

# CPU Info
cpu_model=$(lscpu | grep 'Model name' | cut -d ':' -f2 | sed 's/^[ \t]*//')
cpu_cores=$(lscpu | grep '^CPU(s):' | awk '{print $2}')
cpu_usage=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1"%"}')

echo -e "\n${YELLOW}💻 ${BLUE}CPU Information${NC}"
echo -e "${GREEN}----------------------------------------${NC}"
echo -e "${YELLOW}Model:${NC} $cpu_model"
echo -e "${YELLOW}Cores:${NC} $cpu_cores"
echo -e "${YELLOW}Usage:${NC} $cpu_usage"

# Memory Info
mem_total=$(free -h | grep Mem | awk '{print $2}')
mem_used=$(free -h | grep Mem | awk '{print $3}')
mem_percent=$(free | grep Mem | awk '{printf("%.2f%"), $3/$2*100}')

echo -e "\n${YELLOW}🧠 ${BLUE}Memory Information${NC}"
echo -e "${GREEN}----------------------------------------${NC}"
echo -e "${YELLOW}Total:${NC} $mem_total"
echo -e "${YELLOW}Used:${NC} $mem_used"
echo -e "${YELLOW}Usage:${NC} $mem_percent"

# Disk Info
disk_total=$(df -h / | grep / | awk '{print $2}')
disk_used=$(df -h / | grep / | awk '{print $3}')
disk_percent=$(df -h / | grep / | awk '{print $5}')

echo -e "\n${YELLOW}💾 ${BLUE}Disk Information${NC}"
echo -e "${GREEN}----------------------------------------${NC}"
echo -e "${YELLOW}Total:${NC} $disk_total"
echo -e "${YELLOW}Used:${NC} $disk_used"
echo -e "${YELLOW}Usage:${NC} $disk_percent"

# Network Info
ip_address=$(hostname -I | awk '{print $1}')
public_ip=$(curl -s ifconfig.me)

echo -e "\n${YELLOW}🌐 ${BLUE}Network Information${NC}"
echo -e "${GREEN}----------------------------------------${NC}"
echo -e "${YELLOW}Local IP:${NC} $ip_address"
echo -e "${YELLOW}Public IP:${NC} $public_ip"

# Battery Info (if available)
if [ -f /sys/class/power_supply/BAT0/capacity ]; then
    battery=$(cat /sys/class/power_supply/BAT0/capacity)
    echo -e "\n${YELLOW}🔋 ${BLUE}Battery Information${NC}"
    echo -e "${GREEN}----------------------------------------${NC}"
    echo -e "${YELLOW}Charge:${NC} $battery%"
fi

# System Load
load=$(uptime | awk -F 'load average: ' '{print $2}')
echo -e "\n${YELLOW}⚖️ ${BLUE}System Load${NC}"
echo -e "${GREEN}----------------------------------------${NC}"
echo -e "${YELLOW}Load Average:${NC} $load"

# Weather (using simpler format)
echo -e "\n${YELLOW}☀️ ${BLUE}Local Weather${NC}"
echo -e "${GREEN}----------------------------------------${NC}"
weather=$(curl -s "wttr.in/?format=%l:+%c+%t")
echo -e "${YELLOW}$weather${NC}"

# Fun fact without jq (using grep and cut)
echo -e "\n${YELLOW}💡 ${BLUE}Did You Know?${NC}"
echo -e "${GREEN}----------------------------------------${NC}"
fun_fact=$(curl -s "https://uselessfacts.jsph.pl/random.json?language=en" | grep -o '"text":"[^"]*"' | cut -d'"' -f4)
echo -e "${YELLOW}$fun_fact${NC}"

# Footer
echo -e "\n${MAGENTA}Report generated on: $(date)${NC}"
echo -e "${CYAN}✨ Have a nice day! ✨${NC}"
