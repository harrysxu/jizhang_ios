//
//  FABButton.swift
//  jizhang
//
//  Created by Cursor on 2026/1/24.
//

import SwiftUI

struct FABButton: View {
    // MARK: - Properties
    
    let action: () -> Void
    
    // MARK: - Body
    
    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.primaryBlue, Color.primaryBlue.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 60, height: 60)
                    .shadow(color: Color.primaryBlue.opacity(0.3), radius: 8, x: 0, y: 4)
                
                Image(systemName: "plus")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(.white)
            }
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color(.systemGroupedBackground)
            .ignoresSafeArea()
        
        VStack {
            Spacer()
            HStack {
                Spacer()
                FABButton {
                    print("Add transaction")
                }
                .padding()
            }
        }
    }
}
