---
name: vllm-upstream-case-run
description: >-
  Run upstream vLLM pytest files inside the prepared container and write a
  timestamped upstream_cases CSV. Logs in with hf_token.txt in this skill, sets the
  spawn, hf-mirror, and upstream_test_plugin environment, then runs pytest -sv
  on whole test_*.py files. Use when the user asks to execute, rerun, or record
  upstream community cases, or to classify passed, failed, skipped, and unknown
  results. Stops once the CSV for the requested files is written.
disable-model-invocation: true
---

# vLLM 上游用例执行

在已经准备好的容器里执行用户给出的上游用例，并写出 CSV。容器名由用户给出。没给就先问，不要自己编。

一次任务可以有一个或多个用例。每个用例都是整个 `test_*.py` 文件，不要执行 `::` 后面的单个函数。pytest 收到的路径从 `tests/` 开始，例如 `tests/basic_correctness/models/test_basic_correctness.py`。

工作目录用当前目录，不要写死家目录路径。容器能看到这个目录，也能看到本 skill 所在目录。

## 登录

token 文件是本 skill 目录下的 `hf_token.txt`。在容器内读取，不要把 token 写进命令行，也不要打印 token。`huggingface.co` 不通，用 `HF_ENDPOINT=https://hf-mirror.com`。

```bash
docker exec -i -e HF_ENDPOINT=https://hf-mirror.com <容器名> \
  python3 <本 skill 目录>/scripts/hf_login.py <本 skill 目录>/hf_token.txt
docker exec -i -e HF_ENDPOINT=https://hf-mirror.com <容器名> hf auth whoami
```

`whoami` 打印出用户名，且 endpoint 为 `https://hf-mirror.com`，才算登录完成。

## 选择空闲卡

执行前在宿主机跑 `npu-smi info`，不要进容器。这条命令大约两秒就返回。进程表里有进程的卡算占用，没有进程的卡算空闲。

有卡被占用时，只把空闲卡号传进容器，卡号用逗号分隔：

```bash
export ASCEND_RT_VISIBLE_DEVICES=4,6,7
```

上面的数字只是例子，每次按当时的空闲卡号填写。通过 `docker exec -e ASCEND_RT_VISIBLE_DEVICES=...` 传入，并在容器里再 export 一次。全部空闲时不设置这个变量。用例要的卡数多于空闲卡时，仍然只用空闲卡。

## 执行

工作目录是容器内 `/vllm-workspace/vllm`。下面这些环境变量每次都要带上。`PYTHONPATH` 只在原值前面加上 `/vllm-workspace/vllm-ascend/tests`，不要整段替换。需要限制卡时，把 `ASCEND_RT_VISIBLE_DEVICES` 加到 `docker exec -e` 和容器内的 export 里。

```bash
docker exec -i -e ASCEND_RT_VISIBLE_DEVICES=<空闲卡号> -w /vllm-workspace/vllm <容器名> bash <<'EOF'
export ASCEND_RT_VISIBLE_DEVICES=<空闲卡号>
export VLLM_WORKER_MULTIPROC_METHOD=spawn
export HF_ENDPOINT=https://hf-mirror.com
export PYTEST_ADDOPTS="-p upstream_test_plugin"
export PYTHONPATH="/vllm-workspace/vllm-ascend/tests${PYTHONPATH:+:$PYTHONPATH}"
pytest -sv <tests/开头的用例路径> --tb=short
EOF
```

完整输出另外写入 `<工作目录>/logs/<用例路径去掉 .py 换成 .log>`。按用户给出的顺序一个文件一个文件跑。

跑的过程中出现 401：先查 `hf auth whoami`。未登录或登录失效时，用上面的方式重新登录，再重试该用例一次。

不要为了让用例通过去安装别的依赖版本。遇到 flashinfer、rocm、nccl、cutlass 相关报错不要安装对应包，按 [known-errors.md](known-errors.md) 记为 `unknown`、`无法执行-后端`。

日志停在加载权重时，先当成本地下载慢，继续跟踪。看缓存里的 `.incomplete` 文件大小和进程读写有没有增加。有增长就继续等。隔一段时间大小和读写都不变，再记成卡住。

## 判定

看 pytest 汇总，不要只看退出码。

- 有通过，且没有失败、没有 error：`passed`。其中的 skipped 不用分析。 passed 必须真的有 passed 的子测试。
- 没有通过也没有失败，全部是 skipped：`skipped`，要分析原因。全是 skipped 的文件要改成 skipped。
- 有失败或 error：整个文件记为 `failed` 或 `unknown`。产品代码问题记 `failed`。不是产品代码的问题记 `unknown`。

一个用例一时分析不完，或原因不明显：先记下状态，分析写「待分析」，继续跑后面的用例。这一轮都跑完后再回来补分析。

分析失败或 skipped 时再查 [known-errors.md](known-errors.md)，执行用例前不查。能对上就沿用，不要重新分析。只有共性问题才追加到该文档，单个用例特有的报错不要写。缺了但可以直接安装的依赖不要写进 known-errors，写到 [installable-missing-deps.md](installable-missing-deps.md)。

## CSV

全部用例跑完，待分析的也补完之后，把结果写入工作目录的 `upstream_cases_YYYYMMDDHHMMSS.csv`。时间戳取写文件时的本地时间，精确到秒。每次任务新写一个文件。用带 BOM 的 UTF-8 写，Excel 才能直接打开中文。字段里有逗号或引号时按 CSV 规则转义。

列名固定为：

```text
test_path,status,关键片段,分析,原因分类,版本,是否已删除
```

- `test_path`：从 `tests/` 开始的用例文件路径。
- `status`：只填 `passed`、`failed`、`skipped`、`unknown`。
- `关键片段`：失败或 skipped 时写一行报错或跳过信息。`passed` 置空。
- `分析`：用一两句话说明失败或 skipped 的原因。`passed` 置空。
- `原因分类`：`unknown` 和 `skipped` 用下面的分类。`failed` 和 `passed` 置空。
- `版本`：用户下任务时指定的文字。没指定就置空。
- `是否已删除`：置空。

原因分类只使用这些值：

1. `无法执行-后端`：NPU 后端不支持。用例写明需要 CUDA 或 GPU 后端相关依赖。
2. `无法执行-权限`：访问需要授权的 Hugging Face 模型仓失败，例如 `meta-llama`。401 要先按上面的步骤登录并重试，仍然失败才用这一类。
3. `无法执行-依赖`：镜像里已有依赖的版本不够。可能重装别的版本能过，但是不要装。
4. `无法执行-用例`：用例本身有问题。断言不合理、不是 pytest 用例，或用例代码有问题。
5. `无法执行-显存`：当前环境是 32G。出现 OOM 时先判断 64G 能不能过。判断 64G 仍会 OOM 才用这一类；判断 64G 可能通过时，不使用这一类，把判断写进分析。
6. `无法执行-环境`：环境问题。这一类很少，目前只用于多机用例和内核不满足要求的用例。
