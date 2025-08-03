//
//  CustomTabBar.swift
//  Trident
//
//  Created by Burak Duruk on 2025-07-30.
//

import SwiftUI

struct CustomTabBar: View {
    @State private var selectedIndex: Int = 0

    let icons = ["heart.fill", "calendar", "magnifyingglass", "person.fill"]

    var body: some View {
        HStack(spacing: 50) {
            ForEach(0..<icons.count, id: \.self) { i in
                Button(action: {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    selectedIndex = i
                }) {
                    Image(systemName: icons[i])
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(selectedIndex == i ? .accent : .gray)
                        .frame(width: 36.0, height: 36)
                        .background(
                            Circle()
                                .fill(
                                    selectedIndex == i
                                    ? Color.accentColor.opacity(0.3) : Color.clear
                                )
                        )
                }
            }
        }
        .padding(.horizontal, 30)
        .padding(.vertical, 12)
        .background(Color.black)
        .clipShape(Capsule())
        .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 4)
    }
}

#Preview {
    CustomTabBar()
}
