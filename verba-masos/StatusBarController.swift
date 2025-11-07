//
//  StatusBarController.swift
//  verba-masos
//

import Cocoa
import os

final class StatusBarController {
    private static let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "verba-masos", category: "StatusBar")

    // UserDefaults keys
    private static let autoCopyKey = "menu.check.autoCopy"
    private static let autoPasteKey = "menu.check.autoPaste"

    private let statusItem: NSStatusItem
    private let menu: NSMenu

    private let onShow: () -> Void
    private let onQuit: () -> Void

    init(onShow: @escaping () -> Void, onQuit: @escaping () -> Void) {
        self.onShow = onShow
        self.onQuit = onQuit

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        menu = NSMenu()
        buildMenu(into: menu)

        if let button = statusItem.button {
            button.image = NSImage(named: "verba-png-16") // NSImage(systemSymbolName: "text.bubble", accessibilityDescription: nil)
            button.image?.isTemplate = false // use colors for dark/light menu bar
            Self.logger.debug("Status item button configured with template image")

            // Set up action handling for clicks.
            button.target = self
            button.action = #selector(statusItemClicked(_:))
            // IMPORTANT: Use mouseDown so the action fires even when the app is inactive.
            button.sendAction(on: [.leftMouseDown, .rightMouseDown])
            Self.logger.debug("Status item button actions set for left and right mouse down")
        } else {
            Self.logger.error("Failed to get status item button")
        }
    }

    private func buildMenu(into menu: NSMenu) {
        /*
        let showTitle = NSLocalizedString("menu.show", value: "Show", comment: "Show main window")
        let showItem = NSMenuItem(title: showTitle, action: #selector(didTapShow), keyEquivalent: "")
        showItem.target = self
        menu.addItem(showItem)
         */
        let quitTitle = NSLocalizedString("menu.quit", value: "Quit", comment: "Quit application")


        // Ensure defaults exist and are true by default
        let defaults = UserDefaults.standard
        if defaults.object(forKey: Self.autoCopyKey) == nil {
            defaults.set(true, forKey: Self.autoCopyKey)
        }
        if defaults.object(forKey: Self.autoPasteKey) == nil {
            defaults.set(true, forKey: Self.autoPasteKey)
        }

        // Checkable preferences
        let autoCopyTitle = NSLocalizedString("menu.check.autoCopy", value: "Monitor Clipboard", comment: "Toggle monitoring clipboard")
        let autoPasteTitle = NSLocalizedString("menu.check.autoPaste", value: "Auto-Paste Translation", comment: "Toggle auto pasting translation to clipboard")

        let autoCopyItem = NSMenuItem(title: autoCopyTitle, action: #selector(toggleAutoCopy(_:)), keyEquivalent: "")
        autoCopyItem.target = self
        autoCopyItem.state = defaults.bool(forKey: Self.autoCopyKey) ? .on : .off
        autoCopyItem.onStateImage = NSImage(named: NSImage.menuOnStateTemplateName)
        menu.addItem(autoCopyItem)

        let autoPasteItem = NSMenuItem(title: autoPasteTitle, action: #selector(toggleAutoPaste(_:)), keyEquivalent: "")
        autoPasteItem.target = self
        autoPasteItem.state = defaults.bool(forKey: Self.autoPasteKey) ? .on : .off
        autoPasteItem.onStateImage = NSImage(named: NSImage.menuOnStateTemplateName)
        menu.addItem(autoPasteItem)

        menu.addItem(NSMenuItem.separator())

        let quitItem = NSMenuItem(title: quitTitle, action: #selector(didTapQuit), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
    }

    @objc private func statusItemClicked(_ sender: Any?) {
        guard let event = NSApp.currentEvent else {
            Self.logger.warning("statusItemClicked: No current event; defaulting to onShow()")
            onShow()
            return
        }

        Self.logger.debug("statusItemClicked: eventType=\(String(describing: event.type.rawValue))")

        switch event.type {
        case .rightMouseDown:
            Self.logger.info("Right click detected; showing menu")
            showMenu()
        case .leftMouseDown:
            Self.logger.info("Left click detected; invoking onShow()")
            // Defer to next runloop turn to let status item tracking finish cleanly.
            DispatchQueue.main.async { [onShow] in
                onShow()
            }
        default:
            // Ignore mouseUp and other types to prevent double-handling.
            Self.logger.debug("Ignoring event type: \(String(describing: event.type.rawValue))")
            break
        }
    }

    private func showMenu() {
        /*
         guard let button = statusItem.button else { return }
         let workspace = NSWorkspace.shared
         previousApp = workspace.runningApplications.first { app in
             app.isActive //&& app.bundleIdentifier != Bundle.main.bundleIdentifier
         }
         // NSApp.activate(ignoringOtherApps: true)
         let rect = button.bounds
         menu.popUp(positioning: nil, at: NSPoint(x: rect.minX, y: rect.minY), in: button)
          */
        /*
         if let frontmostApp = NSWorkspace.shared.frontmostApplication,
            frontmostApp.bundleIdentifier != Bundle.main.bundleIdentifier {
             frontmostApp.activate(options: [])
         }
          */
        
        guard let button = statusItem.button else { return }
        statusItem.menu = menu
        button.performClick(nil)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.statusItem.menu = nil
        }

        /*
         guard let button = statusItem.button else {
             Self.logger.error("showMenu: statusItem.button is nil; using fallback presentation")
             if let anchorView = NSApp.keyWindow?.contentView ?? NSApp.mainWindow?.contentView ?? NSApp.windows.first?.contentView {
                 if let currentEvent = NSApp.currentEvent {
                     NSMenu.popUpContextMenu(menu, with: currentEvent, for: anchorView)
                 } else {
                     let mouseLocation = NSEvent.mouseLocation
                     menu.popUp(positioning: nil, at: mouseLocation, in: nil)
                 }
             } else {
                 let mouseLocation = NSEvent.mouseLocation
                 menu.popUp(positioning: nil, at: mouseLocation, in: nil)
             }
             return
         }

         if let currentEvent = NSApp.currentEvent {
             Self.logger.debug("showMenu: Using current event with popUpContextMenu")
             // NSMenu.popUpContextMenu(menu, with: currentEvent, for: button)
             let rect = button.bounds
             menu.popUp(positioning: nil, at: NSPoint(x: rect.minX, y: rect.minY), in: button)
         } else {
             let screenFrame = button.window?.convertToScreen(button.convert(button.bounds, to: nil)) ?? .zero
             let center = NSPoint(x: screenFrame.midX, y: screenFrame.minY) // below the button
             let synthetic = NSEvent.mouseEvent(
                 with: .rightMouseDown,
                 location: center,
                 modifierFlags: [],
                 timestamp: ProcessInfo.processInfo.systemUptime,
                 windowNumber: button.window?.windowNumber ?? 0,
                 context: nil,
                 eventNumber: 0,
                 clickCount: 1,
                 pressure: 1.0
             )
             Self.logger.debug("showMenu: Using synthetic event with popUpContextMenu")
             NSMenu.popUpContextMenu(menu, with: synthetic!, for: button)
         }
         Self.logger.debug("dismiss")
          */
        /*
         DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
             NSApp.hide(nil)
             NSApp.deactivate()
             if let keyWindow = NSApp.keyWindow {
                 keyWindow.resignKey()
             }
         }
          */
    }

    @objc private func toggleAutoCopy(_ sender: NSMenuItem) {
        sender.state = (sender.state == .on) ? .off : .on
        let newValue = (sender.state == .on)
        UserDefaults.standard.set(newValue, forKey: Self.autoCopyKey)
        Self.logger.info("AutoCopy set to \(newValue, privacy: .public)")
    }

    @objc private func toggleAutoPaste(_ sender: NSMenuItem) {
        sender.state = (sender.state == .on) ? .off : .on
        let newValue = (sender.state == .on)
        UserDefaults.standard.set(newValue, forKey: Self.autoPasteKey)
        Self.logger.info("AutoPaste set to \(newValue, privacy: .public)")
    }

    @objc private func didTapShow() {
        onShow()
        //hideApp()
    }

    @objc private func didTapQuit() {
        onQuit()
    }
}
