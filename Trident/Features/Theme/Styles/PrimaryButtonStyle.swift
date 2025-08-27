import SwiftUI

struct PrimaryButtonStyle: ButtonStyle {
  enum SelectedShape { case capsule, rect }

  @Environment(\.accent) private var accent
  @Environment(\.isEnabled) var isEnabled

  var color: Color?
  var shape: SelectedShape = .rect

  var clipShape: AnyShape {
    if shape == .rect {
      AnyShape(RoundedRectangle(cornerRadius: 8, style: .circular))
    } else {
      AnyShape(Capsule())
    }
  }

  var backgroundColor: Color {
    let color = (color ?? accent.color)
    if isEnabled {
      return color
    } else {
      return color.opacity(0.8)
    }
  }

  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .font(.callout.bold())
      .padding(12)
      .background(backgroundColor)
      .foregroundStyle(.white)
      .clipShape(clipShape)
      .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
      .animation(
        .easeInOut(duration: 0.15),
        value: configuration.isPressed
      )
  }
}

extension ButtonStyle where Self == PrimaryButtonStyle {
  static func primary(color: Color?, shape: Self.SelectedShape = .rect) -> Self {
    PrimaryButtonStyle(color: color, shape: shape)
  }
}
