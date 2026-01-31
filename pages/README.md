# 隐私政策配置指南

## 📄 文件说明

- `privacy-policy.html` - 简记账隐私政策（已更新联系邮箱和 GitHub 仓库链接）

## 🚀 部署方式

### 方式一：GitHub Pages（推荐）

1. **启用 GitHub Pages**
   - 访问：https://github.com/harrysxu/jizhang_ios/settings/pages
   - Source: Deploy from a branch
   - Branch: 选择 `ui_v2` 分支（或 `main` 分支）
   - Folder: 选择 `/ (root)`
   - 点击 Save

2. **提交代码**
   ```bash
   git add pages/
   git commit -m "添加隐私政策页面"
   git push origin ui_v2
   ```

3. **访问地址**（约 1-2 分钟后生效）
   ```
   https://harrysxu.github.io/jizhang_ios/pages/privacy-policy.html
   ```

4. **在 App Store Connect 填写此 URL**

### 方式二：自定义域名

如果你有自己的域名，可以使用自定义域名：

1. 在 GitHub Pages 设置中配置自定义域名
2. 配置 DNS CNAME 记录指向 `harrysxu.github.io`
3. 等待 DNS 生效（通常 10-60 分钟）

### 方式三：其他托管平台

你也可以将 `privacy-policy.html` 上传到：
- Notion（导出为公开页面）
- Gitee Pages
- Vercel
- Netlify
- 自己的服务器

## ✅ App Store Connect 配置

1. 登录 [App Store Connect](https://appstoreconnect.apple.com)
2. 选择你的 App → App 信息
3. 找到"隐私政策 URL"字段
4. 填入：`https://harrysxu.github.io/jizhang_ios/pages/privacy-policy.html`
5. 保存

## 📝 隐私政策内容

当前隐私政策包含以下要点：

- ✅ 不收集任何个人信息
- ✅ 数据仅存储在用户设备和 iCloud
- ✅ 使用的 Apple 服务说明（CloudKit、StoreKit、SiriKit、WidgetKit）
- ✅ 订阅和付费说明
- ✅ 数据安全措施
- ✅ 用户权利说明
- ✅ 联系方式（邮箱 + GitHub）
- ✅ 符合中国法律法规要求

## 🔄 更新隐私政策

如果需要更新隐私政策：

1. 修改 `pages/privacy-policy.html` 文件
2. 更新"最后更新"日期
3. 提交并推送到 GitHub
4. GitHub Pages 会自动更新（约 1-2 分钟）

## 📞 联系信息

- **邮箱**：ailehuoquan@163.com
- **GitHub**：https://github.com/harrysxu/jizhang_ios

## ⚠️ 注意事项

1. **URL 必须公开可访问**：App Store 审核时会检查 URL 是否可以访问
2. **不能使用 localhost 或内网地址**
3. **建议使用 HTTPS**：GitHub Pages 默认支持 HTTPS
4. **保持政策更新**：重大功能更新时记得同步更新隐私政策
