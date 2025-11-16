import SwiftUI

struct LoadingApp: View {
    private let geo: GeometryProxy

    init(geo: GeometryProxy) {
        self.geo = geo
    }

    var body: some View {
        VStack {
            Spacer()
            ProgressView("Loading...")
                .frame(maxWidth: .infinity, alignment: .center)
            Spacer()
        }
        .frame(height: geo.size.height)
    }
}
