import SwiftUI

struct PrimaryButtonStyle: ButtonStyle {
  enum SelectedShape { case capsule, rect, circle }

  @Environment(\.accent) private var accent
  @Environment(\.themeManager) private var themeManager
  @Environment(\.isEnabled) var isEnabled

  var color: Color?
  var shape: SelectedShape = .rect
  var gradient: Bool

  var clipShape: AnyShape {
    switch shape {
    case .capsule:
      AnyShape(Capsule())
    case .rect:
      AnyShape(RoundedRectangle(cornerRadius: 8, style: .circular))
    case .circle:
      AnyShape(Circle())
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
      .foregroundStyle(.white)
      .padding(12)
      .background(themeManager.theme == .light ?
        accent.color.opacity(0.9) : accent.color.opacity(0.6)
      )
      .clipShape(clipShape)
      .glassEffect(.regular.interactive(), in: clipShape)
  }
}

extension ButtonStyle where Self == PrimaryButtonStyle {
  static func primary(
    color: Color,
    shape: Self.SelectedShape = .rect,
    gradient: Bool = false
  ) -> Self {
    PrimaryButtonStyle(color: color, shape: shape, gradient: gradient)
  }

  static func primary(shape: Self.SelectedShape = .rect, gradient: Bool = false) -> Self {
    PrimaryButtonStyle(color: nil, shape: shape, gradient: gradient)
  }
}
