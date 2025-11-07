import Carbon
import Cocoa
import OSLog

class GlobalDoubleCmdCDetector {
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var pressTimes: [Date] = []
    private let timeWindow: TimeInterval = 0.5
    private let handler: () -> Void
    private var permissionTimer: Timer?

    init(handler: @escaping () -> Void) {
        self.handler = handler
    }

    func start() -> Bool {
        guard checkAccessibilityPermission() else {
            showAccessibilityAlert()
            startPermissionPolling()
            return false
        }
        startPermissionPolling()

        return true
    }

    private func eventCallback(proxy: CGEventTapProxy, type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent> {
        // Handle tap disabled (happens when user locks screen, etc.)
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            if let eventTap = eventTap {
                CGEvent.tapEnable(tap: eventTap, enable: true)
            }
            return Unmanaged.passUnretained(event)
        }

        guard type == .keyDown else {
            return Unmanaged.passUnretained(event)
        }

        // Check if it's C key (keycode 8)
        let keycode = event.getIntegerValueField(.keyboardEventKeycode)
        guard keycode == 8 else {
            return Unmanaged.passUnretained(event)
        }

        // Check if ONLY Command is pressed (no Shift, Option, Control)
        let flags = event.flags
        let hasCommand = flags.contains(.maskCommand)
        let hasShift = flags.contains(.maskShift)
        let hasOption = flags.contains(.maskAlternate)
        let hasControl = flags.contains(.maskControl)

        guard hasCommand && !hasShift && !hasOption && !hasControl else {
            return Unmanaged.passUnretained(event)
        }

        // Detect triple press
        detectTriplePress()

        // IMPORTANT: Return the event unmodified so Cmd+C still works normally
        return Unmanaged.passUnretained(event)
    }

    private func detectTriplePress() {
        let now = Date()

        // Remove old presses outside time window
        pressTimes = pressTimes.filter { now.timeIntervalSince($0) < timeWindow }

        // Add current press
        pressTimes.append(now)

        // Check for triple press
        if pressTimes.count >= 2 {
            pressTimes.removeAll()

            // Call handler on main thread
            DispatchQueue.main.async {
                self.handler()
            }
        }
    }

    func stop() {
        permissionTimer?.invalidate()
        permissionTimer = nil

        if let eventTap = eventTap {
            CGEvent.tapEnable(tap: eventTap, enable: false)
        }
        if let runLoopSource = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        }
    }

    deinit {
        stop()
    }

    private func requestAccessibilityPermission() -> Bool {
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeRetainedValue() as String: true]
        return AXIsProcessTrustedWithOptions(options)
    }

    private func checkAccessibilityPermission() -> Bool {
        return AXIsProcessTrusted()
    }

    private func startEventTap() -> Bool {
        let eventMask = (1 << CGEventType.keyDown.rawValue)

        guard let eventTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(eventMask),
            callback: { proxy, type, event, refcon in
                guard let refcon = refcon else {
                    return Unmanaged.passUnretained(event)
                }
                let detector = Unmanaged<GlobalDoubleCmdCDetector>.fromOpaque(refcon).takeUnretainedValue()
                return detector.eventCallback(proxy: proxy, type: type, event: event)
            },
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        ) else {
            logger.error("Failed to create event tap")
            return false
        }

        self.eventTap = eventTap
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: eventTap, enable: true)

        logger.info("Global double Cmd+C detector started")
        return true
    }

    private func startPermissionPolling() {
        permissionTimer?.invalidate()
        logger.info("Starting permission polling...")
        permissionTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] timer in
            guard let self = self else {
                timer.invalidate()
                return
            }

            self.logger.info("Checking accessibility permission...")
            if checkAccessibilityPermission() {
                timer.invalidate()
                self.permissionTimer = nil
                self.logger.info("Permission granted!")

                // Start the event tap now
                if self.startEventTap() {
                    DispatchQueue.main.async {
                        self.showSuccessAlert()
                    }
                }
            }
        }
    }

    private func showAccessibilityAlert() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            let alert = NSAlert()
            alert.messageText = "Accessibility Access Required"
            alert.informativeText = """
            This app needs accessibility permission to detect keyboard shortcuts globally.

            Please:
            1. Click "Open System Settings" in the system dialog
            2. Find this app in the list
            3. Toggle the switch to enable access
            4. Restart the app
            """
            alert.alertStyle = .informational
            alert.addButton(withTitle: "OK")
            if alert.runModal() == .alertFirstButtonReturn {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    /*
                     if let url = URL(string: "x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension") {
                         NSWorkspace.shared.open(url)
                     } else {*/
                    if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
                        NSWorkspace.shared.open(url)
                    }
                    // }
                }
            }
        }
    }

    private func showSuccessAlert() {
        let alert = NSAlert()
        alert.messageText = "Ready to Go!"
        alert.informativeText = """
        Accessibility permission has been granted!

        Global keyboard shortcut detection is now active.

        Try it: Press Cmd+C twice quickly to trigger the action.
        """
        alert.alertStyle = .informational
        alert.addButton(withTitle: "Awesome!")
        alert.runModal()
    }

    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "verba-masos", category: "GlobalDoubleCmdCDetector")
}
