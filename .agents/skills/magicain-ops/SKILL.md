---
name: magicain-ops
description: Magicain 生产运维工作流。用于检查或续期 magicain.com SSL/TLS 证书、通过阿里云 CAS 和 DNS 完成验证、更新 GitHub Actions 的 prod 环境证书密钥、触发 app-frontend 部署、验证生产 Nginx 和实际证书，并根据新证书到期时间安排下一次续期任务；也用于后续加入 Magicain 发布、备份、告警和服务器巡检等仓库共享运维流程。涉及“证书快过期”“更新证书”“部署证书”“安排证书续期”“Magicain 运维”“生产证书”时使用。
---

# Magicain 运维

从 `magicain-harness` 仓库根目录执行 Magicain 生产运维。先读取仓库根目录的 `AGENTS.md`，保留用户已有改动，并将生产变更限制在用户明确要求的范围内。

## 选择工作流

- 处理 `magicain.com` 证书检查、续期、部署或验收时，完整读取 [references/certificate-renewal.md](references/certificate-renewal.md)，严格按其中的阶段和验收门槛执行。
- 只检查证书状态时，运行 `scripts/check-production-certificate.sh`；该脚本只输出证书元数据，不读取或打印私钥。
- 处理尚未收录的运维任务时，先检查 `docs/systems/`、`docs/quality/release-gates.md`、`.github/workflows/` 和相关脚本，向用户说明缺少专用工作流，再按仓库约定执行。完成后把可复用经验补入本 Skill 的新参考文件。

## 通用守则

1. 阿里云 CAS 与 `magicain.com` 云解析 DNS 已在同一账号，DV 证书默认使用自动 DNS 验证。优先使用阿里云 CLI、GitHub CLI 和 SSH；只有权限异常、再次跨账号或控制台专属操作必须使用网页时才使用用户指定的浏览器。
2. 在任何输出、日志或命令参数中都不得展示证书私钥、GitHub Token、AccessKey Secret 或 SSH 私钥。将敏感文件写入权限为 `0700/0600` 的临时目录，完成后删除。
3. 修改 DNS 前精确核对域名、主机记录、记录类型、旧值和新值。证书续期只修改 `_dnsauth` TXT，不改动 A、CNAME、MX 等其他记录。
4. 更新 GitHub `prod` 环境密钥和触发生产部署属于外部变更；确认用户已明确要求执行。若用户只要求检查或诊断，不执行写操作。
5. 每个阶段都用权威信号验收：公网 DNS 查询、阿里云签发状态、GitHub Actions 结论、Nginx 配置检查以及服务器 443 端口实际证书。仅看到“命令成功”不算完成。
6. 公网入口若受 ICP 备案拦截，区分“证书已部署”和“公网可访问”；使用生产服务器本机 443 端口完成证书验收，并单独报告备案问题。
7. 每次成功部署后，从生产服务器实际证书读取 `notAfter`，将名为“Magicain 证书续期”的下一次一次性任务安排在到期前 10 天。优先更新已有同名任务，不创建重复任务；不得使用固定季度循环代替实际到期时间。

## 交付结果

报告证书 ID、域名/SAN、有效期、GitHub Actions 运行链接、Nginx 验证结果、服务器实际证书指纹、下一次定时任务时间，以及仍需处理的独立风险。不得在交付中包含敏感值。
