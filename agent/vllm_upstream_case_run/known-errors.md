# 常见报错

分析失败或 skipped 的用例时查这里。能对上就沿用已有结论，不要重新分析。新的常见报错追加一条，写清报
错原文、结论、status 和原因分类。

## ERROR: file or directory not found

pytest 退出码 4，当前检出的 vLLM 树里没有这个文件。记为 `unknown`，原因分类 `无法执行-用例`。

## RuntimeError: npu is not supported

用例或依赖直接写明 NPU 不支持。记为 `unknown`，原因分类 `无法执行-后端`。

## Torch not compiled with CUDA enabled

用例要求 CUDA 或 ROCm，当前镜像的 PyTorch 没有 CUDA。记为 `unknown`，原因分类 `无法执行-后端`。

## GrammarFactory.get_lark_from_jinja() missing 1 required positional argument: 'force_tool_names'

已安装的 GrammarFactory 签名和调用方不一致。记为 `unknown`，原因分类 `无法执行-依赖`。不要为此安装>别的依赖版本。
