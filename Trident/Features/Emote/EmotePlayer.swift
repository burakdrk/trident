//
//  EmotePlayer.swift
//  Trident
//
//  Created by Burak Duruk on 2025-08-08.
//

/// https://github.com/SDWebImage/SDWebImageSwiftUI/issues/300#issuecomment-2440050558
/// Referenced from the above issue, to synchronize similar image playback

import OrderedCollections
import SDWebImage

private struct WeakBox<T: AnyObject> {
    weak var value: T?
    init(value: T) {
        self.value = value
    }
}

@MainActor
final class EmotePlayer {
    private static var players: [URL: EmotePlayer] = [:]
    typealias ViewIdentifier = ObjectIdentifier

    let emote: Emote
    private var views: OrderedDictionary<ViewIdentifier, WeakBox<EmoteAttachmentView>> = [:]
    private var player: SDAnimatedImagePlayer?
    private(set) var image: UIImage?

    init(emote: Emote) {
        self.emote = emote
    }

    private func setAnimatedImage(_ image: SDAnimatedImage) {
        guard player == nil else { return }
        player = .init(provider: image)
        player?.animationFrameHandler = { [weak self] _, image in
            guard let self else { return }
            self.image = image
            for view in views.values {
                view.value?.layer.setNeedsDisplay()
            }
        }
        playPause()
    }

    private func registerView(_ view: EmoteAttachmentView) {
        let identifier = Self.viewIdentifier(view)
        guard views[identifier] == nil else { return }
        views[identifier] = .init(value: view)
        playPause()
    }

    private func unregisterView(identifier: ViewIdentifier) {
        guard views[identifier] != nil else { return }
        views[identifier] = nil
        playPause()
    }

    private func playPause() {
        guard let player else { return }
        if player.isPlaying, views.isEmpty {
            image = nil
            player.stopPlaying()
        } else if !player.isPlaying, !views.isEmpty {
            player.startPlaying()
        }
    }

    static func setAnimatedImage(_ image: SDAnimatedImage, for emote: Emote) {
        player(for: emote).setAnimatedImage(image)
    }

    static func registerView(_ view: EmoteAttachmentView, for emote: Emote) {
        player(for: emote).registerView(view)
    }

    static func unregisterView(_ view: EmoteAttachmentView, for emote: Emote) {
        unregisterView(identifier: viewIdentifier(view), for: emote)
    }

    static func unregisterView(identifier: ViewIdentifier, for emote: Emote) {
        player(for: emote).unregisterView(identifier: identifier)
    }

    static func player(for emote: Emote, view: EmoteAttachmentView) -> EmotePlayer? {
        guard let player = players[emote.url] else { return nil }
        guard player.views[viewIdentifier(view)] != nil else { return nil }
        return player
    }

    private static func player(for emote: Emote) -> EmotePlayer {
        if let player = players[emote.url] {
            return player
        }
        let player = EmotePlayer(emote: emote)
        Self.players[emote.url] = player
        return player
    }

    nonisolated static func viewIdentifier(_ view: EmoteAttachmentView) -> ViewIdentifier {
        .init(view)
    }
}
