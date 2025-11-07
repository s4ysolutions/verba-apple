public protocol GetProvidersUseCase: Sendable {
    func providers() async -> Result<[TranslationProvider], ApiError>
}
