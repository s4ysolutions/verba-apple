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
    @FocusState private var focused: Bool

    init(translateUseCase: TranslateUseCase, getProvidersUseCase: GetProvidersUseCase) {
        _viewModel = StateObject(wrappedValue: TranslationViewModel(
            translateUseCase: translateUseCase,
            getProviderUseCase: getProvidersUseCase
        ))
    }

    var body: some View {
        GeometryReader { geo in
            if viewModel.isLoading {
                VStack {
                    Spacer()
                    ProgressView("Loading...")
                        .frame(maxWidth: .infinity, alignment: .center)
                    Spacer()
                }
                .background(Color(NSColor.textBackgroundColor))
                .frame(height: geo.size.height)
            } else {
                VStack {
                    VStack {
                        editableText($viewModel.translatingText)
                            .focused($focused)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        HStack {
                            Spacer()
                            TextField(NSLocalizedString("lable.from", value: "From:", comment: "A language to translate from"),
                                      text: $viewModel.fromLanguage)
                                .frame(maxWidth: 150)
                            Button(NSLocalizedString(
                                "label.translate",
                                value: "Translate",
                                comment: "Send the content of the text field to the translation service"))
                            {
                                handleTranslate()
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(viewModel.isTranslating)
                        }.padding(.trailing)
                    }
                    .padding(.leading)
                    .background(Color(NSColor.textBackgroundColor))
                    .frame(height: geo.size.height * (2.0 / 9.0)) // 2 -
                    Divider()
                    if viewModel.isTranslating {
                        ProgressView("Translating...")
                            .background(Color(NSColor.textBackgroundColor))
                            .frame(maxHeight: .infinity)
                    } else {
                        VStack {
                            editableText($viewModel.translatedText)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            HStack {
                                HStack {
                                    Picker("", selection: $viewModel.mode) {
                                        Text(modeLabel(.Auto)).tag(TranslationMode.Auto)
                                        Text(modeLabel(.TranslateSentence)).tag(TranslationMode.TranslateSentence)
                                        Text(modeLabel(.ExplainWords)).tag(TranslationMode.ExplainWords)
                                    }
                                    .pickerStyle(.menu)

                                    // Quality selector
                                    Picker("", selection: $viewModel.quality) {
                                        Text(qualityLabel(.Fast)).tag(TranslationQuality.Fast)
                                        Text(qualityLabel(.Optimal)).tag(TranslationQuality.Optimal)
                                        Text(qualityLabel(.Thinking)).tag(TranslationQuality.Thinking)
                                    }
                                    .pickerStyle(.menu)

                                    Picker("", selection: $viewModel.provider) {
                                        ForEach(viewModel.providers) { provider in
                                            Text(provider.displayName).tag(Optional(provider))
                                        }
                                    }
                                    .pickerStyle(.menu)
                                }

                                Spacer()

                                HStack {
                                    TextField(NSLocalizedString("label.to", value: "To:", comment: "A language to translate to"),
                                              text: $viewModel.toLanguage)
                                        .frame(maxWidth: 150)
                                    Button(NSLocalizedString(
                                        "label.copy",
                                        value: "Copy",
                                        comment: "Copy the translated text to the clipboard"), systemImage: "doc.on.doc") {
                                            handleCopy()
                                        }
                                }
                                .fixedSize(horizontal: true, vertical: false)
                                .padding(.trailing)
                            }
                        }
                        .padding([.leading, .bottom])
                        .background(Color(NSColor.textBackgroundColor))
                        .frame(maxHeight: .infinity)
                    }
                }
                .background(Color(NSColor.textBackgroundColor))
            }
        }
        .onAppear {
            logger.debug("View: onAppear")
            updateClipboardText()
            focused = true
        }
        .onReceive(appBecameActivePublisher) { _ in
            logger.debug("View: onRecieve")
            updateClipboardText()
            focused = true
        }
    }

    /*
     var body: some View {
         let vm = viewModel

         GeometryReader { geo in
             if viewModel.isLoading {
                 VStack {
                     Spacer()
                     ProgressView("Loading...")
                         .frame(maxWidth: .infinity, alignment: .center)
                     Spacer()
                 }
                 .background(Color(NSColor.textBackgroundColor))
                 .frame(height: geo.size.height)
             } else {
                 VStack {
                     VStack {
                         editableText($viewModel.translatingText)
                             .focused($focused)
                             .frame(maxWidth: .infinity, alignment: .leading)
                         HStack {
                             Spacer()
                             TextField(NSLocalizedString("lable.from", value: "From:", comment: "A language to translate from"),
                                       text: $viewModel.fromLanguage)
                                 .frame(maxWidth: 150)
                             Button(NSLocalizedString(
                                 "label.translate",
                                 value: "Translate",
                                 comment: "Send the content of the text field to the translation service"))
                             {
                                 handleTranslate()
                             }
                             .buttonStyle(.borderedProminent)
                             .disabled(viewModel.isTranslating)
                         }.padding(.trailing)
                     }
                     .padding(.leading)
                     // .background(Color(NSColor.textBackgroundColor))
                     .background(Color.red)
                     .frame(height: geo.size.height * (2.0 / 9.0)) // 2 -

                     Divider()

                     // Middle panel
                     if vm.isTranslating {
                         ProgressView("Translating...")
                             .background(Color(NSColor.textBackgroundColor))
                             .frame(height: geo.size.height * (7.0 / 9.0))
                     } else {
                         VStack {
                             editableText($viewModel.translatedText)
                                 .frame(maxWidth: .infinity, alignment: .leading)
                             HStack {
                                 HStack {
                                     Picker("", selection: $viewModel.mode) {
                                         Text(modeLabel(.Auto)).tag(TranslationMode.Auto)
                                         Text(modeLabel(.TranslateSentence)).tag(TranslationMode.TranslateSentence)
                                         Text(modeLabel(.ExplainWords)).tag(TranslationMode.ExplainWords)
                                     }
                                     .pickerStyle(.menu)
                                     .frame(maxWidth: 180)

                                     // Quality selector
                                     Picker("", selection: $viewModel.quality) {
                                         Text(qualityLabel(.Fast)).tag(TranslationQuality.Fast)
                                         Text(qualityLabel(.Optimal)).tag(TranslationQuality.Optimal)
                                         Text(qualityLabel(.Thinking)).tag(TranslationQuality.Thinking)
                                     }
                                     .pickerStyle(.menu)
                                     .frame(maxWidth: 180)

                                     Picker("", selection: $viewModel.provider) {
                                         ForEach(viewModel.providers) { provider in
                                             Text(provider.displayName).tag(Optional(provider))
                                         }
                                     }
                                     .pickerStyle(.menu)
                                     .frame(maxWidth: 180)
                                 }
                                 .background(Color.yellow)
                                 .fixedSize(horizontal: true, vertical: false)

                                 Spacer()

                                 HStack {
                                     TextField(NSLocalizedString("label.to", value: "To:", comment: "A language to translate to"),
                                               text: $viewModel.toLanguage)
                                         .frame(maxWidth: 150)
                                     Button(NSLocalizedString(
                                         "label.copy",
                                         value: "Copy",
                                         comment: "Copy the translated text to the clipboard"), systemImage: "doc.on.doc") {
                                             handleCopy()
                                         }
                                 }
                                 .background(Color.yellow)
                                 .fixedSize(horizontal: true, vertical: false)
                             }
                         }
                         // .background(Color(NSColor.textBackgroundColor))
                         .background(Color.green)
                         .frame(height: geo.size.height * (7.0 / 9.0))
                         .padding(.leading)
                     }
                 }
             }
         }
         .onAppear {
             logger.debug("View: onAppear")
             updateClipboardText()
             focused = true
         }
         .onReceive(appBecameActivePublisher) { _ in
             logger.debug("View: onRecieve")
             updateClipboardText()
             focused = true
         }
     }
      */

    // MARK: - Platform helpers

    private var appBecameActivePublisher: NotificationCenter.Publisher {
        #if os(macOS)
            return NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)
        #else
            return NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)
        #endif
    }

    private func updateClipboardText() {
        let monitorClipboard = UserDefaults.standard.object(forKey: "menu.check.autoCopy") as? Bool ?? true
        if monitorClipboard == false {
            logger.debug("Monitoring clipboard is disabled")
            return
        }

        #if os(macOS)
            let str = NSPasteboard.general.string(forType: .string) ?? ""
        #else
            let str = UIPasteboard.general.string ?? ""
        #endif
        logger.error("Launching translation task (force: false)")
        Task {
            logger.error("Translation task (force: false) started")
            await viewModel.translate(text: str, force: false)
        }
        logger.error("Launching translation task (force: false) ended")
    }

    // MARK: - UI helpers

    @ViewBuilder
    private func selectableText(_ text: String) -> some View {
        Text(text)
            .textSelection(.enabled)
            .font(.system(.body, design: .default))
    }

    @ViewBuilder
    private func editableText(_ text: Binding<String>) -> some View {
        TextEditor(text: text)
            .textSelection(.enabled)
            .font(.system(.body, design: .default))
    }

    // Provide user-facing labels for modes
    private func modeLabel(_ mode: TranslationMode) -> String {
        switch mode {
        case .Auto:
            return NSLocalizedString("mode.auto", value: "Auto", comment: "Automatic mode")
        case .TranslateSentence:
            return NSLocalizedString("mode.translate", value: "Translate sentence", comment: "Translate sentence mode")
        case .ExplainWords:
            return NSLocalizedString("mode.explain", value: "Explain words", comment: "Explain words mode")
        }
    }

    // Provide user-facing labels for qualities
    private func qualityLabel(_ quality: TranslationQuality) -> String {
        switch quality {
        case .Fast:
            return NSLocalizedString("qulity.fast", value: "Fast", comment: "Lowest but fastest translate")
        case .Optimal:
            return NSLocalizedString("qulity.optimal", value: "Optimal", comment: "Optimal quality but acceptable fast translate")
        case .Thinking:
            return NSLocalizedString("qulity.thinking", value: "Thinking", comment: "Best quality but slowest translate")
        }
    }

    // MARK: - Actions

    private func handleOK() {
        print("OK tapped")
        #if os(macOS)
            NSApp.keyWindow?.performClose(nil)
        #endif
    }

    private func handleCancel() {
        print("Cancel tapped")
        #if os(macOS)
            NSApp.keyWindow?.performClose(nil)
        #endif
    }

    private func handleTranslate() {
        logger.debug("Launching translation (force: true)")
        Task {
            await viewModel.translate(text: viewModel.translatingText, force: true)
        }
    }

    private func handleCopy() {
        viewModel.copyToClipboard(viewModel.translatedText)
    }
}

#Preview {
    ContentView(
        translateUseCase: TranslationService(translationRepository: TranslationRestRepository()),
        getProvidersUseCase: TranslationService(translationRepository: TranslationRestRepository())
    )
}
