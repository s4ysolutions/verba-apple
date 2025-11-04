//
//  ContentView.swift
//  verba-masos
//
//  Created by Dolin Sergey on 2. 11. 2025..
//

import core
import OSLog
import SwiftUI

struct ContentView: View {
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "verba-masos", category: "ContentView")

    @StateObject private var viewModel: TranslationViewModel

    init(translateUseCase: TranslateUseCase) {
        _viewModel = StateObject(wrappedValue: TranslationViewModel(translator: translateUseCase))
    }

    var body: some View {
        GeometryReader { geo in
            let totalHeight = geo.size.height
            let topHeight = totalHeight * (1.0 / 6.0)
            let middleHeight = totalHeight * (1.0 / 2.0)
            let bottomHeight = totalHeight * (1.0 / 3.0)
            let vm = viewModel

            VStack(spacing: 0) {
                // Top panel
                panelBackground(
                    ScrollView {
                        selectableText(vm.translatingText)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                    }
                )
                .frame(height: topHeight)

                Divider()

                // Middle panel
                if vm.isLoading {
                    panelBackground(
                        ProgressView("Translating...")
                    )
                    .frame(height: middleHeight)
                } else {
                    panelBackground(
                        ScrollView {
                            selectableText(vm.translatedText)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding()
                        }
                    )
                    .frame(height: middleHeight)
                }

                Divider()

                // Bottom panel
                panelBackground(
                    HStack {
                        Spacer()
                        Button("Cancel") {
                            handleCancel()
                        }
                        .keyboardShortcut(.cancelAction)

                        Button("OK") {
                            handleOK()
                        }
                        .keyboardShortcut(.defaultAction)
                    }
                    .padding()
                )
                .frame(height: bottomHeight)
            }
            .onAppear {
                updateClipboardText()
            }
            // Update when the app becomes active (regains focusInsert)
            .onReceive(appBecameActivePublisher) { _ in
                updateClipboardText()
            }
        }
        .padding(.vertical, 0)
        .padding(.horizontal, 0)
    }

    // MARK: - Platform helpers

    private var appBecameActivePublisher: NotificationCenter.Publisher {
        #if os(macOS)
            return NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)
        #else
            return NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)
        #endif
    }

    private func updateClipboardText() {
        #if os(macOS)
            let str = NSPasteboard.general.string(forType: .string) ?? ""
        #else
            let str = UIPasteboard.general.string ?? ""
        #endif
        Task {
            logger.debug("translate task launched")
            await viewModel.translate(text: str, force: false)
        }
    }

    // MARK: - UI helpers

    @ViewBuilder
    private func selectableText(_ text: String) -> some View {
        #if os(macOS)
            Text(text)
                .textSelection(.enabled)
                .font(.system(.body, design: .default))
        #else
            Text(text)
                .textSelection(.enabled)
                .font(.body)
        #endif
    }

    @ViewBuilder
    private func panelBackground<Content: View>(_ content: Content) -> some View {
        #if os(macOS)
            content
                .background(Color(NSColor.textBackgroundColor))
        #else
            content
                .background(Color(UIColor.systemBackground))
        #endif
    }

    // MARK: - Actions

    private func handleOK() {
        print("OK tapped")
        Task{
            await viewModel.translate(text: viewModel.translatingText, force: true)
        }
        /*
         #if os(macOS)
             NSApp.keyWindow?.performClose(nil)
         #endif
          */
    }

    private func handleCancel() {
        print("Cancel tapped")
        #if os(macOS)
            NSApp.keyWindow?.performClose(nil)
        #endif
    }
}

#Preview {
    ContentView(translateUseCase: TranslationService(repository: TranslationRestRepository()))
}
