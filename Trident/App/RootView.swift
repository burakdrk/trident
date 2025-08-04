//
//  RootView.swift
//  Trident
//
//  Created by Burak Duruk on 2025-07-28.
//

import SwiftUI

struct RootView: View {
    @State private var token: String?
    @State private var isFetchDone: Bool = false
    #if PLUS
    @State private var tm = GQLTokenManager(storage: TokenStorageService())
    #endif

    var body: some View {
        NavigationStack {
            VStack {
                if !isFetchDone {
                    Text("Fetching...")
                }

                if let token = token {
                    Text("Token received:\n\(token)")
                } else {
                    Text("Couldn't get token...")
                }
            }
            .padding()
            .frame(maxHeight: .infinity)
            .task {
                #if PLUS
                if let token = try? await tm.getToken() {
                    self.token = token.value
                    self.isFetchDone = true
                }
                #endif
            }
            .overlay(alignment: .bottom) {
                CustomTabBar().transition(.offset(y: 300))
            }
        }
    }
}

#Preview {
    RootView()
}
