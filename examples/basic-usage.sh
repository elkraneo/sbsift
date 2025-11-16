#!/bin/bash

# sbsift Basic Usage Examples
# Demonstrates fundamental sbsift functionality

echo "🚀 sbsift Basic Usage Examples"
echo "================================"

# Create a sample Swift project for demonstration
echo "📁 Creating sample Swift project..."
SAMPLE_DIR="/tmp/sbsift-example"
cd /tmp
rm -rf sbsift-example
swift package init --type executable --name sbsift-example
cd sbsift-example

echo ""
echo "1️⃣ Basic Build Analysis"
echo "========================"
echo "Running: swift build | sbsift"
swift build | sbsift

echo ""
echo "2️⃣ Compact Output Mode"
echo "======================="
echo "Running: swift build | sbsift --compact"
swift build | sbsift --compact

echo ""
echo "3️⃣ Minimal Output Mode"
echo "======================"
echo "Running: swift build | sbsift --minimal"
swift build | sbsift --minimal

echo ""
echo "4️⃣ Context Size Comparison"
echo "=========================="
NORMAL_SIZE=$(swift build 2>&1 | wc -c | tr -d ' ')
COMPACT_SIZE=$(swift build 2>&1 | sbsift --compact | wc -c | tr -d ' ')
MINIMAL_SIZE=$(swift build 2>&1 | sbsift --minimal | wc -c | tr -d ' ')

echo "Original build output: $NORMAL_SIZE bytes"
echo "Compact sbsift output: $COMPACT_SIZE bytes"
echo "Minimal sbsift output: $MINIMAL_SIZE bytes"
echo ""
if [ "$NORMAL_SIZE" -gt 0 ]; then
  COMPACT_REDUCTION=$(( (NORMAL_SIZE - COMPACT_SIZE) * 100 / NORMAL_SIZE ))
  MINIMAL_REDUCTION=$(( (NORMAL_SIZE - MINIMAL_SIZE) * 100 / NORMAL_SIZE ))
  echo "Compact mode reduction: $COMPACT_REDUCTION%"
  echo "Minimal mode reduction: $MINIMAL_REDUCTION%"
fi

echo ""
echo "5️⃣ Test Output Analysis"
echo "========================"
echo "Running: swift test | sbsift --format summary"
swift test 2>&1 | sbsift --format summary

echo ""
echo "✅ Basic usage examples completed!"
echo ""
echo "💡 Try these commands in your own Swift projects:"
echo "   swift build | sbsift --compact"
echo "   swift test | sbsift --minimal"
echo "   swift build | sbsift --bottleneck 5"

# Clean up
cd /tmp
rm -rf sbsift-example