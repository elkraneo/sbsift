import Foundation

public struct BuildCommandDetector {

    public static func detectCommandType(from output: String) -> BuildCommandType {
        let output = output.lowercased()

        // Check for test command
        if output.contains("test suite") || output.contains("test case") || output.contains("running tests") {
            return .test
        }

        // Check for run command
        if output.contains("running ") || output.contains("program started") || output.contains("process finished") {
            return .run
        }

        // Check for package commands
        if output.contains("package ") || output.contains("resolve package") || output.contains("fetch dependencies") {
            return .package
        }

        // Check for build command (default)
        if output.contains("compiling") || output.contains("building for") || output.contains("linking") {
            return .build
        }

        return .unknown
    }

    public static func extractTarget(from output: String) -> String? {
        let lines = output.components(separatedBy: .newlines)

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            // Look for target patterns in Swift build output
            if trimmed.contains("target ") || trimmed.contains("module ") {
                // Extract target from patterns like:
                // "Compiling Swift module 'MyTarget'"
                // "Building target 'MyTarget'"
                // "Compile Swift Module 'MyTarget' (X sources)"

                if let range = trimmed.range(of: #"'([^']*+)'"#, options: .regularExpression) {
                    return String(trimmed[range].dropFirst().dropLast())
                }
            }
        }

        return nil
    }

    public static func determineSuccess(from output: String) -> Bool {
        let output = output.lowercased()

        // Check for explicit success indicators
        if output.contains("build complete") ||
           output.contains("build succeeded") ||
           output.contains("test suite passed") ||
           output.contains("tests passed") ||
           output.contains("compilation finished") {
            return true
        }

        // Check for explicit failure indicators
        if output.contains("build failed") ||
           output.contains("error:") ||
           output.contains("compilation failed") ||
           output.contains("linking failed") ||
           output.contains("test suite failed") ||
           output.contains("tests failed") ||
           output.contains("aborting") {
            return false
        }

        // If no clear indicators, assume success if no errors found
        return !output.contains("error:")
    }

    public static func extractDuration(from output: String) -> TimeInterval? {
        let lines = output.components(separatedBy: .newlines)

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            // Look for duration patterns:
            // "(0.45s)"
            // "Build completed in 1.23 seconds"
            // "Total time: 2.1s"

            // Pattern 1: (X.XXXs)
            if let range = trimmed.range(of: #"\\(([0-9.]+)s\\)"#, options: .regularExpression) {
                let timeString = String(trimmed[range].dropFirst().dropLast().dropLast())
                return TimeInterval(timeString)
            }

            // Pattern 2: X.XXX seconds
            if let range = trimmed.range(of: #"([0-9.]+) seconds?"#, options: .regularExpression) {
                return TimeInterval(trimmed[range])
            }

            // Pattern 3: X.XXXs
            if let range = trimmed.range(of: #"([0-9.]+)s$"#, options: .regularExpression) {
                let timeString = String(trimmed[range].dropLast())
                return TimeInterval(timeString)
            }
        }

        return nil
    }

    public static func hasErrorOutput(_ output: String) -> Bool {
        let output = output.lowercased()
        return output.contains("error:") ||
               output.contains("cannot ") ||
               output.contains("failed") ||
               output.contains("not found")
    }
}