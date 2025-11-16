import SwiftUI

struct TranslatedText: View {
    @Binding var text: String

    var body: some View {
        TextEditor(text: $text)
            .textSelection(.enabled)
            .font(.system(.body, design: .default))
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}
