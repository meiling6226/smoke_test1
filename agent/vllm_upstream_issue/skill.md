---
name: vllm_upstream_issue_filing
description: 根据 vllm-ascend 每周 E2E-upstream 的分析结果，为指定用例在 vllm-project/vllm-ascend 按固定模板新建 issue，并产出 test_path/issue 标题/issue 编号的 CSV。
---

# vLLM 上游用例提 issue

把上游 CI 分析结论落成 GitHub issue。只用 `vllm-project/vllm-ascend` 仓库，不要在其他仓库或 fork 里创建。

## 输入

- 运行链接，例如 `https://github.com/vllm-project/vllm-ascend/actions/runs/<run_id>`。
- 需要建 issue 的用例列表，单位是 `tests/` 下的 `test_*.py` 文件。
- issue 样例，默认 `https://github.com/vllm-project/vllm-ascend/issues/20992`，提之前先拉一次样例确认标题和正文格式。

## 前置检查

1. token 在本 skill 上一级目录的 `github_token.txt`。只在请求头里使用，不写进命令行，不打印，不提交。
2. 先验证账号和目标仓库权限：

```text
GET https://api.github.com/user
GET https://api.github.com/repos/vllm-project/vllm-ascend
```

3. 经典 token 需要 `public_repo`（或 `repo`）scope；fine-grained token 需要 Issues: Read and write。仓库返回的 `permissions` 里 `push` 为 false 时，经典 token 仍可能可以建 issue，先试一条。
4. 建 issue 返回 403 `Resource not accessible by personal access token` 时立即停止批量创建，把状态告诉用户，要求换有建 issue 权限的 token。不要改用 fork 仓库，不要自行假设用哪个 token。
5. 先按 `test_path` 搜索是否已有同类 issue，避免重复：

```text
GET https://api.github.com/search/issues?q=repo:vllm-project/vllm-ascend+is:issue+"<test_file_name>"
```

同时对照 `https://github.com/vllm-ascend/upstream-test/blob/main/issue/issue.csv`（列：`test_path,issue,title`）。已存在的在分析里写明编号和标题，不重复提。

## 从日志取证据

1. 下载并解压该 run 的日志 zip，按 job/shard 区分，例如 `e2e-upstream_singlecard` shard 0、`e2e-upstream_online` shard 0。
2. 日志行带时间戳和 ANSI 颜色，先清理再匹配：

```bash
perl -pe 's/\e\[[0-9;]*m//g; s/^[0-9T:.Z-]+ //' <log>
```

3. 每个用例文件取三类信息：
   - `##[group][n/N] <path>` 区块里的 `FAILED tests/...::test... - <错误>` 与 `ERROR ...` 行；
   - pytest 汇总行，例如 `Result: 21 failed, 144 passed.`；
   - `FAILURES` 段里 `E   ...`、断言和根因异常（EngineCore 初始化失败时要往上找真正根因，如 `NotImplementedError`、编译报错）。
4. 状态与原因分类沿用分析结论：产品/兼容性回归记 `failed`；`not supported`/`not implemented` 不能当无法执行；只有设备表里没有 npu 等硬性后端缺失才记 `unknown` + `无法执行-后端`。

## 创建 issue

一个 `test_*.py` 文件一个 issue。标题固定：

```text
[Bug][Upstream]: <一句话问题描述> case failed: <test_path>
```

正文固定（英文，和样例一致）：

```markdown
### Your current environment

Weekly E2E-upstream run: <run_url>

Job: `e2e-upstream_singlecard` shard N.

### 🐛 Describe the bug

`<test_path>`

Result: <X failed, Y passed.>

1. `<failing_test_id>`

2. `<failing_test_id>`

<一两句根因说明：哪个代码位置、哪个错误、影响范围>

```
<关键报错原文，3 行以内>
```
```

要点：

- `Job` 写真实 job 名和 shard，不要编造。
- 失败用例逐个列出；同一根因的测试太多时可列代表性用例，并在正文写明共有多少条同一错误。
- 代码块放最能定位问题的那几行，保留异常类型和文件:行号。
- 多个用例同根因（如 `test_tool_calls.py` 与 `test_reasoning.py` 的 `force_tool_names`）仍各自建 issue，在正文互相引用。

创建方式（token 从文件读，逐条创建并记录返回编号）：

```python
import json, time, urllib.request

TOK = open('<token_file>').read().strip()
payload = json.dumps({'title': title, 'body': body}).encode()
req = urllib.request.Request(
    'https://api.github.com/repos/vllm-project/vllm-ascend/issues',
    data=payload, method='POST',
    headers={'Authorization': 'Bearer ' + TOK,
             'Accept': 'application/vnd.github+json',
             'Content-Type': 'application/json',
             'User-Agent': 'ci-analysis'})
resp = json.load(urllib.request.urlopen(req, timeout=30))
print(resp['number'], resp['html_url'])
time.sleep(2)  # 避免触发二级限流
```

任何一条失败都停下来报告，不要跳过继续批量创建。

## 产出 CSV

issue 全部创建成功后，写一个带 BOM 的 UTF-8 文件 `issue_list_YYYYMMDDHHMMSS.csv`（本地时间精确到秒）：

```text
test_path,issue标题,issue编号
```

- `test_path`：从 `tests/` 开始的用例路径。
- `issue标题`：实际创建的标题原文。
- `issue编号`：纯数字，不带 `#`。
- 字段含逗号或引号时按 CSV 规则转义。

如需用例分析明细，另写 `upstream_cases_YYYYMMDDHHMMSS.csv`，列固定为 `test_path,status,关键片段,分析,原因分类,版本,是否已删除`。

## 收尾

- 输出 issue 列表和 CSV 路径。
- 提醒用户吊销临时 token。
- 不在目标仓库以外建 issue，不修改 issue.csv，不推送代码。
