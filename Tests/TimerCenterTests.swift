import XCTest
@testable import CulinaChef

@MainActor
final class TimerCenterTests: XCTestCase {
    
    var sut: TimerCenter!
    
    override func setUp() async throws {
        try await super.setUp()
        sut = TimerCenter()
    }
    
    override func tearDown() async throws {
        sut = nil
        try await super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func testInitialization() {
        XCTAssertNotNil(sut)
        XCTAssertTrue(sut.timers.isEmpty)
    }
    
    // MARK: - Start Timer Tests
    
    func testStartTimer_AddsTimerToList() {
        // Given
        XCTAssertEqual(sut.timers.count, 0)
        
        // When
        sut.start(minutes: 5, label: "Test Timer")
        
        // Then
        XCTAssertEqual(sut.timers.count, 1)
        XCTAssertEqual(sut.timers.first?.label, "Test Timer")
        XCTAssertEqual(sut.timers.first?.baseMinutes, 5)
        XCTAssertEqual(sut.timers.first?.remaining, 300) // 5 minutes = 300 seconds
    }
    
    func testStartTimer_MultipleTimers() {
        // When
        sut.start(minutes: 5, label: "Timer 1")
        sut.start(minutes: 10, label: "Timer 2")
        sut.start(minutes: 15, label: "Timer 3")
        
        // Then
        XCTAssertEqual(sut.timers.count, 3)
        XCTAssertEqual(sut.timers[0].label, "Timer 1")
        XCTAssertEqual(sut.timers[1].label, "Timer 2")
        XCTAssertEqual(sut.timers[2].label, "Timer 3")
    }
    
    // MARK: - Remove Timer Tests
    
    func testRemoveTimer_RemovesFromList() {
        // Given
        sut.start(minutes: 5, label: "Timer 1")
        sut.start(minutes: 10, label: "Timer 2")
        XCTAssertEqual(sut.timers.count, 2)
        
        let timerToRemove = sut.timers[0]
        
        // When
        sut.remove(timer: timerToRemove)
        
        // Then
        XCTAssertEqual(sut.timers.count, 1)
        XCTAssertEqual(sut.timers.first?.label, "Timer 2")
    }
    
    func testRemoveTimer_RemovesCorrectTimer() {
        // Given
        sut.start(minutes: 5, label: "Timer 1")
        sut.start(minutes: 10, label: "Timer 2")
        sut.start(minutes: 15, label: "Timer 3")
        
        let timerToRemove = sut.timers[1] // Remove middle timer
        
        // When
        sut.remove(timer: timerToRemove)
        
        // Then
        XCTAssertEqual(sut.timers.count, 2)
        XCTAssertEqual(sut.timers[0].label, "Timer 1")
        XCTAssertEqual(sut.timers[1].label, "Timer 3")
    }
    
    func testRemoveTimer_LastTimer_EmptiesList() {
        // Given
        sut.start(minutes: 5, label: "Timer 1")
        let timer = sut.timers[0]
        
        // When
        sut.remove(timer: timer)
        
        // Then
        XCTAssertTrue(sut.timers.isEmpty)
    }
}

// MARK: - RunningTimer Tests

@MainActor
final class RunningTimerTests: XCTestCase {
    
    // MARK: - Initialization Tests
    
    func testRunningTimerInitialization() {
        // When
        let timer = RunningTimer(minutes: 5, label: "Test Timer")
        
        // Then
        XCTAssertNotNil(timer.id)
        XCTAssertEqual(timer.label, "Test Timer")
        XCTAssertEqual(timer.baseMinutes, 5)
        XCTAssertEqual(timer.remaining, 300) // 5 * 60
        XCTAssertTrue(timer.running)
    }
    
    func testRunningTimerInitialization_DifferentDurations() {
        // When
        let timer1 = RunningTimer(minutes: 1, label: "1 min")
        let timer10 = RunningTimer(minutes: 10, label: "10 min")
        let timer30 = RunningTimer(minutes: 30, label: "30 min")
        
        // Then
        XCTAssertEqual(timer1.remaining, 60)
        XCTAssertEqual(timer10.remaining, 600)
        XCTAssertEqual(timer30.remaining, 1800)
    }
    
    func testRunningTimer_HasUniqueIDs() {
        // When
        let timer1 = RunningTimer(minutes: 5, label: "Timer 1")
        let timer2 = RunningTimer(minutes: 5, label: "Timer 2")
        
        // Then
        XCTAssertNotEqual(timer1.id, timer2.id)
    }
    
    // MARK: - Reset Tests
    
    func testReset_ResetsToOriginalDuration() async {
        // Given
        let timer = RunningTimer(minutes: 5, label: "Test")
        
        // Simulate some time passing
        await Task.yield()
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        // When
        timer.reset()
        
        // Then
        XCTAssertEqual(timer.remaining, 300)
        XCTAssertTrue(timer.running)
    }
    
    func testReset_RestoresRunningState() {
        // Given
        let timer = RunningTimer(minutes: 5, label: "Test")
        timer.running = false
        
        // When
        timer.reset()
        
        // Then
        XCTAssertTrue(timer.running)
    }
    
    // MARK: - Running State Tests
    
    func testTimer_StartsInRunningState() {
        let timer = RunningTimer(minutes: 5, label: "Test")
        XCTAssertTrue(timer.running)
    }
    
    func testTimer_CanBePaused() {
        // Given
        let timer = RunningTimer(minutes: 5, label: "Test")
        
        // When
        timer.running = false
        
        // Then
        XCTAssertFalse(timer.running)
    }
    
    func testTimer_CanBeResumed() {
        // Given
        let timer = RunningTimer(minutes: 5, label: "Test")
        timer.running = false
        
        // When
        timer.running = true
        
        // Then
        XCTAssertTrue(timer.running)
    }
    
    // MARK: - Timer Countdown Tests
    
    func testTimer_CountsDown() async {
        // Given
        let timer = RunningTimer(minutes: 1, label: "Test")
        let initialRemaining = timer.remaining
        
        // When: Wait for timer to tick (slightly more than 1 second)
        try? await Task.sleep(nanoseconds: 1_200_000_000) // 1.2 seconds
        
        // Then: Should have decreased
        XCTAssertLessThan(timer.remaining, initialRemaining)
    }
    
    func testTimer_DoesNotCountDownWhenPaused() async {
        // Given
        let timer = RunningTimer(minutes: 1, label: "Test")
        timer.running = false
        let remainingWhenPaused = timer.remaining
        
        // When: Wait for some time
        try? await Task.sleep(nanoseconds: 1_200_000_000) // 1.2 seconds
        
        // Then: Should not have changed
        XCTAssertEqual(timer.remaining, remainingWhenPaused)
    }
}
