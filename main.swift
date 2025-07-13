import Cocoa

// Default Pomodoro duration in minutes
let defaultPomodoroMinutes = 1

class AppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow!
    var circleView: CircleView!
    var initialDragLocation: NSPoint?
    var timer: Timer?
    var secondsRemaining: Int = defaultPomodoroMinutes * 60 // Convert minutes to seconds
    var isTimerRunning = false
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Create the circle view
        circleView = CircleView(frame: NSRect(x: 0, y: 0, width: 150, height: 150))
        
        // Create the window
        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 150, height: 150),
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
        
        // Draw the timer text
        if let delegate = delegate {
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
        // If we didn't move much, consider it a click to start/stop the timer
        if let initialLocation = delegate?.initialDragLocation,
           abs(initialLocation.x - event.locationInWindow.x) < 5 &&
           abs(initialLocation.y - event.locationInWindow.y) < 5 {
            delegate?.startStopTimer()
        }
        
        delegate?.initialDragLocation = nil
    }
}

// Create and run the application
let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory) // Makes the app not appear in the Dock
app.run()
