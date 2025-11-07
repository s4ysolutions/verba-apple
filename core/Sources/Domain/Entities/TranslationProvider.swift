public struct TranslationProvider: Codable, Hashable, Identifiable, Sendable {
    // Stable identifier, e.g., "openai", "google"
    public let id: String
    public let displayName: String


    public init(id: String, displayName: String) {
        self.id = id
        self.displayName = displayName
    }
}
