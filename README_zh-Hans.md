# LuLu-Lockdown

[English](README.md) | [正體中文](README_zh-Hant.md)

LuLu-Lockdown 是基于 LuLu 和 Lockdown-Mac 思路扩展的 macOS 防火墙项目。

**维护者：** `john-f-m`

## 主要能力

- 首次初始化可选：
  - 使用基线放行（Apple 应用 + 已安装应用）
  - 从零初始化（不使用基线自动放行）
- 新模式：
  - `严格交互模式`：每个新的或变化的连接都要求决策
  - `静默模式`：先放行并加入待审队列，后续再选择允许/阻止
- 待审连接处理：
  - 支持逐条审查并生成允许/阻止规则
- 流量洞察：
  - 提供连接日志、端口/协议图表、IP 去向全球地图
- Lockdown-Mac 列表导入：
  - 可导入已知恶意域名/地址列表并自动启用阻止列表

## 说明文档

- 主文档：`README.md`
- GitHub Landing Page：`docs/index.html`

## 许可证

- `GPL-3.0`（见 `LICENSE.md`）
