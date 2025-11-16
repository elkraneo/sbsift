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

    mutating func run() throws {
        // Read from stdin if piped, otherwise exit with help
        if isatty(STDIN_FILENO) != 0 {
            print("sbsift: No input detected. Pipe Swift build output to sbsift.")
            print("Usage: swift build | sbsift")
            throw ExitCode.failure
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

        // Output based on format
        switch format {
        case .json:
            try outputJSON(finalResult)
        case .summary:
            try outputSummary(finalResult)
        case .detailed:
            try outputDetailed(finalResult)
        }

        // Always return success for analysis (only tool failures should exit 1)
        throw ExitCode.success
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
