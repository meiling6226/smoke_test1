# 常见报错

分析失败或 skipped 的用例时查这里。能对上就沿用已有结论，不要重新分析。

只有共性问题才追加到这里。单个用例特有的报错不要写。新条目写清报错原文、结论、status 和原因分类。

执行用例和每周 CI 分析都用这一份。

## ERROR: file or directory not found

pytest 退出码 4，当前检出的 vLLM 树里没有这个文件。

执行用例时记为 `unknown`，原因分类 `无法执行-用例`。

分析每周 CI 时这是用例已删除。`是否已删除` 填 `是`，原因分类 `已删除`，status 填 `unknown`。不要填 `无法执行-用例`。

## RuntimeError: npu is not supported

报错原文：`RuntimeError: npu is not supported.`

结论：vLLM 的设备允许列表里没有 npu，例如 NIXL 的 `_NIXL_SUPPORTED_DEVICE`。这是 vLLM 代码未支持 NPU。`DCP not support sliding window attn now` 不要套用这一条。

status：`unknown`

原因分类：`无法执行-后端`

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

## No common block size for 16

报错原文：`ValueError: No common block size for 16 (CUSTOM: [128])`

结论：NPU 算子只支持 block_size 为 128，和用例要求的 16 没有公共 block size。

status：`unknown`

原因分类：`无法执行-后端`

## You are trying to access a gated repo

报错原文：`You are trying to access a gated repo`

结论：访问需要授权的 Hugging Face 模型仓。直接记为无法执行，不要再重新登录重试。

status：`unknown`

原因分类：`无法执行-权限`

## flashinfer、rocm、nccl、cutlass

报错原文里出现 `flashinfer`、`rocm`、`nccl` 或 `cutlass`，大小写不限。例如 `No module named 'flashinfer'`。

结论：当前后端不使用这些组件。直接记为无法执行，不要安装对应包。

status：`unknown`

原因分类：`无法执行-后端`