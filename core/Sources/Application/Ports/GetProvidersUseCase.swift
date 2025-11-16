public protocol GetProvidersUseCase: Sendable {
    func providers() async -> Result<[TranslationProvider], TranslationError>
}
