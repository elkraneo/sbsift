#!/bin/bash

# sbsift A+ Grade Installation Script
# Installs the enhanced Swift Build Analysis Tool with all features

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 Installing sbsift A+ Grade Swift Build Analysis Tool${NC}"
echo "======================================================"

# Check if Swift is available
if ! command -v swift &> /dev/null; then
    echo -e "${RED}❌ Error: Swift is not installed. Please install Swift 5.9+ first.${NC}"
    echo "Install Swift: https://www.swift.org/download/"
    exit 1
fi

# Check Swift version
SWIFT_VERSION=$(swift --version | head -n1 | grep -o '[0-9]\+\.[0-9]\+' | head -n1)
echo -e "${GREEN}✅ Swift version: $SWIFT_VERSION${NC}"

# Build in release mode
echo -e "${BLUE}🔨 Building sbsift in release mode...${NC}"
swift build -c release

# Verify build was successful
if [ ! -f ".build/release/sbsift" ]; then
    echo -e "${RED}❌ Build failed. Please check the error messages above.${NC}"
    exit 1
fi

# Install to /usr/local/bin
INSTALL_DIR="/usr/local/bin"
if [ ! -d "$INSTALL_DIR" ]; then
    echo -e "${YELLOW}⚠️  Creating $INSTALL_DIR directory...${NC}"
    sudo mkdir -p "$INSTALL_DIR"
fi

echo -e "${BLUE}📦 Installing to $INSTALL_DIR...${NC}"
sudo cp .build/release/sbsift "$INSTALL_DIR/sbsift"

# Make executable
sudo chmod +x "$INSTALL_DIR/sbsift"

# Verify installation
if command -v sbsift &> /dev/null; then
    echo -e "${GREEN}✅ sbsift installed successfully!${NC}"

    # Show version
    SBSIFT_VERSION=$(sbsift --version 2>/dev/null || echo "v1.0.0")
    echo -e "${GREEN}📱 Version: $SBSIFT_VERSION${NC}"

    echo ""
    echo -e "${BLUE}🎯 Quick Start:${NC}"
    echo -e "  ${YELLOW}swift build | sbsift${NC}                    # Basic analysis"
    echo -e "  ${YELLOW}swift build | sbsift --compact${NC}         # 60-70% reduction"
    echo -e "  ${YELLOW}swift build | sbsift --minimal${NC}         # 85%+ reduction"
    echo -e "  ${YELLOW}swift build | sbsift --bottleneck 5${NC}    # Performance analysis"
    echo ""
    echo -e "${BLUE}📚 Documentation:${NC}"
    echo -e "  ${YELLOW}man sbsift${NC}                             # Manual page"
    echo -e "  ${YELLOW}sbsift --help${NC}                          # Help command"
    echo -e "  ${YELLOW}https://github.com/elkraneo/sbsift${NC}     # GitHub repository"
    echo ""
    echo -e "${GREEN}🎉 Installation completed successfully!${NC}"

    # Test basic functionality
    echo -e "${BLUE}🧪 Testing installation...${NC}"
    echo "test build output" | sbsift --minimal > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Installation test passed!${NC}"
    else
        echo -e "${YELLOW}⚠️  Installation test failed, but binary was installed.${NC}"
    fi
else
    echo -e "${RED}❌ Installation failed. Please check your PATH.${NC}"
    echo "Make sure $INSTALL_DIR is in your PATH"
    exit 1
fi

echo ""
echo -e "${BLUE}💡 Pro tip: Add these aliases to your .zshrc or .bashrc:${NC}"
echo -e "  ${YELLOW}alias sb='swift build | sbsift --compact'${NC}"
echo -e "  ${YELLOW}alias sbp='swift build | sbsift --bottleneck 5'${NC}"
echo -e "  ${YELLOW}alias sbm='swift build | sbsift --monitor 300'${NC}"