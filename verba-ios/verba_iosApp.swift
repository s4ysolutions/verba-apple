import core
import SwiftUI

@main
struct verba_iosApp: App {
    @State private var showAbout = false

    // Create a shared service that conforms to both TranslateUseCase and GetProvidersUseCase
    private let translationService = TranslationService(translationRepository: TranslationRestRepository())
    @AppStorage("menu.check.autoCopy") private var autoCopy: Bool = true
    @AppStorage("menu.check.autoPaste") private var autoPaste: Bool = true

    var body: some Scene {
        WindowGroup {
            NavigationView {
                ContentView(
                    translateUseCase: translationService,
                    getProvidersUseCase: translationService
                )
                .navigationTitle(Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String ?? "Verba")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Menu {
                            // Auto-copy toggle
                            Button(action: {
                                let newValue = !(UserDefaults.standard.bool(forKey: "menu.check.autoCopy"))
                                UserDefaults.standard.set(newValue, forKey: "menu.check.autoCopy")
                            }) {
                                Label(
                                    NSLocalizedString(
                                        "menu.check.autoCopy",
                                        value: "Monitor Clipboard",
                                        comment: "Toggle monitoring clipboard"
                                    ),
                                    systemImage: autoCopy ? "checkmark.square" : "square"
                                )
                            }

                            // Auto-paste toggle
                            Button(action: {
                                let newValue = !(UserDefaults.standard.bool(forKey: "menu.check.autoPaste"))
                                UserDefaults.standard.set(newValue, forKey: "menu.check.autoPaste")
                            }) {
                                Label(
                                    NSLocalizedString(
                                        "menu.check.autoPaste",
                                        value: "Auto-Paste Translation",
                                        comment: "Toggle auto pasting translation to clipboard"
                                    ),
                                    systemImage: autoPaste ? "checkmark.square" : "square"
                                )
                            }
                            Divider()

                            Button(NSLocalizedString("menu.about", value: "About & Privacy", comment: "")) {
                                showAbout = true
                            }
                        } label: {
                            Image(systemName: "ellipsis")
                                .rotationEffect(.degrees(90))
                        }
                        .menuStyle(BorderlessButtonMenuStyle())
                        .menuIndicator(.hidden)
                        .onAppear {
                            let defaults = UserDefaults.standard
                            if defaults.object(forKey: "menu.check.autoCopy") == nil {
                                defaults.set(true, forKey: "menu.check.autoCopy")
                            }
                            if defaults.object(forKey: "menu.check.autoPaste") == nil {
                                defaults.set(true, forKey: "menu.check.autoPaste")
                            }
                        }
                    }
                }
                .sheet(isPresented: $showAbout) {
                    AboutView()
                }
            }
            .navigationViewStyle(StackNavigationViewStyle())
        }
    }
}
