Preparation:
1. ok now we have a basic app that can run a floating circle, can we add one more feature: allow user to drag the circle around the screen

Features 1:
- the circle should display time counting down, let's make the default time counting down 25 minutes, it just just display the time like "25:00", when time is up, it should display "00:00"
- when user click on the circle, it starts counting down, when user click on the circle again, it stops counting down

Feature 2:
- let's now trigger the Pomodoro timer counting down not by click, but by detecting user active behaviours on the screen, e.g. moving mouse, typing, etc.
- Looks like now it detect moving mouse, but not the typing

Feature 3:
- when the counting down is finished, giving an notification of "Time's up!"
- Once time is up, you have to click the circle to re-enable the timer counting down, the acticity detection won't be able to retrigger the timer without clicking
- Fix: No i mean once it reaches 0, you won't be able to restart it through user activity, you can only restart by clicking the circle.  but once it restart, when it paused, you can retrigger it through activity

Feature 4:
- Everytime when the Pomodoro timer is finished, it should write a log to a file in the user's home directory, record the start time, the duration of active time, and the end time

Clean up:
I'm happy with the functionality now, let's clean up the code
- Now the main.swift file is getting pretty long, can we break it down to small files to make it more readable
