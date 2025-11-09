import SwiftUI

struct AboutView: View {
    private var appName: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String ??
        Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String ??
        "App"
    }

    private var version: String {
        let v = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "?"
        let b = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "?"
        return "\(v) (\(b))"
    }

    var body: some View {
        VStack(spacing: 20) {
            Image(uiImage: UIApplication.shared.applicationIconImage ?? UIImage())
                .resizable()
                .frame(width: 80, height: 80)
                .cornerRadius(16)

            Text(appName)
                .font(.title3)
            Text("Version \(version)")
                .foregroundStyle(.secondary)

            Link("Privacy Policy", destination: URL(string: "https://YOUR_PRIVACY_URL_HERE")!)
                .padding(.top, 8)

            Spacer(minLength: 20)
        }
        .padding()
    }
}
