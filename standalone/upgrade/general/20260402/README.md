# 20260402 AIBI Global Default Model Config

- 文档目录：`docs/AIBI默认模型全局配置｜上线后配置与测试手册.md`
- 本次变更为 AIBI 增加了一个全局默认模型配置项：`aibi.default-chat-model`
- 该配置项用于解决新租户初始无模型时无法顺利创建智能体的问题
- 配置值支持两类标识：
  - 内置模型枚举名，例如 `QWEN_3_235B`
  - 模型管理中的 `modelId`，例如 `deepseek-v3`
- 文档已补充端到端配置示例，包含：
  - 先在模型管理中确认已有 `chat` 模型的 `modelId`
  - 再在 `基础设施 -> 配置管理` 中新增 `aibi.default-chat-model`
  - 最后新建 `SYS_CHAT_BI` 应用验证根链路、子 skill 和模型下拉默认项
- 文档中的实测示例使用了本地现成模型：`qwen2.5-72b-instruct`
