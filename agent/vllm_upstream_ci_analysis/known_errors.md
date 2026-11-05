---
name: vllm-upstream-ci-analysis
description: >-
  Analyze the latest scheduled vllm-ascend E2E-upstream run, or a run URL the
  user gives. Download logs with the GitHub token in the parent directory,
  classify each tests/*.py file, and write a timestamped UTF-8 CSV. Use when
  the user asks to analyze the weekly upstream CI, E2E-upstream schedule logs,
  or an upstream-test issue list. Stops once the CSV is written.
disable-model-invocation: true
---

# vLLM 上游用例 CI 分析

分析 vllm-ascend 每周定时的 E2E-upstream。用户给了运行链接就用那一次，没给就取最新一次定时运行。

工作目录用当前目录，不要写死家目录路径。

## 取日志

token 在本 skill 上一级目录的 `github_token.txt`。只在请求里使用，不要写进命令行，也不要打印。

最新一次定时运行：

```text
https://github.com/vllm-project/vllm-ascend/actions?query=event%3Aschedule+workflow%3AE2E-upstream
```

对应工作流是 `.github/workflows/schedule_e2e_upstream_test.yaml`，`event=schedule` 的第一条。用 token 下载该 run 的日志 zip。下载中断就重试。

## 已有 issue

对照 `https://github.com/vllm-ascend/upstream-test/blob/main/issue/issue.csv`。这个表只记已经存在的 issue，列是 `test_path,issue,title`：用例路径、issue 编号、issue 标题。它不是共性问题库，对上的只说明这一条用例已有记录。

失败或 skipped 的用例先按 `test_path` 查这张表。对上了就在分析里写上 issue 编号和标题，状态仍按本次日志填写，不要因为已有 issue 改成无法执行。表是空的或对不上，再按本次日志分析。

## 判定

单位是整个 `test_*.py`。看 pytest 汇总，不要只看退出码。

- 有通过，且没有失败、没有 error：`passed`。其中的 skipped 不用分析。
- 没有通过也没有失败，全部是 skipped：`skipped`，要分析原因。
- 有失败或 error：整个文件记为 `failed` 或 `unknown`。产品代码问题记 `failed`。不是产品代码的问题记 `unknown`。

这些用例是曾经跑通过才进每周 CI 的。本次失败默认是产品回归，记 `failed`。不要轻易用「无法执行」。

日志里出现 not supported、not implemented，或 `DCP not support sliding window attn now` 这类措辞，不能单独当成无法执行。vLLM 已经支持的能力，vllm-ascend 也必须支持；没实现记 `failed`，原因分类置空。

vLLM 自己的设备表或后端表里没有 npu，属于后端不支持。status 填 `unknown`，原因分类填 `无法执行-后端`。例如 profiler 的 activity 表、NIXL 的设备允许列表。

`无法执行-后端` 用于两类：硬件或其他硬性条件导致昇腾 NPU 不可能执行，例如用例绑定 CUDA 或 ROCm 设备；以及 vLLM 代码未支持 npu。vllm-ascend 代码能做但还没做的，不用这一类。

拿不准就问用户。分析先写「待分析」，其余用例继续。这一轮看完后再回来补。

分析失败或 skipped 时再查 [known-errors.md](known-errors.md)。能对上就沿用。新的常见报错追加到该文档。不要沿用执行 skill 里「文件不存在算无法执行-用例」的结论。

pytest 报 `file or directory not found`，或退出码 4 且文件不在当次检出的 vLLM 树里：用例已删除。`是否已删除` 填 `是`，原因分类填 `已删除`，status 填 `unknown`。不要填 `无法执行-用例`。

## CSV

分析完成后，把结果写入工作目录的 `upstream_cases_YYYYMMDDHHMMSS.csv`。时间戳取写文件时的本地时间，精确到秒。每次任务新写一个文件。用带 BOM 的 UTF-8 写。字段里有逗号或引号时按 CSV 规则转义。

列名固定为：

```text
test_path,status,关键片段,分析,原因分类,版本,是否已删除
```

- `test_path`：从 `tests/` 开始的用例文件路径。
- `status`：只填 `passed`、`failed`、`skipped`、`unknown`。
- `关键片段`：失败、skipped 或已删除时写一行报错。`passed` 置空。
- `分析`：用一两句话说明原因。已在 issue.csv 里的写明已有记录。`passed` 置空。
- `原因分类`：`unknown` 和 `skipped` 才填。已删除填 `已删除`。`failed` 和 `passed` 置空。
- `版本`：用户下任务时指定的文字。没指定就置空。
- `是否已删除`：已删除填 `是`，其余置空。

除 `已删除` 外，原因分类只使用这些值，并且要满足上面的限制：

1. `无法执行-后端`：硬件或同类硬性条件使昇腾 NPU 无法执行，或 vLLM 代码的设备表、后端表里没有 npu。
2. `无法执行-权限`：访问需要授权的 Hugging Face 模型仓失败，例如 `meta-llama`。
3. `无法执行-依赖`：镜像里已有依赖的版本不够。不要为此安装别的依赖版本。
4. `无法执行-用例`：用例本身有问题。断言不合理、不是 pytest 用例，或用例代码有问题。文件不存在不用这一类。
5. `无法执行-显存`：在 CI 机器上仍会 OOM，且不是本可实现的功能缺失。
6. `无法执行-环境`：这一类很少，只用于多机用例和内核不满足要求的用例。
[root@hostname-qbnxc vllm-upstream-ci-analysis]# ll
total 12
-rw-r--r--. 1 root root 1475 Nov  4 09:27 known-errors.md
-rw-r--r--. 1 root root 5216 Nov  4 09:23 SKILL.md
[root@hostname-qbnxc vllm-upstream-ci-analysis]# cat known-errors.md
# 常见报错

分析失败或 skipped 的用例时查这里。能对上就沿用已有结论，不要重新分析。新的常见报错追加一条，写清报错原文、结论、status 和原因分类。

不要把「文件不存在」记成无法执行-用例。那条在本 skill 里固定是已删除。

## Torch not compiled with CUDA enabled

报错原文：`AssertionError: Torch not compiled with CUDA enabled`

结论：昇腾镜像里的 torch 没有 CUDA。用例在初始化 CUDA 或 ROCm 时碰到这句，直接按无法执行处理。

status：`unknown`

原因分类：`无法执行-后端`

## KeyError: 'npu'

报错原文：`KeyError: 'npu'`

结论：vLLM 按 `device_type` 查设备表时没有 npu，例如 profiler 的 `_DEFAULT_TORCH_PROFILER_ACTIVITIES`。这是 vLLM 代码未支持 NPU。

status：`unknown`

原因分类：`无法执行-后端`

## npu is not supported

报错原文：`RuntimeError: npu is not supported.`

结论：vLLM 的设备允许列表里没有 npu，例如 NIXL 的 `_NIXL_SUPPORTED_DEVICE`。这是 vLLM 代码未支持 NPU。`DCP not support sliding window attn now` 不要套用这一条。

status：`unknown`

原因分类：`无法执行-后端`

## No common block size for 16

报错原文：`ValueError: No common block size for 16 (CUSTOM: [128])`

结论：NPU 算子只支持 block_size 为 128，和用例要求的 16 没有公共 block size。

status：`unknown`

原因分类：`无法执行-后端`
