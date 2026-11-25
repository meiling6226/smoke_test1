---
name: vllm-upstream-case-diff
description: >-
  Diff upstream vLLM pytest files between the running container's vLLM and a
  user-specified older tag. Clone https://github.com/vllm-project/vllm.git, or
  git pull when that checkout is already a complete repo, then checkout the tag
  and run scripts/check_update.sh. Use when the user asks to
  compare upstream community tests, find new or deleted test_*.py cases,
  diff a vLLM tag against the container version, or summarize the result as a
  CSV. Runs the diff and then writes new.txt, deleted.txt and a summary CSV.
disable-model-invocation: true
---

# vLLM 上游用例差异

对比容器里的新版本和用户指定 tag 的老版本，列出 `tests` 下新增、删除的 pytest 用例文件。用例怎么跑不在本 skill。

老版本 tag、容器名由用户给出。没给就先问，不要自己编。

工作目录用当前目录，不要写死路径。容器能看到这个目录。

## 步骤

1. 在工作目录克隆官方仓库。不要检查代理，不要改用镜像。停在 `Cloning into` 且没有 `Receiving objects` 时，停掉这次克隆，删掉未完成的 `vllm` 目录，再执行同一条命令。

```bash
git clone https://github.com/vllm-project/vllm.git
```

工作目录里的 `vllm` 已是完整仓库时不要删、不要重新克隆。进入该仓库，用 `git pull` 更新。当前不在分支上时，先切回 `main` 再拉取。网络卡住就重试，不要检查代理，不要改用镜像。

```bash
git -C vllm switch main
git -C vllm pull
```

2. 切到用户给的 tag。

```bash
git -C vllm checkout <tag>
```

`git -C vllm describe --tags --exact-match HEAD` 等于该 tag 才算完成。

3. 在已运行的容器里执行本 skill 的 `scripts/check_update.sh`。`-w` 设为工作目录，脚本以当前目录作为工作目录。新版本代码是容器内 `/vllm-workspace/vllm`，老版本代码是工作目录下的 `vllm`。只比较 `tests` 下的 `test_*.py`。

```bash
docker exec -i -w <工作目录> <容器名> bash <本 skill 目录>/scripts/check_update.sh
```

结果覆盖写到工作目录：

- `new.txt`：新版本有、老版本没有
- `deleted.txt`：老版本有、新版本没有
- `new_list.txt`、`old_list.txt`：两边的完整列表

同名文件只是换了目录时，会同时出现在 `new.txt` 和 `deleted.txt`。把这种情况告诉用户。

4. 生成总结 CSV。用脚本 `scripts/build_diff_csv.py`，以工作目录为准读取上一步的 `new.txt`、`deleted.txt`（以及 `new_list.txt`、`old_list.txt` 取总数），输出 `<新版本>_vs_<老版本>.csv`。

```bash
python <本 skill 目录>/scripts/build_diff_csv.py --workdir <工作目录> \
  --new-label v0.34.0 --old-label v0.33.0
```

- 版本号用用户给的写法：新版本是容器里跑的那版，老版本是第 2 步 checkout 的 tag。
- 脚本要在能读到工作目录的机器上执行。工作目录在远端时，先把 `new.txt`、`deleted.txt`、`new_list.txt`、`old_list.txt` 拷到本地同一目录再跑（或把脚本拷到远端用 `python3` 跑）。
- 脚本可选参数：`--related related.json`（`{"tests/xxx/test_y.py": "21975"}` 关联 issue）、`--notes notes.json`（逐条覆盖分析说明）、`--generated-at "2026-11-25"`、`--out <路径>`。
- `related.json` / `notes.json` 不存在就不要传，脚本会按目录和平台属性自动填默认说明，不要自己编造 issue 号。
- CSV 为 6 列：`类型,test_path,平台属性,NPU关注度,关联issue,分析说明`，UTF-8 带 BOM（Excel 直接打开不乱码）。结构固定为四段：
  1. 最上面：用例数量与变化总结（用例总数、新增、删除、净增、同名换目录、NPU 关注度与平台属性分布、生成时间）
  2. 紧跟其后：删除且关联 issue 的条目（带表头）
  3. `new.list`：全部新增用例（带表头）
  4. `deleted.list`：全部删除用例（带表头）
- 生成后向用户报告：CSV 路径、总行数、新增/删除/deleted 中关联 issue 的条数。删除且关联 issue 的条目会同时出现在第二段和 `deleted.list`，这是预期行为。