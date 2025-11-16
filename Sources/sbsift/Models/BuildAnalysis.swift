import Foundation
import ArgumentParser

// MARK: - Core Output Models
public struct BuildAnalysis: Codable {
    public let command: BuildCommandType
    public let target: String?
    public let success: Bool
    public let duration: TimeInterval?
    public let errors: [BuildError]
    public let warnings: [BuildWarning]
    public let metrics: BuildMetrics
    public let timestamp: String

    public init(
        command: BuildCommandType,
        target: String? = nil,
        success: Bool,
        duration: TimeInterval? = nil,
        errors: [BuildError] = [],
        warnings: [BuildWarning] = [],
        metrics: BuildMetrics = BuildMetrics(),
        timestamp: String = ISO8601DateFormatter().string(from: Date())
    ) {
        self.command = command
        self.target = target
        self.success = success
        self.duration = duration
        self.errors = errors
        self.warnings = warnings
        self.metrics = metrics
        self.timestamp = timestamp
    }
}

public struct BuildError: Codable {
    public let file: String?
    public let line: Int?
    public let column: Int?
    public let message: String
    public let type: ErrorType

    public init(file: String? = nil, line: Int? = nil, column: Int? = nil, message: String, type: ErrorType) {
        self.file = file
        self.line = line
        self.column = column
        self.message = message
        self.type = type
    }
}

public struct BuildWarning: Codable {
    public let file: String?
    public let line: Int?
    public let column: Int?
    public let message: String
    public let type: WarningType

    public init(file: String? = nil, line: Int? = nil, column: Int? = nil, message: String, type: WarningType) {
        self.file = file
        self.line = line
        self.column = column
        self.message = message
        self.type = type
    }
}

public struct BuildMetrics: Codable {
    public let filesCompiled: Int
    public let linesCompiled: Int
    public let compilationTime: TimeInterval
    public let linkingTime: TimeInterval
    public let modulesLinked: Int

    public init(
        filesCompiled: Int = 0,
        linesCompiled: Int = 0,
        compilationTime: TimeInterval = 0.0,
        linkingTime: TimeInterval = 0.0,
        modulesLinked: Int = 0
    ) {
        self.filesCompiled = filesCompiled
        self.linesCompiled = linesCompiled
        self.compilationTime = compilationTime
        self.linkingTime = linkingTime
        self.modulesLinked = modulesLinked
    }
}

// MARK: - Enums
public enum BuildCommandType: String, Codable, CaseIterable {
    case build = "build"
    case test = "test"
    case run = "run"
    case package = "package"
    case unknown = "unknown"
}

public enum ErrorType: String, Codable, CaseIterable {
    case syntax = "syntax_error"
    case type = "type_mismatch"
    case linking = "link_error"
    case dependency = "dependency_error"
    case module = "module_not_found"
    case unavailable = "unavailable_api"
    case unresolved = "unresolved_identifier"
    case conversion = "conversion_error"
    case unknown = "unknown"
}

public enum WarningType: String, Codable, CaseIterable {
    case unusedVariable = "unused_variable"
    case unusedConstant = "unused_constant"
    case unusedImport = "unused_import"
    case deprecated = "deprecated"
    case reference = "closure_reference"
    case implicitSelf = "implicit_self"
    case unknown = "unknown"
}

// MARK: - Output Format
public enum OutputFormat: String, CaseIterable {
    case json = "json"
    case summary = "summary"
    case detailed = "detailed"
}

extension OutputFormat: ExpressibleByArgument {}

public enum Severity: String, Codable, CaseIterable {
    case info = "info"
    case warning = "warning"
    case error = "error"
    case critical = "critical"
}

extension Severity: ExpressibleByArgument {}