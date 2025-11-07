public enum TranslationQuality: String, CaseIterable, Identifiable, Sendable {
    case Fast
    case Optimal
    case Thinking

    public var id: String { rawValue }
}
