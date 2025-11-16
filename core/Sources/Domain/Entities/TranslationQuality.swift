public enum TranslationQuality: String, CaseIterable, Identifiable, Sendable, Codable {
    case Fast
    case Optimal
    case Thinking

    public var id: String { rawValue }
}
