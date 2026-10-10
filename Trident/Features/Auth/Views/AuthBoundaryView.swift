import SwiftUI

struct AuthBoundaryView: View {
  @Environment(\.auth) var auth

  var body: some View {
    VStack(spacing: 16) {
      Image(systemName: "shield.lefthalf.filled").font(.system(size: 44, weight: .semibold))
        .accessibilityLabel("Twitch Lock")
      Text("Log in to continue").font(.title2).fontWeight(.semibold)
      Text("Authenticate with Twitch to unlock this feature.").foregroundStyle(.secondary)
        .multilineTextAlignment(.center)

      Button {
        haptics.generate(.impactLight)
        auth.logIn()
      } label: {
        Text(auth.isBusy ? "Logging in…" : "Log in with Twitch")
          .frame(maxWidth: .infinity)
      }
      .disabled(auth.isBusy)
      .buttonStyle(.primary(color: .twitchPurple))

      if let errorMessage = auth.errorMessage {
        Text(errorMessage).font(.footnote).foregroundStyle(.red).transition(.opacity)
      }
    }
    .padding(24)
    .padding()
  }
}
