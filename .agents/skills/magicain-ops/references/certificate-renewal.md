# Magicain 生产证书续期

## 目录

- [固定上下文](#固定上下文)
- [阶段 0：预检](#阶段-0预检)
- [阶段 1：准备并申请证书](#阶段-1准备并申请证书)
- [阶段 2：自动 DNS 验证](#阶段-2自动-dns-验证)
- [阶段 3：等待签发并验证证书](#阶段-3等待签发并验证证书)
- [阶段 4：安全下载和本地校验](#阶段-4安全下载和本地校验)
- [阶段 5：更新 GitHub prod 密钥](#阶段-5更新-github-prod-密钥)
- [阶段 6：触发并跟踪部署](#阶段-6触发并跟踪部署)
- [阶段 7：生产服务器验收](#阶段-7生产服务器验收)
- [阶段 8：清理和交付](#阶段-8清理和交付)
- [阶段 9：安排下一次续期任务](#阶段-9安排下一次续期任务)

## 固定上下文

| 项目 | 值 |
| --- | --- |
| 主域名 | `magicain.com` |
| 期望 SAN | `magicain.com`、`www.magicain.com` |
| 证书服务 | 阿里云数字证书管理服务 CAS，DigiCert DV |
| DNS 托管 | 阿里云云解析 DNS，与 CAS 在同一阿里云账号；默认自动 DNS 验证 |
| 仓库 | `magicain-com/magicain-harness` |
| GitHub 环境 | `prod` |
| GitHub 密钥 | `MAGICAIN_CERT_KEY`、`MAGICAIN_CERT_PEM` |
| 部署工作流 | `.github/workflows/deploy-app-frontend.yml` |
| 默认分支 | 运行时查询，不硬编码；当前通常为 `main` |
| 生产 SSH 别名 | `prod-app-frontend`（本机存在时使用） |
| 生产目录 | `/opt/magicain` |
| Nginx 容器 | `magicain-nginx-proxy-1` |

个人测试 DV 证书通常只有约 3 个月有效期。每次成功部署后，在实际到期时间前 10 天安排下一次续期任务。

## 阶段 0：预检

1. 从仓库根目录读取 `AGENTS.md` 和 `.github/workflows/deploy-app-frontend.yml`，确认环境名、密钥名和部署目标没有变化。
2. 检查工具：`aliyun`、`gh`、`jq`、`openssl`、`dig`、`ssh`。
3. 运行：

   ```bash
   .agents/skills/magicain-ops/scripts/check-production-certificate.sh
   ```

4. 检查认证身份，不输出密钥：

   ```bash
   aliyun sts GetCallerIdentity
   aliyun alidns DescribeDomainInfo --DomainName magicain.com
   aliyun alidns DescribeDomainRecords --DomainName magicain.com --SearchMode COMBINATION --RRKeyWord _dnsauth --TypeKeyWord TXT --PageNumber 1 --PageSize 100
   gh auth status
   gh repo view magicain-com/magicain-harness --json nameWithOwner,defaultBranchRef
   ```

5. 如果环境变量 `GITHUB_TOKEN` 覆盖了钥匙串中的有效登录并导致失败，使用 `env -u GITHUB_TOKEN gh ...` 重试。不要打印环境变量内容。
6. 使用 `aliyun configure list` 选择同时有 CAS 和云解析 DNS 权限的配置。团队机器可使用 `magicain-prod`，但必须以 `GetCallerIdentity`、`DescribeDomainInfo` 和实际返回结果为准，不假设账号身份。
7. 保存申请前 `_dnsauth` TXT 的记录 ID、值、TTL 和状态。若存在多个记录或明显属于第三方的验证值，不要覆盖或删除；先报告冲突。

## 阶段 1：准备并申请证书

优先复用未使用的个人测试证书实例，避免重复购买或耗尽额度：

```bash
aliyun cas ListInstances --InstanceType TEST --Status inactive --CurrentPage 1 --ShowSize 100
aliyun cas ListContact --CurrentPage 1 --ShowSize 100
```

选择明确属于 Magicain 的联系人 ID 和未使用实例。不要把联系人邮箱或手机号写入 Skill、仓库或聊天输出。

配置实例。替换占位符，不要盲目复用旧实例 ID：

```bash
aliyun cas UpdateInstance \
  --InstanceId <INSTANCE_ID> \
  --CertificateName cert-magicain-YYYY-MM \
  --Domain magicain.com \
  --ContactIdList.1 <CONTACT_ID> \
  --GenerateCsrMethod online \
  --KeyAlgorithm RSA_2048 \
  --CountryCode CN \
  --Province Shanghai \
  --City Shanghai \
  --ValidationMethod DNS \
  --AutoReissue disable
aliyun cas ApplyCertificate --InstanceId <INSTANCE_ID>
```

`magicain.com` 的 CAS 与云解析 DNS 已在同一阿里云账号。提交 DV 证书申请后，阿里云应自动选择自动 DNS 验证并添加所需解析记录。不要在 `ApplyCertificate` 前预先猜测或写入验证值。

若没有可复用实例，先通过阿里云控制台获取个人测试证书额度，或在联系人信息已获授权时使用 `CreateCertificateRequest`。执行前用 `aliyun cas CreateCertificateRequest help` 核对当前参数；不要把个人信息硬编码进仓库。

不要为当前 Magicain 入口选择 HTTP/FILE 验证。公网可能被阿里云 ICP 备案页面拦截，导致 CA 无法读取验证文件；使用 DNS 验证。

## 阶段 2：自动 DNS 验证

查询实例详情并提取本次申请的验证记录：

```bash
aliyun cas GetInstanceDetail --InstanceId <INSTANCE_ID>
```

提交申请后先等待 30–120 秒，并同时检查 CAS 状态和云解析记录：

```bash
aliyun cas GetInstanceDetail --InstanceId <INSTANCE_ID>
aliyun alidns DescribeDomainRecords --DomainName magicain.com --SearchMode COMBINATION --RRKeyWord _dnsauth --TypeKeyWord TXT --PageNumber 1 --PageSize 100
```

同账号自动 DNS 验证是默认路径。阿里云会在云解析 DNS 中自动添加验证记录；如果证书很快进入 `issued`，无需人工改 DNS。不要因为仍看到旧 `_dnsauth` 值就立即覆盖，先确认 CAS 是否已创建另一条记录或已经完成验证。

如果证书仍为 `pending`，以 `GetInstanceDetail` 返回的 `DomainValidationList` 为唯一真源，读取：

- `ValidationKey` 或 `CnameKey`：通常为 `_dnsauth`
- `ValidationType`：当前流程使用 `TXT`
- `ValidationValue`：每次申请都会变化，绝不能复用旧值

先用公网 DNS 验收：

```bash
dig +short TXT _dnsauth.magicain.com
```

返回值包含本次 `ValidationValue` 即表示验证记录已公开生效。

### 自动验证失败时的 CLI 备用流程

只有等待数分钟后 CAS 仍为 `pending`，且公网 DNS 不包含本次验证值时才人工补记录。先精确查询现有记录，绝不凭旧记录 ID 操作：

```bash
aliyun alidns DescribeDomainRecords --DomainName magicain.com --SearchMode COMBINATION --RRKeyWord _dnsauth --TypeKeyWord TXT --PageNumber 1 --PageSize 100
```

- 已存在完全相同的 `ValidationValue`：不写入，继续等待 DNS 缓存和 CA 检测。
- 没有相同值：优先新增独立记录，避免覆盖仍可能被其他证书申请使用的值：

  ```bash
  aliyun alidns AddDomainRecord --DomainName magicain.com --RR _dnsauth --Type TXT --Value <VALIDATION_VALUE> --Line default --TTL 600
  ```

- 只有确认某条旧记录专属于已完成或已撤回的旧证书申请，并且用户已授权替换时，才按实时查询出的记录 ID 更新：

  ```bash
  aliyun alidns UpdateDomainRecord --RecordId <RECORD_ID> --RR _dnsauth --Type TXT --Value <VALIDATION_VALUE> --Line default --TTL 600
  ```

写入后再次执行 `DescribeDomainRecords` 和 `dig +short TXT _dnsauth.magicain.com` 验收。

只有当前 CLI 身份失去云解析 DNS 权限、DNS 再次迁移到其他账号，或阿里云控制台要求人工确认时，才使用用户已登录的 Chrome。网页操作仍只允许处理 `_dnsauth` TXT，不改动其他记录。

## 阶段 3：等待签发并验证证书

每 20–60 秒查询一次，不要高频轮询：

```bash
aliyun cas GetInstanceDetail --InstanceId <INSTANCE_ID>
aliyun cas ListCertificates --InstanceId <INSTANCE_ID> --CurrentPage 1 --ShowSize 10
```

只有 `CertificateStatus` 或 `PendingResult` 显示 `issued`，并获得新的 `CertificateId`，才进入下载阶段。失败时读取明确的审核原因，不要反复创建新订单。

## 阶段 4：安全下载和本地校验

创建随机临时目录并收紧权限。下列文件只能存在于临时目录，绝不提交到 Git：

```bash
CERT_TMP_DIR="$(mktemp -d /private/tmp/magicain-cert.XXXXXX)"
chmod 700 "$CERT_TMP_DIR"
umask 077
aliyun cas GetUserCertificateDetail --CertId <CERTIFICATE_ID> > "$CERT_TMP_DIR/detail.json"
jq -r .Cert "$CERT_TMP_DIR/detail.json" > "$CERT_TMP_DIR/cert.pem"
jq -r .Key "$CERT_TMP_DIR/detail.json" > "$CERT_TMP_DIR/key.pem"
chmod 600 "$CERT_TMP_DIR/detail.json" "$CERT_TMP_DIR/cert.pem" "$CERT_TMP_DIR/key.pem"
```

不要把 `detail.json`、`.Key`、私钥正文或完整 CLI 响应输出到聊天。验证以下条件：

```bash
openssl x509 -in "$CERT_TMP_DIR/cert.pem" -noout -subject -issuer -dates -ext subjectAltName -fingerprint -sha256
openssl x509 -in "$CERT_TMP_DIR/cert.pem" -pubkey -noout | openssl sha256
openssl pkey -in "$CERT_TMP_DIR/key.pem" -pubout | openssl sha256
rg -c "BEGIN CERTIFICATE" "$CERT_TMP_DIR/cert.pem"
```

验收门槛：

- SAN 同时包含 `magicain.com` 与 `www.magicain.com`。
- 证书有效期是新周期。
- 证书公钥和私钥派生公钥的 SHA-256 完全一致。
- PEM 包含叶证书和中间证书链；当前阿里云返回通常是 2 个证书块。

## 阶段 5：更新 GitHub prod 密钥

先确认密钥名称和更新时间，不读取密钥值：

```bash
gh secret list --repo magicain-com/magicain-harness --env prod
```

从标准输入更新，避免把敏感值放进命令参数或历史：

```bash
gh secret set MAGICAIN_CERT_KEY --repo magicain-com/magicain-harness --env prod < "$CERT_TMP_DIR/key.pem"
gh secret set MAGICAIN_CERT_PEM --repo magicain-com/magicain-harness --env prod < "$CERT_TMP_DIR/cert.pem"
gh secret list --repo magicain-com/magicain-harness --env prod
```

最后一条输出中的两项更新时间必须刷新。若使用 `env -u GITHUB_TOKEN` 才能认证，对本阶段所有 `gh` 命令保持一致。

## 阶段 6：触发并跟踪部署

运行时查询默认分支，然后触发生产工作流：

```bash
gh repo view magicain-com/magicain-harness --json defaultBranchRef
gh workflow run deploy-app-frontend.yml --repo magicain-com/magicain-harness --ref <DEFAULT_BRANCH>
gh run watch <RUN_ID> --repo magicain-com/magicain-harness --exit-status --interval 10
```

必须保存并交付 Actions 运行链接。只有工作流结论为 `success` 且 Upload、Deploy 步骤均通过，才视为部署完成。

## 阶段 7：生产服务器验收

验证 Nginx 配置：

```bash
ssh -o BatchMode=yes prod-app-frontend "docker exec magicain-nginx-proxy-1 nginx -t"
```

直接读取服务器本机 443 端口实际提供的证书：

```bash
ssh -o BatchMode=yes prod-app-frontend \
  "openssl s_client -connect 127.0.0.1:443 -servername magicain.com </dev/null 2>/dev/null | openssl x509 -noout -subject -issuer -dates -ext subjectAltName -fingerprint -sha256"
```

服务器证书的有效期、SAN 和 SHA-256 指纹必须与新证书一致。公网 TLS 可作为附加检查，但不能替代服务器本机验收；如果公网被 ICP 备案拦截，要单独报告。

## 阶段 8：清理和交付

只删除本次创建的明确临时文件和目录：

```bash
rm -f "$CERT_TMP_DIR/detail.json" "$CERT_TMP_DIR/cert.pem" "$CERT_TMP_DIR/key.pem"
rmdir "$CERT_TMP_DIR"
```

证书签发后可清理仅服务于本次申请的 DNS 验证记录，但这不是部署成功的必要条件。删除前必须重新查询记录 ID，确认没有其他待签发证书依赖该值，并取得用户明确授权；不确定时保留记录并在交付中说明。

交付内容包括：

- 新证书 ID、域名/SAN、签发者和有效期
- DNS 验证已生效
- GitHub `prod` 两项密钥更新时间已刷新
- Actions 运行链接和成功结论
- Nginx 配置检查结果
- 服务器 443 端口证书指纹
- 临时敏感文件已删除
- ICP 备案等与证书无关的遗留风险

## 阶段 9：安排下一次续期任务

必须在证书部署与生产服务器验收成功后执行本阶段。不要根据申请日期、签发日期或“3 个月”估算；只使用生产服务器 443 端口实际证书的 `notAfter`。

1. 读取服务器实际证书到期时间：

   ```bash
   ssh -o BatchMode=yes prod-app-frontend \
     "openssl s_client -connect 127.0.0.1:443 -servername magicain.com </dev/null 2>/dev/null | openssl x509 -noout -enddate"
   ```

2. 将 `notAfter` 转换为 `Asia/Shanghai` 时间，计算“到期时间减 10 天”。保留实际时刻；如产品只允许整点，向后取最近整点但不得晚于到期前 9 天 23 小时。
3. 在 Codex 自动化中查找名为 `Magicain 证书续期` 的现有任务。存在则更新它的下一次运行时间，不存在才创建，避免每次续期积累重复任务。
4. 创建一次性任务，不使用每季度或每 90 天循环。任务应回到当前 Magicain 运维任务，并使用以下意图：

   ```text
   使用 $magicain-ops 检查 magicain.com 当前生产证书；若已进入到期前 10 天窗口，完成阿里云证书申请、自动 DNS 验证、GitHub prod 密钥更新、Actions 部署和生产验收。成功后根据新证书实际 notAfter 重新安排下一次到期前 10 天的一次性任务；遇到权限、签发或部署失败时停止写操作并明确报告。
   ```

5. 任务应绑定 Magicain 项目或当前本地任务上下文，使其能读取仓库级 `$magicain-ops`。安排后检查任务名称、状态、时区和下一次运行时间。
6. 若计算出的时间已过去，安排到下一个可用整点立即执行，并在交付中说明证书已进入紧急续期窗口。

交付时同时报告证书原始 `notAfter`、换算后的上海时间和下一次任务时间。
