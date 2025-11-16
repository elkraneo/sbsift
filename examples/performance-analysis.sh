#!/bin/bash

# sbsift Performance Analysis Examples
# Demonstrates advanced performance monitoring features

echo "📊 sbsift Performance Analysis Examples"
echo "======================================="

# Check if sbsift is available
if ! command -v sbsift &> /dev/null; then
    echo "❌ sbsift not found. Please install sbsift first."
    exit 1
fi

echo "1️⃣ Real-time Build Monitoring"
echo "=============================="
echo "Monitoring build with 30-second timeout..."
echo "Use this for potentially long-running builds"
echo ""

# Create a sample project
SAMPLE_DIR="/tmp/sbsift-perf-test"
cd /tmp
rm -rf sbsift-perf-test
swift package init --type executable --name sbsift-perf-test
cd sbsift-perf-test

# Add some source files to make compilation more interesting
cat > Sources/sbsift-perf-test/Model.swift << 'EOF'
import Foundation

struct Model {
    let id: UUID
    let name: String
    let data: [String]

    init(name: String) {
        self.id = UUID()
        self.name = name
        self.data = Array(0...100).map { "Item_\($0)" }
    }
}
EOF

cat > Sources/sbsift-perf-test/Processor.swift << 'EOF'
import Foundation

class Processor {
    func process<T>(_ items: [T]) -> [T] {
        return items.enumerated().compactMap { index, item in
            if index % 2 == 0 {
                return item
            }
            return nil
        }
    }
}
EOF

echo "Running: swift build | sbsift --monitor 30 --compact"
echo "(This would normally show real-time monitoring output)"
swift build | sbsift --monitor 30 --compact

echo ""
echo "2️⃣ File Timing Analysis"
echo "========================="
echo "Analyzing per-file compilation times..."
echo ""

# Add a more complex source file to trigger file timing
cat > Sources/sbsift-perf-test/ComplexLogic.swift << 'EOF'
import Foundation

class ComplexLogic {
    func calculateHeavyComputation() -> Double {
        var result = 0.0
        for i in 0...1000 {
            result += sin(Double(i)) * cos(Double(i))
        }
        return result
    }

    func processLargeArray() -> [Int] {
        return (0...10000).map { $0 * 2 }
            .filter { $0 % 3 == 0 }
            .map { $0 + 1 }
    }
}
EOF

echo "Running: swift build | sbsift --file-timing"
swift build | sbsift --file-timing

echo ""
echo "3️⃣ Bottleneck Detection"
echo "========================"
echo "Identifying slowest compilation files..."
echo ""

echo "Running: swift build | sbsift --bottleneck 3 --compact"
swift build | sbsift --bottleneck 3 --compact

echo ""
echo "4️⃣ Performance Comparison"
echo "=========================="
echo "Comparing different output modes and their performance..."
echo ""

# Measure performance of different modes
echo "Testing Normal JSON mode..."
time swift build > /dev/null 2>&1
echo "Normal JSON size: $(swift build 2>&1 | sbsift | wc -c) bytes"

echo ""
echo "Testing Compact mode..."
time swift build > /dev/null 2>&1
echo "Compact JSON size: $(swift build 2>&1 | sbsift --compact | wc -c) bytes"

echo ""
echo "Testing Minimal mode..."
time swift build > /dev/null 2>&1
echo "Minimal JSON size: $(swift build 2>&1 | sbsift --minimal | wc -c) bytes"

echo ""
echo "5️⃣ Error Detection and Analysis"
echo "==============================="
echo "Testing error detection with intentional error..."
echo ""

# Create a file with an error
cat > Sources/sbsift-perf-test/WithError.swift << 'EOF'
import Foundation

// This file contains intentional errors for demonstration
let invalid: String = 42  // Type mismatch error

func unusedFunction() -> Int {
    return 42  // Unused function warning
}
EOF

echo "Running: swift build | sbsift --severity error"
swift build 2>&1 | sbsift --severity error

echo ""
echo "6️⃣ CI/CD Integration Pattern"
echo "============================"
echo "Demonstrating CI-friendly build analysis..."
echo ""

# Fix the error for CI example
rm Sources/sbsift-perf-test/WithError.swift

BUILD_RESULT=$(swift build 2>&1 | sbsift --compact)
SUCCESS=$(echo $BUILD_RESULT | jq -r '.ok' 2>/dev/null || echo "false")
DURATION=$(echo $BUILD_RESULT | jq -r '.time' 2>/dev/null || echo "unknown")

echo "Build result: $BUILD_RESULT"
echo "Success: $SUCCESS"
echo "Duration: ${DURATION}s"

if [[ "$SUCCESS" == "true" ]]; then
    echo "✅ Build succeeded in ${DURATION}s"
    exit 0
else
    echo "❌ Build failed"
    exit 1
fi

# Clean up
cd /tmp
rm -rf sbsift-perf-test