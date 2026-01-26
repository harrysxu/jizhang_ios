//
//  BudgetProgressBar.swift
//  jizhang
//
//  Created by Cursor on 2026/1/24.
//

import SwiftUI

struct BudgetProgressBar: View {
    let progress: Double
    var maxProgress: Double = 1.2
    var height: CGFloat = 12
    var showOverflow: Bool = true
    
    private var displayProgress: Double {
        min(progress, maxProgress)
    }
    
    private var progressColor: Color {
        if progress >= 1.0 {
            return .expenseRed
        } else if progress >= 0.9 {
            return .warningOrange
        } else if progress >= 0.8 {
            return .warningOrange
        } else {
            return .incomeGreen
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // 背景
                RoundedRectangle(cornerRadius: height / 2)
                    .fill(Color(.systemGray5))
                
                // 进度条 (使用渐变,参考UI样式)
                RoundedRectangle(cornerRadius: height / 2)
                    .fill(
                        LinearGradient(
                            colors: [progressColor, progressColor.opacity(0.7)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: geometry.size.width * CGFloat(displayProgress / maxProgress))
                    .animation(.spring(response: 0.5, dampingFraction: 0.8), value: progress)
            }
        }
        .frame(height: height)
    }
}

#Preview {
    VStack(spacing: Spacing.l) {
        VStack(alignment: .leading, spacing: Spacing.s) {
            Text("安全 (50%)")
                .font(.caption)
            BudgetProgressBar(progress: 0.5)
        }
        
        VStack(alignment: .leading, spacing: Spacing.s) {
            Text("注意 (85%)")
                .font(.caption)
            BudgetProgressBar(progress: 0.85)
        }
        
        VStack(alignment: .leading, spacing: Spacing.s) {
            Text("预警 (95%)")
                .font(.caption)
            BudgetProgressBar(progress: 0.95)
        }
        
        VStack(alignment: .leading, spacing: Spacing.s) {
            Text("超支 (110%)")
                .font(.caption)
            BudgetProgressBar(progress: 1.1)
        }
    }
    .padding()
}
