//
//  MessageView.swift
//  Trident
//
//  Created by Burak Duruk on 2025-08-04.
//

import SDWebImageSwiftUI
import SwiftUI
import WrappingStack

struct MessageView: View {
    let message: RenderableMessage

    var body: some View {
        WrappingHStack(id: \.id, alignment: .leading) {
            ForEach(message.chunks, id: \.id) { msg in
                if let emote = msg.emote {
                    AnimatedImage(url: emote.url)
                        .indicator(.activity)
                        .resizable()
                        .frame(
                            width: CGFloat(emote.width ?? 32),
                            height: CGFloat(emote.height ?? 32)
                        )
                        .padding(.trailing, 5)
                } else {
                    if msg.type == .body {
                        Text(msg.text + " ")
                    } else if msg.type == .displayName {
                        Text(msg.text + ": ")
                            .foregroundStyle(
                                Color(hex: message.details.color)
                            )
                            .fontWeight(.bold)
                    }
                }
            }
        }
    }
}

#Preview(traits: .sizeThatFitsLayout) {
    MessageView(
        message: .init(
            details: .init(
                id: "Test",
                color: "#FFFFFF",
                displayName: "forsen",
                emotes: [],
                badges: [],
                timestamp: Date.now,
                body: "Hello I'm forsen"
            ),
            chunks: [
                .init(id: "4", type: .displayName, text: "forsen"),
                .init(id: "1", type: .body, text: "Hello"),
                .init(id: "2", type: .body, text: "I'm"),
                .init(id: "3", type: .body, text: "forsen"),
            ]
        )
    )
}
