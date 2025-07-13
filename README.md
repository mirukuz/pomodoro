# Pomodoro Timer
A minimalist Pomodoro timer app for macOS

## Description
A lightweight macOS application that displays a floating circle timer that stays on top of all windows. The app helps you manage your work sessions using the Pomodoro technique with visual and audible notifications.

## Features
- Interactive floating timer with color-coded states:
  - Blue: Timer paused
  - Green: Timer running
  - Flashing red/orange: Timer finished
- Automatic timer control based on user activity:
  - Starts when you're active (if paused)
  - Pauses after configurable inactivity period
  - Requires manual restart after completion
- Visual and audible notifications when timer completes
- Session logging to track productivity
- Draggable interface
- Visible across all spaces/desktops

## Requirements
- macOS 10.15 or later
- Accessibility permissions (for keyboard activity monitoring)

## Usage
Compile and run the application using:
```
swift pomodoro.swift
```

## Configuration
You can modify these constants in the source code:
- `defaultPomodoroMinutes`: Duration of each Pomodoro session (default: 1 minute)
- `inactivityThresholdSeconds`: Time before pausing due to inactivity (default: 5 seconds)

## Session Logging
The app automatically logs your Pomodoro sessions to a file in your home directory. Each log entry includes:
- Start time
- End time
- Total duration
- Active time
- Inactive time

To view your session logs:
```
cat ~/pomodoro_log.txt
```

## Testing
Run the test suite with:
```
swift SimplePomodoroTests.swift
```
