#!/bin/bash
#
# Hermes Agent Mobile — Termux Installer
# One-liner: curl -fsSL https://raw.githubusercontent.com/nousresearch/hermes-agent-mobile/main/install.sh | bash
#

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}"
echo "╔═══════════════════════════════════════════╗"
echo "║     Hermes Agent Mobile Installer        ║"
echo "║     AI Agent for Android                  ║"
echo "╚═══════════════════════════════════════════╝"
echo -e "${NC}"

# Check if running in Termux
if [ ! -d "/data/data/com.termux" ] && [ -z "$TERMUX_VERSION" ]; then
    echo -e "${YELLOW}Warning:${NC} Not running in Termux - some features may not work"
fi

# Update and install packages
echo -e "\n${BLUE}[1/2]${NC} Installing required packages..."
pkg update -y
pkg install -y nodejs-lts git proot-distro

echo -e "  ${GREEN}✓${NC} Node.js $(node --version)"
echo -e "  ${GREEN}✓${NC} npm $(npm --version)"
echo -e "  ${GREEN}✓${NC} git installed"
echo -e "  ${GREEN}✓${NC} proot-distro installed"

# Install hermes-agent-mobile from local or npm
echo -e "\n${BLUE}[2/2]${NC} Installing hermes-agent-mobile..."
npm install -g hermes-agent-mobile

echo -e "\n${GREEN}═══════════════════════════════════════════${NC}"
echo -e "${GREEN}Installation complete!${NC}"
echo -e "${GREEN}═══════════════════════════════════════════${NC}"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "  1. Run setup:      hermesx setup"
echo "  2. Configure:      hermesx configure"
echo "  3. Start agent:    hermesx start"
echo ""
echo -e "${YELLOW}Tip:${NC} Disable battery optimization for Termux in Android settings"
echo ""
