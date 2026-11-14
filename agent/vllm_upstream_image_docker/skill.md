---
name: vllm-container-setup
description: >-
  Pull the latest vllm-ascend nightly image, create a container named test_ml_YYYYMMDD
  with start-docker.sh, then exec into the container and ask the user for the version
  to create a version directory. Use when the user asks to set up a new vllm-ascend
  container environment, pull image and create container, or start a fresh test
  container. Do not use for running tests inside an already running container.
---

# vLLM 容器初始化

拉取 vllm-ascend 最新 nightly 镜像，创建容器，然后进入容器准备版本目录。

## 环境约定

- 服务器：`173.125.1.2`
- 工作目录：`/home/ml/`
- 镜像仓库：`quay.io/ascend/vllm-ascend:nightly-main`
- 容器创建脚本：`/home/ml/start-docker.sh`

如果服务器不可达或脚本不存在，先向用户确认，不要自行修改地址。

## 第一步：拉取镜像

在服务器 `173.125.1.2` 上进入 `/home/ml/` 目录，拉取镜像：

```bash
ssh 173.125.1.2 'cd /home/ml && docker pull quay.io/ascend/vllm-ascend:nightly-main'
```

镜像拉取成功后，获取镜像 ID：

```bash
ssh 173.125.1.2 'docker images quay.io/ascend/vllm-ascend:nightly-main -q'
```

将返回的 ID 记为 `<IMAGE_ID>`。如果返回空，说明拉取没有成功完成，重新检查拉取日志。

网络不稳定时拉取可能中断，允许用户手动重试，但不要自动并发拉取多个镜像。

## 第二步：创建容器

容器名格式为 `test_ml_YYYYMMDD`，日期取当天本地时间，例如 `test_ml_20261111`。

用 `<CONTAINER_NAME>` 表示生成的容器名，执行创建脚本：

```bash
ssh 173.125.1.2 'cd /home/ml && bash start-docker.sh <IMAGE_ID> <CONTAINER_NAME>'
```

例如：`bash start-docker.sh abc123 test_ml_20261111`

脚本运行完成后，确认容器已启动：

```bash
ssh 173.125.1.2 "docker ps --filter name=<CONTAINER_NAME> --format '{{.Names}} {{.Status}}'"
```

状态应为 `Up ...`。没有运行起来就向用户报告，不要反复创建。

## 第三步：进入容器并准备目录

### 进入容器

```bash
ssh -t 173.125.1.2 "docker exec -it <CONTAINER_NAME> bash"
```

然后在容器内切换到工作目录：

```bash
cd /home/ml
```

### 创建版本目录

向用户询问：**这个版本是什么？** 例如用户回答 `v0.33.0`，则去掉点号得到 `v0330`，用它作为目录名。

```bash
# 用户回答 v0.33.0，转换为 v0330
mkdir v0330
```

转换规则：去掉版本字符串中所有 `.`，其他字符原样保留。例如：
- `v0.33.0` → `v0330`
- `0.33.0` → `0330`
- `v1.0.0` → `v100`

目录创建完成后，向用户报告三个信息：
- 容器名 `<CONTAINER_NAME>`
- 镜像 ID `<IMAGE_ID>`
- 版本目录名 `<VERSION_DIR>`
