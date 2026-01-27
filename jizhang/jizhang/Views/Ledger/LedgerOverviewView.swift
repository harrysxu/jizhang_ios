//
//  LedgerOverviewView.swift
//  jizhang
//
//  Created by Cursor on 2026/1/25.
//

import SwiftUI
import SwiftData

/// 账本统计概览页面
struct LedgerOverviewView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    let ledger: Ledger
    
    @State private var showEditLedger = false
    @State private var showExportOptions = false
    
    private var viewModel: LedgerViewModel {
        LedgerViewModel(modelContext: modelContext)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 自定义导航栏
            FlexibleSheetNavigationBar(
                title: "账本详情",
                leftText: "关闭",
                rightText: "编辑",
                leftAction: {
                    dismiss()
                },
                rightAction: {
                    showEditLedger = true
                }
            )
            
            ScrollView {
                VStack(spacing: 20) {
                    // 账本基本信息卡片
                    ledgerInfoCard
                    
                    // 统计数据卡片
                    statsCards
                    
                    // 快捷操作
                    quickActions
                }
                .padding()
            }
        }
        .background(Color(.systemGroupedBackground))
        .sheet(isPresented: $showEditLedger) {
            LedgerFormSheet(ledger: ledger, viewModel: viewModel)
        }
        .sheet(isPresented: $showExportOptions) {
            exportOptionsSheet
        }
    }
    
    // MARK: - Subviews
    
    private var ledgerInfoCard: some View {
        VStack(spacing: 16) {
            // 图标和名称
            HStack(spacing: 16) {
                // 大图标
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(hex: ledger.colorHex).opacity(0.15))
                        .frame(width: 80, height: 80)
                    
                    Image(systemName: ledger.iconName)
                        .font(.system(size: 40))
                        .foregroundStyle(Color(hex: ledger.colorHex))
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(ledger.name)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    HStack(spacing: 12) {
                        Label(ledger.currencyCode, systemImage: "dollarsign.circle")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        
                        if ledger.isDefault {
                            Label("默认", systemImage: "star.fill")
                                .font(.caption)
                                .foregroundStyle(.orange)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.orange.opacity(0.1))
                                .cornerRadius(8)
                        }
                    }
                }
                
                Spacer()
            }
            
            // 创建时间
            HStack {
                Text("创建于")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Text(ledger.createdAt, style: .date)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Spacer()
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    private var statsCards: some View {
        VStack(spacing: 16) {
            // 资产统计
            HStack(spacing: 16) {
                StatCard(
                    title: "总资产",
                    value: ledger.totalAssets.formatted(.currency(code: ledger.currencyCode)),
                    icon: "banknote",
                    color: .blue
                )
                
                StatCard(
                    title: "账户数",
                    value: "\(ledger.activeAccountsCount)",
                    icon: "creditcard",
                    color: .purple
                )
            }
            
            // 交易统计
            HStack(spacing: 16) {
                StatCard(
                    title: "本月交易",
                    value: "\(ledger.thisMonthTransactionCount)笔",
                    icon: "list.bullet",
                    color: .green
                )
                
                StatCard(
                    title: "总交易",
                    value: "\(ledger.transactions.count)笔",
                    icon: "chart.line.uptrend.xyaxis",
                    color: .orange
                )
            }
        }
    }
    
    private var quickActions: some View {
        VStack(spacing: 12) {
            Text("快捷操作")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(spacing: 0) {
                ActionButton(
                    title: "导出数据",
                    icon: "square.and.arrow.up",
                    action: {
                        showExportOptions = true
                    }
                )
                
                Divider()
                    .padding(.leading, 52)
                
                ActionButton(
                    title: ledger.isArchived ? "取消归档" : "归档账本",
                    icon: ledger.isArchived ? "tray.and.arrow.up" : "tray.and.arrow.down",
                    action: toggleArchive
                )
                
                if !ledger.isDefault {
                    Divider()
                        .padding(.leading, 52)
                    
                    ActionButton(
                        title: "设为默认账本",
                        icon: "star",
                        action: setAsDefault
                    )
                }
            }
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        }
    }
    
    private var exportOptionsSheet: some View {
        VStack(spacing: 0) {
            // 自定义导航栏
            SimpleCancelNavigationBar(title: "导出选项")
            
            List {
                Button {
                    exportAsCSV()
                } label: {
                    Label("导出为CSV", systemImage: "doc.text")
                }
                
                Button {
                    exportAsJSON()
                } label: {
                    Label("导出为JSON", systemImage: "doc.badge.gearshape")
                }
            }
        }
        .background(Color(.systemGroupedBackground))
    }
    
    // MARK: - Actions
    
    private func toggleArchive() {
        ledger.isArchived.toggle()
        try? modelContext.save()
    }
    
    private func setAsDefault() {
        // 清除其他账本的默认状态
        let descriptor = FetchDescriptor<Ledger>()
        if let allLedgers = try? modelContext.fetch(descriptor) {
            for otherLedger in allLedgers where otherLedger.id != ledger.id {
                otherLedger.isDefault = false
            }
        }
        
        // 设置当前账本为默认
        ledger.isDefault = true
        try? modelContext.save()
    }
    
    private func exportAsCSV() {
        // TODO: 实现CSV导出
        showExportOptions = false
    }
    
    private func exportAsJSON() {
        // TODO: 实现JSON导出
        showExportOptions = false
    }
}

// MARK: - Supporting Views

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(color)
                Spacer()
            }
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

struct ActionButton: View {
    let title: String
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(.blue)
                    .frame(width: 28)
                
                Text(title)
                    .foregroundStyle(.primary)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()
        }
    }
}

#Preview {
    LedgerOverviewView(ledger: Ledger(name: "日常账本"))
        .modelContainer(for: Ledger.self)
}
