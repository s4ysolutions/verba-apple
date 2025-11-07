public enum TranslationMode: String, CaseIterable, Identifiable, Sendable {
    case TranslateSentence = "translate"
    case ExplainWords = "explain"
    case Auto = "auto"

    public var id: String { rawValue }
}
