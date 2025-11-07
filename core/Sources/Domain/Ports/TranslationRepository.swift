public protocol TranslationRepository: Sendable {
    func translate(from translationRequest: TranslationRequest) async -> Result<String, TranslationError>
    func providers() async -> Result<[TranslationProvider], ApiError>
}
