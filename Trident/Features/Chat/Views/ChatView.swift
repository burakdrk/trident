//
//  ChatView.swift
//  Trident
//
//  Created by Burak Duruk on 2025-08-03.
//

import SwiftUI

struct ChatView: View {
    @State private var viewModel = LiveChatViewModel()

    var body: some View {
        VStack {
            ZStack(alignment: .bottom) {
                ScrollView {
                    LazyVStack(spacing: 6) {
                        ForEach(viewModel.messages) { msg in
                            MessageView(message: msg)
                        }
                    }
                    .padding(.horizontal)
                }
                .defaultScrollAnchor(.bottom)
                .scrollPosition($viewModel.position)
                .onChange(of: viewModel.messages) {
                    if !viewModel.isPaused {
                        viewModel.position.scrollTo(edge: .bottom)
                    }
                }

                if viewModel.isPaused {
                    ScrollButtonView(
                        action: { viewModel.position.scrollTo(edge: .bottom) },
                        newMessageCount: viewModel.newMessageCount
                    )
                }
            }
        }
        .task {
            try? await viewModel.beginConsumingMessageStream()
        }
    }
}

#Preview {
    ChatView()
}
