import SwiftUI

struct AppBackgroundView: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color("AppBackground"),
                    Color("AppPrimary").opacity(0.12),
                    Color("AppBackground").opacity(0.92),
                    Color("AppAccent").opacity(0.08)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            AppAmbientOrbs()

            GeometryReader { geo in
                let cols = Int(geo.size.width / 36) + 1
                let rows = Int(geo.size.height / 36) + 1
                Canvas { context, _ in
                    var path = Path()
                    for row in 0..<rows {
                        for col in 0..<cols {
                            let x = CGFloat(col) * 36 + 10
                            let y = CGFloat(row) * 36 + 10
                            path.addEllipse(in: CGRect(x: x, y: y, width: 2.5, height: 2.5))
                        }
                    }
                    context.fill(path, with: .color(Color("AppTextPrimary").opacity(0.14)))
                }
            }
            .drawingGroup()
        }
        .ignoresSafeArea()
    }
}
