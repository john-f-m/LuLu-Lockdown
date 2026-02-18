# LuLu-Lockdown

[English](README.md) | [简体中文](README_zh-Hans.md)

LuLu-Lockdown 是基於 LuLu 與 Lockdown-Mac 思路擴展的 macOS 防火牆專案。

**維護者：** `john-f-m`

## 主要能力

- 首次初始化可選：
  - 使用基線放行（Apple 應用 + 已安裝應用）
  - 從零初始化（不使用基線自動放行）
- 新模式：
  - `嚴格互動模式`：每個新的或變化的連線都要求決策
  - `靜默模式`：先放行並加入待審佇列，後續再選擇允許/阻止
- 待審連線處理：
  - 支援逐條審查並產生允許/阻止規則
- 流量洞察：
  - 提供連線日誌、連接埠/協定圖表、IP 去向全球地圖
- Lockdown-Mac 清單匯入：
  - 可匯入已知惡意網域/位址清單並自動啟用阻止清單

## 說明文件

- 主文件：`README.md`
- GitHub Landing Page：`docs/index.html`

## 授權

- `GPL-3.0`（見 `LICENSE.md`）
