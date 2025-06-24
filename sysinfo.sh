#!/bin/bash

echo "===== 🐧 System Info CLI Tool ====="
echo ""

# OS Info
echo "📦 OS: $(lsb_release -d | cut -f2)"

# Kernel Version
echo "🧬 Kernel: $(uname -r)"

# Uptime
echo "⏳ Uptime: $(uptime -p)"

# CPU Info
echo "🧠 CPU: $(lscpu | grep 'Model name' | cut -d ':' -f2 | sed 's/^ *//')"

# RAM Usage
echo "🧠 RAM: $(free -h | grep Mem | awk '{print $3 "/" $2}')"

# Disk Usage
echo "💽 Disk: $(df -h / | grep / | awk '{print $3 "/" $2 " used"}')"

# Hostname
echo "💻 Hostname: $(hostname)"

echo ""
echo "==================================="
