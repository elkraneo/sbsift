import Testing
@testable import sbsift

@Suite("Build Output Parser Tests")
struct BuildOutputParserTests {
    let parser = SwiftBuildOutputParser()

    @Test("Parser correctly handles successful build output")
    func parseSuccessfulBuild() {
        let input = """
        Building for debug...
        Compiling Swift module 'ReadingLibrary' (23 sources)
        Linking ./.build/debug/ReadingLibrary
        Build complete! (0.45s)
        """

        let result = parser.parse(input)

        #expect(result.command == .build)
        #expect(result.success)
        #expect(result.target == "ReadingLibrary")
        #expect(result.duration == 0.45)
        #expect(result.errors.count == 0)
        #expect(result.metrics.filesCompiled == 23)
    }

    @Test("Parser correctly extracts errors with file and line information")
    func parseBuildWithError() {
        let input = """
        Compiling Swift module 'ArticleReader' (3 sources)
        Sources/ArticleReader/Core.swift:15:8: error: cannot convert value of type 'String' to expected type 'Int'
        let number: Int = text
        ^
        Linking failed
        """

        let result = parser.parse(input)

        #expect(result.command == .build)
        #expect(!result.success)
        #expect(result.errors.count == 1)

        let error = result.errors.first!
        #expect(error.file == "Sources/ArticleReader/Core.swift")
        #expect(error.line == 15)
        #expect(error.column == 8)
        #expect(error.type == .conversion)
        #expect(error.message.contains("cannot convert value of type"))
    }

    @Test("Parser correctly extracts warnings")
    func parseBuildWithWarnings() {
        let input = """
        Compiling Swift module 'ReadingLibrary' (23 sources)
        Sources/ReadingLibrary/Feature.swift:42:7: warning: variable 'result' was written to, but never read
        var result = processData()
        ^
        Build complete! (1.23s)
        """

        let result = parser.parse(input)

        #expect(result.success)
        #expect(result.warnings.count == 1)

        let warning = result.warnings.first!
        #expect(warning.file == "Sources/ReadingLibrary/Feature.swift")
        #expect(warning.line == 42)
        #expect(warning.type == .unusedVariable)
        #expect(warning.message.contains("variable 'result' was written to"))
    }

    @Test("Parser handles test run output")
    func parseTestOutput() {
        let input = """
        Test Suite 'ReadingLibraryTests' started at 2025-11-16 01:45:32.123
        Test Case 'testReadingSuccess' started
        Test Case 'testReadingSuccess' passed (0.001 seconds)
        Test Case 'testReadingFailure' started
        Test Case 'testReadingFailure' failed (0.002 seconds)
        Test Suite 'ReadingLibraryTests' failed at 2025-11-16 01:45:32.456
        """

        let result = parser.parse(input)

        #expect(result.command == .test)
        #expect(!result.success)
    }

    @Test("Parser extracts performance metrics")
    func parseWithMetrics() {
        let input = """
        Building for debug...
        Compile Swift Module 'ReadingLibrary' (23 sources) (1.8s)
        Linking ./.build/debug/ReadingLibrary (0.54s)
        Build complete! (2.34s)
        """

        let result = parser.parse(input)

        #expect(result.metrics.filesCompiled == 23)
        #expect(result.metrics.compilationTime == 1.8)
        #expect(result.metrics.linkingTime == 0.54)
        #expect(result.metrics.modulesLinked == 1)
    }

    @Test("Parser handles unknown input gracefully")
    func parseUnknownInput() {
        let input = """
        Some unexpected output
        That doesn't look like a Swift build
        """
        let result = parser.parse(input)

        #expect(result.command == .unknown)
        #expect(result.success) // Default to success for unknown input
    }
}