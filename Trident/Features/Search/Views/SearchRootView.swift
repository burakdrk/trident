//
//  SearchRootView.swift
//  Trident
//
//  Created by Burak Duruk on 2025-08-19.
//

import SwiftUI

struct SearchRootView: View {
  @Environment(\.router) private var router

  var text = ""

  var body: some View {
    Button {
      router.push(.channels(query: text))
    } label: {
      Text("Go to \(text)")
    }
  }
}

#Preview {
  SearchRootView()
}
