import SwiftUI

struct DataRecoveryView: View {
    let message: String
    let canExportRecoveryPackage: Bool
    let onRetry: () -> Void
    let onExportRecoveryPackage: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
            Image(systemName: "externaldrive.badge.exclamationmark")
                .font(.system(size: 42, weight: .medium))
                .foregroundStyle(Color.brandCoral)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 8) {
                Text("账本暂时无法打开")
                    .font(.title2.bold())
                    .fixedSize(horizontal: false, vertical: true)
                Text("原始数据仍保留在此设备，我们没有创建空白账本覆盖它。")
                    .font(.body)
                    .foregroundStyle(Color.brandMuted)
                    .fixedSize(horizontal: false, vertical: true)
                Text(message)
                    .font(.footnote)
                    .foregroundStyle(Color.brandMuted)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Button("重试", action: onRetry)
                .buttonStyle(.borderedProminent)
                .tint(.primaryBlue)
                .controlSize(.large)

            if canExportRecoveryPackage {
                Button("导出恢复包", action: onExportRecoveryPackage)
                    .buttonStyle(.bordered)
                    .controlSize(.large)
            }

            Text("如果问题持续存在，请保留 App 并联系支持。不要删除 App，否则本地数据可能随之移除。")
                .font(.footnote)
                .foregroundStyle(Color.brandMuted)
                .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: 520, alignment: .leading)
            .padding(32)
        }
    }
}
