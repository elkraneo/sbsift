import Testing
@testable import sbsift

@Suite("SBSift Core Tests")
struct SBSiftTests {
    @Test("Build command detector correctly identifies different Swift commands")
    func buildCommandDetector() {
        // Test build detection
        let buildOutput = """
        Building for debug...
        Compiling Swift module 'MyTarget'
        Linking ./.build/debug/MyTarget
        Build complete!
        """
        #expect(BuildCommandDetector.detectCommandType(from: buildOutput) == .build)

        // Test detection
        let testOutput = """
        Test Suite 'MyTargetTests' started at 2025-11-16 01:45:32.123
        Test Case 'testExample' started
        Test Case 'testExample' passed (0.001 seconds)
        Test Suite 'MyTargetTests' passed at 2025-11-16 01:45:32.456
        """
        #expect(BuildCommandDetector.detectCommandType(from: testOutput) == .test)

        // Test run detection
        let runOutput = """
        Building for debug...
        Linking ./.build/debug/MyTarget
        Build complete!
        Running MyTarget...
        Hello, world!
        """
        #expect(BuildCommandDetector.detectCommandType(from: runOutput) == .run)
    }

    @Test("Error detection correctly identifies build failures")
    func errorDetection() {
        let errorOutput = """
        Compiling Swift module 'MyTarget'
        Sources/MyTarget/main.swift:5:8: error: cannot convert value of type 'String' to expected type 'Int'
        let x: String = "hello"
        let y: Int = x
        """
        #expect(BuildCommandDetector.hasErrorOutput(errorOutput))
        #expect(!BuildCommandDetector.determineSuccess(from: errorOutput))
    }

    @Test("Success detection correctly identifies successful builds")
    func successDetection() {
        let successOutput = """
        Building for debug...
        Compiling Swift module 'MyTarget' (3 sources)
        Linking ./.build/debug/MyTarget
        Build complete!
        """
        #expect(!BuildCommandDetector.hasErrorOutput(successOutput))
        #expect(BuildCommandDetector.determineSuccess(from: successOutput))
    }
}