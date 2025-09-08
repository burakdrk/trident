# Trident for Twitch

A native iOS client for Twitch built with SwiftUI and some UIKit.

## ⚠️ Work in Progress

This project is currently under active development and is not yet ready for production use. Features may be incomplete, APIs may change, and bugs are expected. Use at your own discretion.

## Features (So far)

- 🔐 Secure OAuth authentication with Twitch
- 💬 Live chat through IRC, built with UIKit for performance and efficiency
- 🎭 Third party emote support
- 🔍 Search functionality for channels
- 🎨 Customizable themes and accent colors

## Requirements

- iOS 18.0+
- Xcode 16.0+
- Swift 6.0+

## Architecture

Trident follows a clean architecture pattern with:

- **MVVM + Store Pattern**: Centralized state management with reactive stores
- **SwiftUI**: Modern declarative UI framework
- **UIKit**: Performance-critical chat/emote rendering
- **Swift Concurrency**: Modern async/await patterns for data flow
- **Modular Design**: Feature-based organization for maintainability

## Key Components

- **Core**: Shared utilities, networking, storage, and extensions
- **Features**: Modular feature implementations (Auth, Chat, Stream, etc.)
- **Models**: Data models and entities
- **Navigation**: App routing and navigation logic

## Getting Started

1. Clone the repository
2. Open `Trident.xcodeproj` in Xcode
4. Build and run the project

## Third-Party Integration

- BTTV, FrankerFaceZ and 7TV for emotes
- recent-messages.robotty.de for recent messages

## Contributing

This project is currently in development. Contributions, issues, and feature requests are welcome.

## License

[License information to be added]
