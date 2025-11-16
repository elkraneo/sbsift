import Foundation

public class SwiftBuildOutputParser {
    public init() {}

    public func parse(_ output: String) -> BuildAnalysis {
        let lines = output.components(separatedBy: .newlines)

        return BuildAnalysis(
            command: BuildCommandDetector.detectCommandType(from: output),
            target: BuildCommandDetector.extractTarget(from: output),
            success: BuildCommandDetector.determineSuccess(from: output),
            duration: BuildCommandDetector.extractDuration(from: output),
            errors: extractErrors(from: lines),
            warnings: extractWarnings(from: lines),
            metrics: extractMetrics(from: lines)
        )
    }

    // MARK: - Error Extraction
    private func extractErrors(from lines: [String]) -> [BuildError] {
        var errors: [BuildError] = []

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)

            if trimmed.lowercased().hasPrefix("error:") {
                let error = parseErrorLine(trimmed)
                errors.append(error)
            }
        }

        return errors
    }

    private func parseErrorLine(_ line: String) -> BuildError {
        // Pattern: error: message (file:line:column)
        let errorType = determineErrorType(from: line)
        let (file, lineNum, column, message) = extractErrorDetails(from: line)

        return BuildError(
            file: file,
            line: lineNum,
            column: column,
            message: message,
            type: errorType
        )
    }

    private func determineErrorType(from line: String) -> ErrorType {
        let lowercased = line.lowercased()

        if lowercased.contains("unresolved identifier") {
            return .unresolved
        } else if lowercased.contains("cannot convert") {
            return .conversion
        } else if lowercased.contains("link") || lowercased.contains("symbol") {
            return .linking
        } else if lowercased.contains("module") || lowercased.contains("import") {
            return .module
        } else if lowercased.contains("dependency") {
            return .dependency
        } else if lowercased.contains("unavailable") {
            return .unavailable
        } else if lowercased.contains("syntax") {
            return .syntax
        } else {
            return .type
        }
    }

    private func extractErrorDetails(from line: String) -> (file: String?, line: Int?, column: Int?, message: String) {
        // Remove "error:" prefix
        let messageStart = line.hasPrefix("error:") ? line.dropFirst(6).trimmingCharacters(in: .whitespacesAndNewlines) : line

        // Look for file:line:column pattern
        if let range = messageStart.range(of: #"([^:]+):(\d+):(\d+)$"#, options: .regularExpression) {
            let filePath = String(messageStart[..<range.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
            let lineNum = Int(messageStart[range].components(separatedBy: ":")[1]) ?? 0
            let columnNum = Int(messageStart[range].components(separatedBy: ":")[2]) ?? 0

            // Extract message before the file reference
            let messageWithoutLocation = String(messageStart[..<range.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)

            return (filePath, lineNum, columnNum, messageWithoutLocation)
        }

        // Look for file:line pattern
        if let range = messageStart.range(of: #"([^:]+):(\d+)$"#, options: .regularExpression) {
            let filePath = String(messageStart[..<range.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
            let lineNum = Int(messageStart[range].components(separatedBy: ":")[1]) ?? 0

            // Extract message before the file reference
            let messageWithoutLocation = String(messageStart[..<range.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)

            return (filePath, lineNum, nil, messageWithoutLocation)
        }

        // No location found, return just the message
        return (nil, nil, nil, String(messageStart))
    }

    // MARK: - Warning Extraction
    private func extractWarnings(from lines: [String]) -> [BuildWarning] {
        var warnings: [BuildWarning] = []

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)

            if trimmed.lowercased().hasPrefix("warning:") {
                let warning = parseWarningLine(trimmed)
                warnings.append(warning)
            }
        }

        return warnings
    }

    private func parseWarningLine(_ line: String) -> BuildWarning {
        let warningType = determineWarningType(from: line)
        let (file, lineNum, column, message) = extractWarningDetails(from: line)

        return BuildWarning(
            file: file,
            line: lineNum,
            column: column,
            message: message,
            type: warningType
        )
    }

    private func determineWarningType(from line: String) -> WarningType {
        let lowercased = line.lowercased()

        if lowercased.contains("unused") && lowercased.contains("variable") {
            return .unusedVariable
        } else if lowercased.contains("unused") && (lowercased.contains("let") || lowercased.contains("constant")) {
            return .unusedConstant
        } else if lowercased.contains("unused") && lowercased.contains("import") {
            return .unusedImport
        } else if lowercased.contains("deprecated") {
            return .deprecated
        } else if lowercased.contains("reference to var") {
            return .reference
        } else if lowercased.contains("implicit self") {
            return .implicitSelf
        } else {
            return .unknown
        }
    }

    private func extractWarningDetails(from line: String) -> (file: String?, line: Int?, column: Int?, message: String) {
        // Same logic as error details extraction
        return extractErrorDetails(from: line)
    }

    // MARK: - Metrics Extraction
    private func extractMetrics(from lines: [String]) -> BuildMetrics {
        var filesCompiled = 0
        let linesCompiled = 0  // Note: Could implement line counting in future
        var compilationTime: TimeInterval = 0.0
        var linkingTime: TimeInterval = 0.0
        var modulesLinked = 0

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)

            // Extract files compiled
            if trimmed.contains("Compile Swift Module") {
                if let range = trimmed.range(of: #"\\((\d+) sources?"#, options: .regularExpression) {
                    filesCompiled = Int(trimmed[range].dropFirst().dropLast().dropLast()) ?? 0
                }
            }

            // Extract compilation time
            if trimmed.contains("Compile Swift Module") && trimmed.contains("s)") {
                if let range = trimmed.range(of: #"\\(([0-9.]+)s\\)"#, options: .regularExpression) {
                    let timeString = String(trimmed[range].dropFirst().dropLast().dropLast())
                    compilationTime = TimeInterval(timeString) ?? 0.0
                }
            }

            // Extract linking time
            if trimmed.contains("Linking") && trimmed.contains("s)") {
                if let range = trimmed.range(of: #"\\(([0-9.]+)s\\)"#, options: .regularExpression) {
                    let timeString = String(trimmed[range].dropFirst().dropLast().dropLast())
                    linkingTime = TimeInterval(timeString) ?? 0.0
                }
            }

            // Count modules linked
            if trimmed.contains("Linking") && trimmed.contains(".build") {
                modulesLinked += 1
            }
        }

        return BuildMetrics(
            filesCompiled: filesCompiled,
            linesCompiled: linesCompiled,
            compilationTime: compilationTime,
            linkingTime: linkingTime,
            modulesLinked: modulesLinked
        )
    }
}