import ArgumentParser
import Foundation

@main
struct SBSift: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Context-efficient Swift build analysis tool",
        discussion: """
        sbsift converts verbose Swift build output into structured,
        minimal-context JSON designed for Claude agents and AI development workflows.

        Examples:
          swift build --target MyTarget | sbsift
          swift test | sbsift --format summary
          swift run | sbsift --metrics
        """,
        version: "1.0.0"
    )

    @Option(name: .shortAndLong, help: "Output format (json, summary, detailed)")
    var format: OutputFormat = .json

    @Option(name: .long, help: "Minimum issue severity to include (info, warning, error, critical)")
    var severity: Severity = .info

    @Flag(name: .shortAndLong, help: "Include raw output for debugging")
    var verbose: Bool = false

    @Flag(name: .long, help: "Enable performance metrics")
    var metrics: Bool = false

    @Flag(name: .long, help: "Compact output mode (60-70% size reduction)")
    var compact: Bool = false

    @Flag(name: .long, help: "Minimal output mode (85%+ size reduction)")
    var minimal: Bool = false

    @Option(name: .long, help: "Monitor build progress with timeout in seconds (0 for no timeout)")
    var monitor: Int = 0

    @Flag(name: .long, help: "Show file-level compilation timing")
    var fileTiming: Bool = false

    @Option(name: .long, help: "Show top N slowest files (default: 5)")
    var bottleneck: Int = 0

    mutating func run() throws {
        // Read from stdin if piped, otherwise exit with help
        if isatty(STDIN_FILENO) != 0 {
            print("sbsift: No input detected. Pipe Swift build output to sbsift.")
            print("Usage: swift build | sbsift")
            throw ExitCode.failure
        }

        // Handle monitoring mode (streaming input with timeout)
        if monitor > 0 {
            try runWithMonitoring()
            return
        }

        let input = FileHandle.standardInput.readDataToEndOfFile()
        let output = String(data: input, encoding: .utf8) ?? ""

        guard !output.isEmpty else {
            print("{\"error\": \"No input received\"}")
            throw ExitCode.failure
        }

        let result = parseBuildOutput(output)

        // Filter issues by severity
        let filteredIssues = filterIssues(result.errors + result.warnings, minSeverity: severity)

        var finalResult = result
        if severity != .info {
            finalResult = BuildAnalysis(
                command: result.command,
                target: result.target,
                success: result.success,
                duration: result.duration,
                errors: filteredIssues.compactMap { $0 as? BuildError },
                warnings: filteredIssues.compactMap { $0 as? BuildWarning },
                metrics: result.metrics,
                timestamp: result.timestamp
            )
        }

        // Handle file timing output separately
        if fileTiming || bottleneck > 0 {
            try outputFileTiming(finalResult)
        }

        // Output based on format and mode
        switch format {
        case .json:
            if minimal {
                try outputMinimal(finalResult)
            } else if compact {
                try outputCompact(finalResult)
            } else {
                try outputJSON(finalResult)
            }
        case .summary:
            try outputSummary(finalResult)
        case .detailed:
            try outputDetailed(finalResult)
        }

        // Always return success for analysis (only tool failures should exit 1)
        throw ExitCode.success
    }

    private func runWithMonitoring() throws {
        let timeout = TimeInterval(monitor)
        var outputBuffer = ""
        var lastProgressTime = Date()
        var lineCount = 0

        print("{\"status\": \"monitoring\", \"timeout\": \(timeout)}", terminator: "\n")
        fflush(stdout)

        // Set up signal handling for timeout
        let startTime = Date()

        // Read input line by line for real-time monitoring
        let handle = FileHandle.standardInput
        let data = NSMutableData()

        while true {
            let availableData = handle.availableData
            if availableData.isEmpty { break }

            data.append(availableData)
            if let string = String(data: data as Data, encoding: .utf8) {
                let lines = string.components(separatedBy: .newlines)

                // Process new lines
                for line in lines.dropLast() { // Last line might be incomplete
                    outputBuffer += line + "\n"
                    lineCount += 1

                    // Check for key indicators
                    if line.contains("Compiling") {
                        let now = Date()
                        if now.timeIntervalSince(lastProgressTime) > 5 {
                            print("{\"status\": \"progress\", \"message\": \"Compiling...\", \"lines\": \(lineCount)}", terminator: "\n")
                            fflush(stdout)
                            lastProgressTime = now
                        }
                    }

                    if line.contains("error:") {
                        print("{\"status\": \"error_detected\", \"line\": \"\(line.replacingOccurrences(of: "\"", with: "\\\""))\"}", terminator: "\n")
                        fflush(stdout)
                    }

                    // Check for timeout
                    if Date().timeIntervalSince(startTime) > timeout {
                        print("{\"status\": \"timeout\", \"message\": \"Build timeout after \(timeout) seconds\", \"lines_processed\": \(lineCount)}", terminator: "\n")
                        fflush(stdout)
                        throw ExitCode.failure
                    }
                }
            }

            // Small delay to prevent busy waiting
            usleep(100000) // 0.1 seconds
        }

        // Final processing
        if let finalString = String(data: data as Data, encoding: .utf8) {
            outputBuffer = finalString
        }

        guard !outputBuffer.isEmpty else {
            print("{\"error\": \"No input received\"}")
            throw ExitCode.failure
        }

        // Parse and output final result
        let result = parseBuildOutput(outputBuffer)

        // Filter issues by severity
        let filteredIssues = filterIssues(result.errors + result.warnings, minSeverity: severity)

        var finalResult = result
        if severity != .info {
            finalResult = BuildAnalysis(
                command: result.command,
                target: result.target,
                success: result.success,
                duration: result.duration,
                errors: filteredIssues.compactMap { $0 as? BuildError },
                warnings: filteredIssues.compactMap { $0 as? BuildWarning },
                metrics: result.metrics,
                timestamp: result.timestamp
            )
        }

        // Output final result with monitoring metadata
        print("{\"status\": \"completed\", \"result\": ", terminator: "")

        if minimal {
            try outputMinimal(finalResult)
        } else if compact {
            try outputCompact(finalResult)
        } else {
            try outputJSON(finalResult)
        }

        print("}", terminator: "")
    }

    private func outputFileTiming(_ result: BuildAnalysis) throws {
        guard !result.metrics.fileTimings.isEmpty else {
            print("{\"file_timing\": \"No file timing data available\"}")
            return
        }

        let sortedTimings = result.metrics.fileTimings.sorted(by: >)
        var timingData: [String: Any] = [
            "total_files": result.metrics.fileTimings.count,
            "total_time": result.metrics.compilationTime,
            "average_time": result.metrics.fileTimings.isEmpty ? 0 : result.metrics.compilationTime / Double(result.metrics.fileTimings.count)
        ]

        if bottleneck > 0 {
            let topFiles = Array(sortedTimings.prefix(bottleneck))
            timingData["bottlenecks"] = topFiles.map { timing in
                [
                    "file": URL(fileURLWithPath: timing.file).lastPathComponent,
                    "path": timing.file,
                    "duration": timing.duration,
                    "lines": timing.linesCompiled,
                    "percentage": result.metrics.compilationTime > 0 ? (timing.duration / result.metrics.compilationTime) * 100 : 0
                ]
            }
        } else {
            timingData["files"] = sortedTimings.map { timing in
                [
                    "file": URL(fileURLWithPath: timing.file).lastPathComponent,
                    "path": timing.file,
                    "duration": timing.duration,
                    "lines": timing.linesCompiled
                ]
            }
        }

        let jsonData = try JSONSerialization.data(withJSONObject: ["file_timing": timingData], options: .prettyPrinted)
        if let jsonString = String(data: jsonData, encoding: .utf8) {
            print(jsonString)
        }
    }

    private func parseBuildOutput(_ input: String) -> BuildAnalysis {
        let parser = SwiftBuildOutputParser()
        return parser.parse(input)
    }

    private func outputJSON(_ result: BuildAnalysis) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        encoder.dateEncodingStrategy = .iso8601

        let jsonData = try encoder.encode(result)
        if let jsonString = String(data: jsonData, encoding: .utf8) {
            print(jsonString)
        }
    }

    private func outputSummary(_ result: BuildAnalysis) throws {
        var summary: [String: Any] = [
            "command": result.command.rawValue,
            "success": result.success,
            "errors": result.errors.count,
            "warnings": result.warnings.count
        ]

        if let target = result.target {
            summary["target"] = target
        }

        if let duration = result.duration {
            summary["duration"] = duration
        }

        if result.metrics.filesCompiled > 0 {
            summary["filesCompiled"] = result.metrics.filesCompiled
        }

        let jsonData = try JSONSerialization.data(withJSONObject: summary, options: .prettyPrinted)
        if let jsonString = String(data: jsonData, encoding: .utf8) {
            print(jsonString)
        }
    }

    private func outputDetailed(_ result: BuildAnalysis) throws {
        try outputJSON(result)
    }

    private func outputCompact(_ result: BuildAnalysis) throws {
        var compact: [String: Any] = [
            "cmd": result.command.rawValue.prefix(1),
            "ok": result.success,
            "time": result.duration ?? 0,
            "errs": result.errors.count,
            "warns": result.warnings.count
        ]

        if let target = result.target {
            compact["tgt"] = target
        }

        // Add key metrics only if they have meaningful values
        if result.metrics.filesCompiled > 0 {
            compact["files"] = result.metrics.filesCompiled
        }
        if result.metrics.compilationTime > 0 {
            compact["compile"] = result.metrics.compilationTime
        }

        // Add slowest files if requested
        if bottleneck > 0 && !result.metrics.fileTimings.isEmpty {
            let slowestFiles = Array(result.metrics.fileTimings.sorted(by: >).prefix(bottleneck))
            compact["slowest"] = slowestFiles.map { ["f": URL(fileURLWithPath: $0.file).lastPathComponent, "t": $0.duration] }
        }

        let jsonData = try JSONSerialization.data(withJSONObject: compact, options: [])
        if let jsonString = String(data: jsonData, encoding: .utf8) {
            print(jsonString)
        }
    }

    private func outputMinimal(_ result: BuildAnalysis) throws {
        var minimal: [String: Any] = [
            "c": result.command.rawValue.prefix(1),
            "s": result.success ? 1 : 0,
            "e": result.errors.count,
            "w": result.warnings.count
        ]

        // Only add non-zero values
        if let duration = result.duration, duration > 0 {
            minimal["t"] = duration
        }
        if result.metrics.filesCompiled > 0 {
            minimal["f"] = result.metrics.filesCompiled
        }

        // Add target if not empty
        if let target = result.target, !target.isEmpty {
            minimal["tg"] = target
        }

        let jsonData = try JSONSerialization.data(withJSONObject: minimal, options: [])
        if let jsonString = String(data: jsonData, encoding: .utf8) {
            print(jsonString)
        }
    }

    private func filterIssues(_ issues: [Any], minSeverity: Severity) -> [Any] {
        let severityOrder: [Severity] = [.info, .warning, .error, .critical]
        guard let minIndex = severityOrder.firstIndex(of: minSeverity) else {
            return issues
        }

        return issues.filter { issue in
            if let error = issue as? BuildError {
                guard let issueIndex = severityOrder.firstIndex(of: error.severity) else { return false }
                return issueIndex >= minIndex
            } else if let warning = issue as? BuildWarning {
                guard let issueIndex = severityOrder.firstIndex(of: warning.severity) else { return false }
                return issueIndex >= minIndex
            }
            return false
        }
    }
}

// MARK: - Severity Extensions
extension BuildError {
    var severity: Severity {
        switch type {
        case .syntax, .linking, .module:
            return .error
        case .type, .conversion, .dependency:
            return .error
        case .unavailable:
            return .warning
        case .unresolved, .unknown:
            return .error
        }
    }
}

extension BuildWarning {
    var severity: Severity {
        switch type {
        case .unusedVariable, .unusedConstant, .unusedImport:
            return .info
        case .deprecated:
            return .warning
        case .reference, .implicitSelf:
            return .warning
        case .unknown:
            return .info
        }
    }
}
