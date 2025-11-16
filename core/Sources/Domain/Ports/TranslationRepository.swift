public protocol TranslationRepository: Sendable {
    func translate(from translationRequest: TranslationRequest) async -> Result<String, ApiError>
    func providers() async -> Result<[TranslationProvider], ApiError>
}
