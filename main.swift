import Cocoa
import IOKit.pwr_mgt
import Carbon

// Event tap callback for keyboard monitoring
func keyboardCallback(proxy: CGEventTapProxy, type: CGEventType, event: CGEvent, refcon: UnsafeMutableRawPointer?) -> Unmanaged<CGEvent>? {
    if let appDelegate = NSApp.delegate as? AppDelegate {
        appDelegate.userActivityDetected()
    }
    return Unmanaged.passRetained(event)
}

// Default Pomodoro duration in minutes
let defaultPomodoroMinutes = 25

// Inactivity threshold in seconds before stopping the timer
let inactivityThresholdSeconds = 5

class AppDelegate: NSObject, NSApplicationDelegate {
    // Activity monitoring
    var lastActivityTime = Date()
    var activityMonitorTimer: Timer?
    var globalEventMonitor: Any?
    var localEventMonitor: Any?
    var window: NSWindow!
    var circleView: CircleView!
    var initialDragLocation: NSPoint?
    var timer: Timer?
    var secondsRemaining: Int = defaultPomodoroMinutes * 60 // Convert minutes to seconds
    var isTimerRunning = false
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Set up activity monitoring
        setupActivityMonitoring()
        // Create the circle view
        circleView = CircleView(frame: NSRect(x: 0, y: 0, width: 150, height: 150))
        
        // Create the window
        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 100, height: 100),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        
        // Configure the window
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = false
        window.level = .floating
        window.collectionBehavior = [.canJoinAllSpaces, .stationary]
        window.ignoresMouseEvents = false
        
        // Set the content view
        window.contentView = circleView
        
        // Position the window in the center of the screen
        if let screen = NSScreen.main {
            let x = (screen.frame.width - window.frame.width) / 2
            let y = (screen.frame.height - window.frame.height) / 2
            window.setFrameOrigin(NSPoint(x: x, y: y))
        }
        
        // Show the window
        window.makeKeyAndOrderFront(nil)
    }
    
    func setupActivityMonitoring() {
        // Monitor global mouse events
        globalEventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.mouseMoved, .leftMouseDown, .rightMouseDown]) { [weak self] _ in
            self?.userActivityDetected()
        }
        
        // Monitor local keyboard events (for the app)
        localEventMonitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .keyUp, .flagsChanged]) { [weak self] event in
            self?.userActivityDetected()
            return event
        }
        
        // Register for workspace notifications to detect activity
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(userDidBecomeActive),
            name: NSWorkspace.didActivateApplicationNotification,
            object: nil
        )
        
        // Set up a global event tap for keyboard events
        setupKeyboardEventTap()
        
        // Set up a timer to check for inactivity
        activityMonitorTimer = Timer.scheduledTimer(timeInterval: 5.0, target: self, selector: #selector(checkUserActivity), userInfo: nil, repeats: true)
    }
    
    func userActivityDetected() {
        // Update the last activity time
        lastActivityTime = Date()
        
        // Do NOT restart the timer if it has finished - require a manual click
        // Only start the timer if it's not already running, not finished, and has time remaining
        if !circleView.timerFinished && !isTimerRunning && secondsRemaining > 0 {
            startTimer()
        }
        
        // Debug output to confirm activity detection
        // print("Activity detected at \(Date())")
    }
    
    @objc func userDidBecomeActive(notification: Notification) {
        userActivityDetected()
    }
    
    func setupKeyboardEventTap() {
        // Create an event tap to monitor keyboard events
        let eventMask = (1 << CGEventType.keyDown.rawValue) | 
                       (1 << CGEventType.keyUp.rawValue) | 
                       (1 << CGEventType.flagsChanged.rawValue)
        
        guard let eventTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(eventMask),
            callback: keyboardCallback,
            userInfo: nil
        ) else {
            print("Failed to create event tap")
            return
        }
        
        // Create a run loop source and add it to the current run loop
        let runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        
        // Enable the event tap
        CGEvent.tapEnable(tap: eventTap, enable: true)
        
        print("Keyboard event tap set up successfully")
    }
    
    @objc func checkUserActivity() {
        // Check if user has been inactive for the threshold period
        let currentTime = Date()
        let inactivityDuration = currentTime.timeIntervalSince(lastActivityTime)
        
        // If user has been inactive for more than the threshold and timer is running, pause it
        if inactivityDuration > Double(inactivityThresholdSeconds) && isTimerRunning {
            stopTimer()
        }
    }
    
    // Manual start/stop (still available but not the primary method)
    func startStopTimer() {
        if isTimerRunning {
            stopTimer()
        } else {
            startTimer()
        }
    }
    
    func startTimer() {
        if timer == nil && secondsRemaining > 0 {
            timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(updateTimer), userInfo: nil, repeats: true)
            isTimerRunning = true
            circleView.needsDisplay = true
        }
    }
    
    func stopTimer() {
        timer?.invalidate()
        timer = nil
        isTimerRunning = false
        circleView.needsDisplay = true
    }
    
    @objc func updateTimer() {
        if secondsRemaining > 0 {
            secondsRemaining -= 1
            circleView.needsDisplay = true
        } else {
            stopTimer()
            timerFinished()
        }
    }
    
    func timerFinished() {
        // Set the timer finished state in the circle view
        circleView.timerFinished = true
        
        // Play alarm sound
        NSSound.beep()
        
        // Start flashing animation
        startFlashingAnimation()
        
        // Print message to console
        print("Time's up! Your Pomodoro session has ended.")
    }
    
    func startFlashingAnimation() {
        // Create a repeating timer for flashing effect
        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] timer in
            guard let self = self else {
                timer.invalidate()
                return
            }
            
            // Toggle flashing state
            self.circleView.isFlashing.toggle()
            self.circleView.needsDisplay = true
            
            // Stop flashing after 5 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                timer.invalidate()
                self.circleView.isFlashing = false
                self.circleView.needsDisplay = true
            }
        }
    }
    
    func resetTimer() {
        stopTimer()
        secondsRemaining = defaultPomodoroMinutes * 60
        circleView.needsDisplay = true
    }
}

class CircleView: NSView {    
    var delegate: AppDelegate? {
        return NSApp.delegate as? AppDelegate
    }
    
    // Font for the timer display
    let timerFont = NSFont.systemFont(ofSize: 24, weight: .medium)
    
    // Properties for timer finished state and flashing animation
    var timerFinished = false
    var isFlashing = false
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        self.wantsLayer = true
        self.layer?.backgroundColor = .clear
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        // Draw the circle background
        let circlePath = NSBezierPath(ovalIn: bounds.insetBy(dx: 5, dy: 5))
        
        // Change color based on timer state
        if let delegate = delegate, delegate.isTimerRunning {
            NSColor.green.withAlphaComponent(0.7).setFill()
        } else {
            NSColor.blue.withAlphaComponent(0.7).setFill()
        }
        
        circlePath.fill()
        
        // Draw the timer text or "Time's up!" message
        if self.timerFinished {
            // Display "Time's up!" message
            let message = "Time's up!"
            
            let textAttributes: [NSAttributedString.Key: Any] = [
                .font: timerFont,
                .foregroundColor: NSColor.white
            ]
            
            let textSize = message.size(withAttributes: textAttributes)
            let textRect = NSRect(
                x: (bounds.width - textSize.width) / 2,
                y: (bounds.height - textSize.height) / 2,
                width: textSize.width,
                height: textSize.height
            )
            
            message.draw(in: textRect, withAttributes: textAttributes)
        } else if let delegate = delegate {
            // Display the timer
            let minutes = delegate.secondsRemaining / 60
            let seconds = delegate.secondsRemaining % 60
            let timeString = String(format: "%02d:%02d", minutes, seconds)
            
            let textAttributes: [NSAttributedString.Key: Any] = [
                .font: timerFont,
                .foregroundColor: NSColor.white
            ]
            
            let textSize = timeString.size(withAttributes: textAttributes)
            let textRect = NSRect(
                x: (bounds.width - textSize.width) / 2,
                y: (bounds.height - textSize.height) / 2,
                width: textSize.width,
                height: textSize.height
            )
            
            timeString.draw(in: textRect, withAttributes: textAttributes)
        }
    }
    
    // Mouse event handling for dragging and timer control
    override func mouseDown(with event: NSEvent) {
        // Store location for potential drag
        delegate?.initialDragLocation = event.locationInWindow
        
        // Check if it's a click (will be determined in mouseUp)
    }
    
    override func mouseDragged(with event: NSEvent) {
        guard let window = window, let initialDragLocation = delegate?.initialDragLocation else { return }
        
        let currentLocation = event.locationInWindow
        let deltaX = currentLocation.x - initialDragLocation.x
        let deltaY = currentLocation.y - initialDragLocation.y
        
        let newOrigin = NSPoint(
            x: window.frame.origin.x + deltaX,
            y: window.frame.origin.y + deltaY
        )
        
        window.setFrameOrigin(newOrigin)
    }
    
    override func mouseUp(with event: NSEvent) {
        // Check if the timer has finished and reset it on click
        if timerFinished {
            timerFinished = false
            delegate?.resetTimer()
            delegate?.startTimer() // Automatically start the timer after reset
            needsDisplay = true
            print("Timer reset and restarted by mouse click")
        }
        
        // Reset the drag location
        delegate?.initialDragLocation = nil
    }
}

// Create and run the application
let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate

// Request accessibility permissions for monitoring keyboard events
let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
AXIsProcessTrustedWithOptions(options as CFDictionary)

app.setActivationPolicy(.accessory) // Makes the app not appear in the Dock
app.run()
