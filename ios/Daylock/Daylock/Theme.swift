import SwiftUI

enum Theme {
    static let paper = Color(red: 0.953, green: 0.937, blue: 0.902)
    static let ink = Color(red: 0.110, green: 0.098, blue: 0.082)
    static let clay = Color(red: 0.769, green: 0.361, blue: 0.149)
    static let clayDeep = Color(red: 0.545, green: 0.239, blue: 0.090)
    static let card = Color(red: 0.992, green: 0.980, blue: 0.961)
    static let line = Color(red: 0.110, green: 0.098, blue: 0.082).opacity(0.12)
}

struct ClayButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.body.weight(.semibold))
            .foregroundStyle(Theme.card)
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
            .background(Theme.clayDeep, in: Capsule())
            .opacity(configuration.isPressed ? 0.82 : 1)
    }
}

struct PaperScreen<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        content
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Theme.paper)
    }
}
