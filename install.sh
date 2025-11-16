#!/bin/bash

# sbsift installation script
set -e

echo "Installing sbsift..."

# Build in release mode
echo "Building sbsift..."
swift build -c release

# Install to /usr/local/bin
echo "Installing to /usr/local/bin..."
sudo cp .build/release/sbsift /usr/local/bin/

# Make executable
sudo chmod +x /usr/local/bin/sbsift

echo "sbsift installed successfully!"
echo "Usage: swift build | sbsift"