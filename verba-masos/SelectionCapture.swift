import Cocoa
import OSLog

class SelectionCapture {
    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "verba-macos",
        category: "SelectionCapture"
    )

    func captureSelection(completion: @escaping (String?) -> Void) {
        // Save current clipboard
        let pasteboard = NSPasteboard.general
        let previousContent = pasteboard.string(forType: .string)

        logger.debug("💾 Saved previous clipboard content")

        // Clear clipboard to detect new copy
        pasteboard.clearContents()

        // Simulate Cmd+C to copy the selection
        simulateCmdC { [weak self] success in
            guard let self = self else { return }

            if !success {
                self.logger.error("❌ Failed to simulate Cmd+C")
                completion(nil)
                return
            }

            // Small delay for clipboard to update
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                guard let copiedText = pasteboard.string(forType: .string), !copiedText.isEmpty else {
                    self.logger.warning("❌ No text copied")

                    // Restore previous clipboard
                    if let previous = previousContent {
                        pasteboard.clearContents()
                        pasteboard.setString(previous, forType: .string)
                    }

                    completion(nil)
                    return
                }

                self.logger.info("✅ Captured selection: '\(copiedText.prefix(50))...'")
                completion(copiedText)

                // Optionally restore previous clipboard after processing
                // (DeepL doesn't do this, but you could)
                // if let previous = previousContent {
                //     DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                //         pasteboard.clearContents()
                //         pasteboard.setString(previous, forType: .string)
                //     }
                // }
            }
        }
    }

    private func simulateCmdC(completion: @escaping (Bool) -> Void) {
        // Create event source
        guard let source = CGEventSource(stateID: .hidSystemState) else {
            logger.error("Failed to create event source")
            completion(false)
            return
        }

        // Key codes
        let cmdKey: CGKeyCode = 0x37  // Command
        let cKey: CGKeyCode = 0x08    // C

        // Press Command down
        guard let cmdDown = CGEvent(keyboardEventSource: source, virtualKey: cmdKey, keyDown: true) else {
            completion(false)
            return
        }
        cmdDown.flags = .maskCommand

        // Press C down (with Command held)
        guard let cDown = CGEvent(keyboardEventSource: source, virtualKey: cKey, keyDown: true) else {
            completion(false)
            return
        }
        cDown.flags = .maskCommand

        // Release C
        guard let cUp = CGEvent(keyboardEventSource: source, virtualKey: cKey, keyDown: false) else {
            completion(false)
            return
        }
        cUp.flags = .maskCommand

        // Release Command
        guard let cmdUp = CGEvent(keyboardEventSource: source, virtualKey: cmdKey, keyDown: false) else {
            completion(false)
            return
        }

        // Post events in sequence
        let location = CGEventTapLocation.cghidEventTap
        cmdDown.post(tap: location)

        // Small delay between key down and up
        usleep(10000) // 10ms

        cDown.post(tap: location)
        usleep(10000) // 10ms

        cUp.post(tap: location)
        usleep(10000) // 10ms

        cmdUp.post(tap: location)

        logger.debug("⌨️ Simulated Cmd+C")
        completion(true)
    }
}
