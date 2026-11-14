---
name: vllm-upstream-csv-to-yaml
description: Convert upstream_cases_*.csv into a CI config yaml. Use when the user asks to extract passed cases into a new upstream_config_*.yaml, or to generate a yaml from a CSV of test results. Do not use for modifying the yaml in place or for diffing two CSVs.
---

# CSV → YAML 配置生成

把 `upstream_cases_*.csv` 里指定状态（通常是 `passed`）的用例，按现有 `upstream_config.yaml` 的格式写成新的 yaml 文件，供 CI 流水线使用。

## 输入

- **CSV 文件**：工作目录下的 `upstream_cases_YYYYMMDDHHMMSS.csv`，必须包含列 `test_path` 和 `status`。BOM UTF-8。
- **目标状态**：默认 `passed`。如果用户指定了别的状态（比如 `failed`、`skipped`），按用户给的来。
- **输出文件名**：用户给了就用用户的；没给就取 `upstream_config_<version>.yaml`，version 从 CSV 的 `版本` 列首行取，取不到就用当前时间戳。
- **section 名**：默认 `e2e-upstream_singlecard`。如果用户给了就按用户的来。

## 步骤

1. 读取 CSV（`encoding='utf-8-sig'`），筛选 `status == 目标状态` 的行，取去重后的 `test_path`。
2. 用下面的模板写出每个 `test_path`：

```text
<section>:
  - name: <test_path>
    estimated_time: 20
```

- 缩进固定 2 空格，`estimated_time` 固定 20（与现有 `upstream_config.yaml` 保持一致，不要从 CSV 里推断）。
- 条目不排序，保持 CSV 原始顺序。
- 只写一个 section，不要复制原 yaml 的其他 section 或条目。

3. 写到工作目录。文件编码 UTF-8，**不要**加 BOM（yaml 不需要）。
4. 打印条目数量和文件路径。

## 典型命令（Python 3，避免 shell 引号问题）

```python
import csv
status = 'passed'
section = 'e2e-upstream_singlecard'
csv_path = 'upstream_cases_YYYYMMDDHHMMSS.csv'
out_path = 'upstream_config_v0330.yaml'
rows = list(csv.DictReader(open(csv_path, encoding='utf-8-sig')))
paths = []
seen = set()
for r in rows:
    if r['status'] == status and r['test_path'] not in seen:
        seen.add(r['test_path']); paths.append(r['test_path'])
with open(out_path, 'w', encoding='utf-8', newline='') as f:
    f.write(f'{section}:\n')
    for p in paths:
        f.write(f'  - name: {p}\n    estimated_time: 20\n')
print('wrote', out_path, len(paths), 'entries')
```

## 不要做

- 不要修改现有 `upstream_config.yaml`，始终新建文件。
- 不要把 `skipped`、`unknown`、`failed` 混进去，除非用户明确要求。
- 不要从 `upstream_config.yaml` 反查 section 归属；CSV 里的 test_path 可能不在现有 yaml 里（比如版本变了），这种情况统一放到用户指定或默认的单个 section 下。
