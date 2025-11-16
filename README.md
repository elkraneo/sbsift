# sbsift - Swift Build Context Filter

Context-efficient Swift build analysis tool for Claude agents and AI development workflows.

## Overview

sbsift is the third tool in the specialized sift family, completing the context efficiency trinity for Swift development. It converts verbose Swift build output into structured, minimal-context JSON.

## The Sift Family Context

# Package structure analysis:
swift package dump-package | spmsift     # SPM analysis (~1.5KB)

# Build compilation analysis:
swift build --target T | sbsift         # Build analysis (~500B)

# Xcode project analysis:
xcodebuild build -scheme S | xcsift     # Xcode analysis (~2KB)

sbsift's Role: Bridge between package analysis (spmsift) and Xcode integration (xcsift).

## Usage

### Basic Usage

```bash
# Analyze Swift build output
swift build --target MyTarget | sbsift

# Analyze test output
swift test | sbsift --format summary

# Include performance metrics
swift build | sbsift --metrics
```

### Output Formats

```bash
# JSON output (default)
swift build | sbsift

# Summary format (minimal)
swift build | sbsift --format summary

# Detailed format (includes diagnostics)
swift build | sbsift --format detailed
```

### Filtering by Severity

```bash
# Only show errors and critical issues
swift build | sbsift --severity error

# Show all issues including info
swift build | sbsift --severity info
```

## Output Examples

### Successful Build
```json
{
  "command": "build",
  "target": "ReadingLibrary",
  "success": true,
  "duration": 2.34,
  "errors": [],
  "warnings": [
    {
      "file": "Sources/ReadingLibrary/Feature.swift",
      "line": 42,
      "message": "unused variable 'result'",
      "type": "unused_variable"
    }
  ],
  "metrics": {
    "filesCompiled": 23,
    "linesCompiled": 1847,
    "compilationTime": 1.8,
    "linkingTime": 0.54
  },
  "timestamp": "2025-11-16T00:45:32Z"
}
```

### Failed Build
```json
{
  "command": "build",
  "target": "ArticleReader",
  "success": false,
  "duration": 1.2,
  "errors": [
    {
      "file": "Sources/ArticleReader/Core.swift",
      "line": 15,
      "column": 8,
      "message": "cannot convert value of type 'String' to expected type 'Int'",
      "type": "type_mismatch"
    }
  ],
  "warnings": [],
  "metrics": {
    "filesCompiled": 3,
    "compilationTime": 0.8,
    "linkingTime": 0
  },
  "timestamp": "2025-11-16T00:45:32Z"
}
```

## Performance

| Metric          | Before sbsift | After sbsift |
|-----------------|----------------|--------------|
| Output Size     | 10-20KB       | ~500B         |
| Context Usage   | High           | Minimal       |
| Parse Time      | N/A            | <50ms         |
| Error Detection | Manual         | Automated     |

## Requirements

- Swift 5.9+
- macOS 13.0+

## Installation

### From Source

```bash
git clone https://github.com/your-username/sbsift.git
cd sbsift
swift build -c release
cp .build/release/sbsift /usr/local/bin/
```

### Using Install Script

```bash
curl -sSL https://raw.githubusercontent.com/your-username/sbsift/main/install.sh | bash
```

## Features

- **Pipe-based interface** like spmsift/xcsift for seamless integration
- **Multi-command support**: build, test, run, package commands
- **Structured JSON output** for programmatic analysis
- **Context-optimized output** < 1KB for any build size
- **Error-aware** with detailed file/line/column information
- **Performance-focused** < 50ms parse time for any build size
- **Configurable output** formats and severity filtering
- **Built-in metrics** for compilation and linking performance

## Related Tools

- [spmsift](https://github.com/elkraneo/spmsift) - Swift Package Manager analysis
- [xcsift](https://github.com/ldomaradzki/xcsift) - Xcode build analysis

Together they provide complete Swift ecosystem analysis:
- **spmsift** → Package structure and dependencies
- **sbsift** → Build compilation and errors
- **xcsift** → Xcode project and integration

## Integration

Perfect for Smith skill SPM build analysis tools:

```bash
#!/bin/bash
# Enhanced SPM analysis
swift package dump-package 2>&1 | spmsift
swift build --target $TARGET 2>&1 | sbsift
```

## License

MIT License - see LICENSE file for details.

---

**sbsift**: Making Swift build analysis AI-friendly.# Workflow trigger test Sun Nov 16 03:15:44 CET 2025
