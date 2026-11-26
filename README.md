# 存钱罐

记账用的 iOS App，只记录、不存钱、不联网。

- SwiftUI，最低 iOS 18，支持 iPhone / iPad，浅色/深色自动跟随
- 数据只写在本机 Application Support 里的 `piggy-pot.json`
- 账户：名称 / 图标 / 颜色 / 初始余额，可增删改排序
- 记录：支出、收入，带账户、备注、时间；按天分组，可改可删
- 首页：总资产、本月收支、账户余额、最近记录

构建走 GitHub Actions（macos-26 + Xcode 26），产出未签名 ipa。
