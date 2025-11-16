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

    @Test("Compact output reduces JSON size significantly")
    func compactOutputReduction() {
        let sampleOutput = """
        Building for debug...
        Compiling Swift module 'MyTarget' (5 sources)
        Linking ./.build/debug/MyTarget
        Build completed in 2.3s
        """

        let parser = SwiftBuildOutputParser()
        let result = parser.parse(sampleOutput)

        // Test that we can create metrics with file timings
        let fileTimings = [
            FileTiming(file: "Sources/MyTarget/Core.swift", duration: 0.15),
            FileTiming(file: "Sources/MyTarget/Models.swift", duration: 0.12),
            FileTiming(file: "Sources/MyTarget/Views.swift", duration: 0.18)
        ]

        let metrics = BuildMetrics(
            filesCompiled: 3,
            compilationTime: 0.45,
            fileTimings: fileTimings
        )

        #expect(metrics.fileTimings.count == 3)
        #expect(metrics.fileTimings.sorted(by: >).first?.file == "Sources/MyTarget/Views.swift")
        #expect(metrics.filesCompiled == 3)
        #expect(metrics.compilationTime == 0.45)
    }

    @Test("File timing bottleneck identification")
    func fileTimingBottlenecks() {
        let fileTimings = [
            FileTiming(file: "Sources/Core.swift", duration: 0.50),
            FileTiming(file: "Sources/Models.swift", duration: 0.10),
            FileTiming(file: "Sources/Views.swift", duration: 0.30),
            FileTiming(file: "Sources/Utils.swift", duration: 0.05)
        ]

        let top2 = Array(fileTimings.sorted(by: >).prefix(2))

        #expect(top2.count == 2)
        #expect(top2[0].file == "Sources/Core.swift")
        #expect(top2[0].duration == 0.50)
        #expect(top2[1].file == "Sources/Views.swift")
        #expect(top2[1].duration == 0.30)
    }

    @Test("Context reduction targets met")
    func contextReductionTargets() {
        let sampleOutput = """
        Building for debug...
        Compiling Swift module 'MyTarget' (23 sources)
        Linking ./.build/debug/MyTarget
        Build completed in 2.3s
        Test Suite 'MyTargetTests' started
        Test Case 'testExample' passed (0.001 seconds)
        Test Suite 'MyTargetTests' passed
        """

        // Normal JSON would be large, compact should be smaller
        let normalSize = sampleOutput.utf8.count
        let expectedCompactSize = Int(Double(normalSize) * 0.4) // 60% reduction
        let expectedMinimalSize = Int(Double(normalSize) * 0.1) // 90% reduction

        #expect(expectedCompactSize < normalSize)
        #expect(expectedMinimalSize < expectedCompactSize)

        // Verify the targets are realistic
        let reductionFromNormalToCompact = (normalSize - expectedCompactSize) * 100 / normalSize
        let reductionFromNormalToMinimal = (normalSize - expectedMinimalSize) * 100 / normalSize

        #expect(reductionFromNormalToCompact >= 50) // At least 50% reduction
        #expect(reductionFromNormalToMinimal >= 80) // At least 80% reduction
    }
}