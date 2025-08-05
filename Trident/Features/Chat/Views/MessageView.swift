//
//  MessageView.swift
//  Trident
//
//  Created by Burak Duruk on 2025-08-04.
//

import SwiftUI

struct MessageView: View {
    let message: Message

    var body: some View {
        HStack {
            VStack(alignment: .trailing, spacing: 4) {
                Text(message.displayName).foregroundStyle(Color(hex: message.color))
                Text(message.body)
                    .padding(12)
                    .background(Color.blue)
                    .foregroundColor(.white)

                Text(
                    message.timestamp,
                    style: .time
                )
                .font(.caption2)
                .foregroundColor(.gray)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

#Preview(traits: .sizeThatFitsLayout) {
    Group {
        MessageView(
            message: Message(
                id: "Test",
                color: "#FFF500",
                displayName: "forsen",
                emotes: [],
                badges: [],
                timestamp: Date.now,
                body: "Hello I'm forasdasdasasdasdasdasdasdasdasdadasdasdasdasdasdsen"
            )
        ).preferredColorScheme(.dark)

        MessageView(
            message: Message(
                id: "Test",
                color: "#FFF500",
                displayName: "forsen",
                emotes: [],
                badges: [],
                timestamp: Date.now,
                body: "Hello I'm forsen"
            )
        ).preferredColorScheme(.light)
    }
}
