import SwiftUI

struct TranslatingText: View {
    @Binding var text: String
    var focused: FocusState<Bool>.Binding

    var body: some View {
        TextEditor(text: $text)
            .textSelection(.enabled)
            .font(.system(.body, design: .default))
            .frame(maxWidth: .infinity, alignment: .leading)
            .focused(focused)
    }
}
