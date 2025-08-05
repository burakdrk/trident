//
//  ChatView.swift
//  Trident
//
//  Created by Burak Duruk on 2025-08-03.
//

import SwiftUI

struct ChatView: View {
    @State private var viewModel = LiveChatViewModel()

    private let bottomViewID = "bottomViewID"
    private var observedValues: [String?] {
        [viewModel.messages.last?.id, String(viewModel.isPaused)]
    }

    var body: some View {
        VStack {
            ZStack(alignment: .bottom) {
                ScrollViewReader { scrollViewProxy in
                    ScrollView {
                        LazyVStack(spacing: 6) {
                            ForEach(viewModel.messages) { msg in
                                MessageView(message: msg)
                            }

                            // An invisible view at the bottom of the list.
                            // We use its visibility to determine if we are at the bottom.
                            HStack { Spacer() }
                                .id(bottomViewID)
                                .frame(height: 1)
                                .onAppear {
                                    // The user scrolled to the very bottom.
                                    viewModel.isPaused = false
                                }
                                .onDisappear {
                                    // The user has scrolled up
                                    viewModel.isPaused = true
                                }
                        }
                        .padding(.horizontal)
                    }
                    .onAppear {
                        // When the view first appears, scroll to the bottom.
                        scrollViewProxy.scrollTo(bottomViewID, anchor: .bottom)
                    }
                    .onChange(of: observedValues) {
                        if !viewModel.isPaused {
                            scrollViewProxy.scrollTo(bottomViewID, anchor: .bottom)
                        }
                    }
                }

                if viewModel.isPaused {
                    ScrollButtonView(
                        action: { viewModel.isPaused = false },
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
