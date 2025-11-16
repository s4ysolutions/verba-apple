import OSLog

public struct TranslationRequest: Sendable {
    public let sourceText: String
    public let sourceLang: String?
    public let targetLang: String
    public let mode: TranslationMode
    public let provider: TranslationProvider
    public let quality: TranslationQuality
    public let ipa: Bool

    private init(
        sourceText: String,
        sourceLang: String?,
        targetLang: String,
        mode: TranslationMode,
        provider: TranslationProvider,
        quality: TranslationQuality,
        ipa: Bool,
    ) {
        self.sourceText = sourceText
        self.sourceLang = sourceLang
        self.targetLang = targetLang
        self.mode = mode
        self.provider = provider
        self.quality = quality
        self.ipa = ipa
    }

    public static func create(
        sourceText: String,
        sourceLang: String,
        targetLang: String,
        mode: TranslationMode = .Auto,
        provider: TranslationProvider,
        quality: TranslationQuality = .Optimal,
        ipa: Bool
    ) -> Result<TranslationRequest, TranslationError> {
        // Validate sourceText
        let trimmedText = sourceText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else {
            logger.error("Empty source text")
            return .failure(.validation(.emptyString))
        }

        let trimmedSourceLang = sourceLang.trimmingCharacters(in: .whitespacesAndNewlines)


        guard trimmedSourceLang.count == 0 || trimmedSourceLang.count <= 16 else {
            logger.error("source lang too long: \(trimmedSourceLang)")
            return .failure(.validation(.langTooLong(trimmedSourceLang)))
        }
        guard trimmedSourceLang.count == 0 || trimmedSourceLang.count > 2 else {
            logger.error("source lang too short: \(trimmedSourceLang)")
            return .failure(.validation(.langTooShort(trimmedSourceLang)))
        }

        let trimmedTargetLang = targetLang.trimmingCharacters(in: .whitespacesAndNewlines)

        guard trimmedTargetLang.count <= 16 else {
            logger.error("target lang too long: \(trimmedTargetLang)")
            return .failure(.validation(.langTooLong(trimmedTargetLang)))
        }
        guard trimmedTargetLang.count > 2 else {
            logger.error("target lang too short: \(trimmedTargetLang)")
            return .failure(.validation(.langTooShort(trimmedTargetLang)))
        }

        // let modeResult = mode //TranslationMode.from(string: mode)
        // let qualityResult = TranslationQuality.from(string: quality)
        // let providerResult = TranslationProvider.from(string: provider)

        // Short-circuit on any failure
        // switch providerResult {
        // case let .success(provider):
        // All parsed: Create and succeed
        let request = TranslationRequest(
            sourceText: trimmedText,
            sourceLang: trimmedSourceLang.count == 0 ? nil : trimmedSourceLang,
            targetLang: trimmedTargetLang,
            mode: mode,
            provider: provider,
            quality: quality,
            ipa: ipa
        )
        return .success(request)

        // case let .failure(providerErr):
        // return .failure(.validation(providerErr))
        // }
    }

    private static let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "verba-masos", category: "TranslationRequest")
}
