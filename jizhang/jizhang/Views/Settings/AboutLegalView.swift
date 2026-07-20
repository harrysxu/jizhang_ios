import SwiftUI

struct AboutLegalView: View {
    private let privacyURL = URL(string: "https://harrysxu.github.io/jizhang_ios/pages/privacy-policy.html")!
    private let termsURL = URL(string: "https://harrysxu.github.io/jizhang_ios/pages/terms-of-service.html")!
    private let eulaURL = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!
    private let supportURL = URL(string: "mailto:ailehuoquan@163.com?subject=简记账反馈")!
    private let projectURL = URL(string: "https://github.com/harrysxu/jizhang_ios")!
    private let phosphorURL = URL(string: "https://github.com/phosphor-icons/swift")!

    private var versionText: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "未知"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "未知"
        return "版本 \(version)（构建 \(build)）"
    }

    var body: some View {
        List {
            Section {
                VStack(spacing: Spacing.s) {
                    Image(systemName: "book.closed.fill")
                        .font(.system(size: 42, weight: .medium))
                        .foregroundStyle(Color.brandEmerald)
                        .accessibilityHidden(true)

                    Text("简记账")
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(Color.brandInk)

                    Text("简迹")
                        .font(.subheadline)
                        .foregroundStyle(Color.brandMuted)

                    Text(versionText)
                        .font(.footnote)
                        .foregroundStyle(Color.brandMuted)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.l)
                .accessibilityElement(children: .combine)
                .accessibilityLabel("简记账，简迹，\(versionText)")
            }

            Section("法律文档") {
                externalLinkRow(
                    title: "隐私政策",
                    subtitle: "了解数据存储、iCloud 和隐私处理方式",
                    icon: "hand.raised.fill",
                    color: .brandEmerald,
                    destination: privacyURL,
                    identifier: "about.privacyPolicy"
                )
                externalLinkRow(
                    title: "服务条款",
                    subtitle: "查看使用规则、订阅和责任限制",
                    icon: "doc.text.fill",
                    color: .brandEmerald,
                    destination: termsURL,
                    identifier: "about.termsOfService"
                )
                externalLinkRow(
                    title: "Apple 标准 EULA",
                    subtitle: "查看 Apple 标准最终用户许可协议",
                    icon: "doc.badge.gearshape.fill",
                    color: .brandMuted,
                    destination: eulaURL,
                    identifier: "about.appleEULA"
                )
            }

            Section("数据与风险") {
                NavigationLink {
                    FinancialDisclaimerView()
                } label: {
                    internalRow(
                        title: "财务信息免责声明",
                        subtitle: "本应用不提供投资、税务或法律建议",
                        icon: "exclamationmark.shield.fill",
                        color: .brandCoral
                    )
                }
                .accessibilityIdentifier("about.financialDisclaimer")

                NavigationLink {
                    CloudDataPolicyView()
                } label: {
                    internalRow(
                        title: "iCloud 与数据安全",
                        subtitle: "了解本地存储、CloudKit 同步和备份责任",
                        icon: "icloud.and.arrow.up.fill",
                        color: .brandEmerald
                    )
                }
                .accessibilityIdentifier("about.cloudDataPolicy")
            }

            Section("帮助与反馈") {
                externalLinkRow(
                    title: "联系支持",
                    subtitle: "反馈问题或提交建议",
                    icon: "envelope.fill",
                    color: .brandEmerald,
                    destination: supportURL,
                    identifier: "about.contactSupport"
                )
                externalLinkRow(
                    title: "项目主页",
                    subtitle: "查看项目说明和公开问题跟踪",
                    icon: "chevron.left.forwardslash.chevron.right",
                    color: .brandMuted,
                    destination: projectURL,
                    identifier: "about.projectHome"
                )
            }

            Section("第三方许可") {
                externalLinkRow(
                    title: "Phosphor Icons",
                    subtitle: "图标库及其开源许可",
                    icon: "sparkles",
                    color: .brandMuted,
                    destination: phosphorURL,
                    identifier: "about.phosphorLicense"
                )
                Text("本应用使用 Apple 系统框架和 Phosphor Icons。第三方组件的许可归其各自作者所有。")
                    .font(.footnote)
                    .foregroundStyle(Color.brandMuted)
                    .padding(.vertical, Spacing.xs)
            }
        }
        .navigationTitle("关于与法律")
        .navigationBarTitleDisplayMode(.inline)
        .font(.body)
    }

    private func internalRow(
        title: String,
        subtitle: String,
        icon: String,
        color: Color
    ) -> some View {
        HStack(spacing: Spacing.m) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(color)
                .frame(width: 28)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .foregroundStyle(Color.brandInk)
                Text(subtitle)
                    .font(.footnote)
                    .foregroundStyle(Color.brandMuted)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title)，\(subtitle)")
    }

    private func externalLinkRow(
        title: String,
        subtitle: String,
        icon: String,
        color: Color,
        destination: URL,
        identifier: String
    ) -> some View {
        Link(destination: destination) {
            HStack(spacing: Spacing.m) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(color)
                    .frame(width: 28)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .foregroundStyle(Color.brandInk)
                    Text(subtitle)
                        .font(.footnote)
                        .foregroundStyle(Color.brandMuted)
                }

                Spacer(minLength: Spacing.s)

                Image(systemName: "arrow.up.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.brandMuted)
                    .accessibilityHidden(true)
            }
        }
        .accessibilityIdentifier(identifier)
        .accessibilityHint("打开外部链接")
    }
}

struct FinancialDisclaimerView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.l) {
                Text("财务信息免责声明")
                    .font(.title2.weight(.semibold))

                disclaimerSection(
                    title: "仅用于记录和整理",
                    text: "简记账用于记录个人收支、预算和账本信息。应用中的统计、趋势、预算余量和建议仅基于您输入的数据进行计算。"
                )
                disclaimerSection(
                    title: "不构成专业建议",
                    text: "本应用不提供投资、证券、保险、税务、会计或法律建议，也不推荐任何金融产品。涉及付款、投资、报税或其他重要决定前，请咨询具备资质的专业人士。"
                )
                disclaimerSection(
                    title: "请核对重要数据",
                    text: "自动计算结果可能受到输入错误、分类选择、日期范围、汇率或系统同步状态影响。进行付款、对账、申报或投资决策前，请使用原始凭证和账户记录核对。"
                )
                disclaimerSection(
                    title: "同步和备份责任",
                    text: "iCloud 同步依赖 Apple 账户、设备状态和网络服务。请定期使用应用提供的导出或备份功能保存重要数据。"
                )
            }
            .padding(Spacing.l)
        }
        .navigationTitle("财务信息免责声明")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func disclaimerSection(title: String, text: String) -> some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            Text(title)
                .font(.headline)
            Text(text)
                .foregroundStyle(Color.brandMuted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct CloudDataPolicyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.l) {
                Text("iCloud 与数据安全")
                    .font(.title2.weight(.semibold))

                policySection(
                    title: "本地优先",
                    text: "账本数据首先保存在设备上。没有登录 iCloud 或 iCloud 暂不可用时，应用仍可使用本地数据。"
                )
                policySection(
                    title: "CloudKit 同步",
                    text: "登录 iCloud 后，系统会根据设备和账户状态使用 Apple CloudKit 同步数据。同步由 Apple 的系统服务处理，应用不会读取或保存您的 Apple ID 密码。"
                )
                policySection(
                    title: "导出和恢复",
                    text: "导出文件由您决定保存位置和分享对象。恢复页面提供的是原始数据保护能力，不会因为会员状态而收费。"
                )
                policySection(
                    title: "删除前请备份",
                    text: "删除账本、重置数据或卸载应用前，请先完成导出或备份。CloudKit 的同步状态和设备备份由 Apple 系统管理。"
                )
            }
            .padding(Spacing.l)
        }
        .navigationTitle("iCloud 与数据安全")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func policySection(title: String, text: String) -> some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            Text(title)
                .font(.headline)
            Text(text)
                .foregroundStyle(Color.brandMuted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    NavigationStack {
        AboutLegalView()
    }
}
