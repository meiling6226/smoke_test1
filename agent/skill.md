---
name: vllm-upstream-ci-analysis
description: >-
  Analyze the latest scheduled vllm-ascend E2E-upstream run, or a run URL the
  user gives. Download logs with the GitHub token in the parent directory,
  classify each tests/*.py file, and write a timestamped UTF-8 CSV. Use when
  the user asks to analyze the weekly upstream CI, E2E-upstream schedule logs,
  or an upstream-test issue list.
disable-model-invocation: true
---


# vLLM 上游用例 CI 分析 提 issue

根据用户给定的用例：
tests/v1/kv_connector/unit/test_remote_prefill_lifecycle.py
tests/parser/mistral/test_tool_calls.py
tests/v1/e2e/spec_decode/acceptance_rates/mtp_other/test_medusa.py
tests/models/test_terratorch.py
tests/v1/spec_decode/test_dflash2.py
tests/v1/logits_processors/test_custom_online.py
tests/entrypoints/openai/chat_completion/test_chat_echo.py
tests/parser/mistral/test_reasoning.py
tests/tokenizers_/test_mistral.py
tests/evals/mrcr/test_mrcr_correctness.py
tests/model_executor/test_routed_experts_capture.py
tests/v1/kv_connector/unit/test_mooncake_store_worker.py



分析 vllm-ascend 每周定时的 E2E-upstream。用户给了运行链接就用那一次，没给就取最新一次定时运行。 
链接为：https://github.com/vllm-project/vllm-ascend/actions/runs/42491193545

在链接中找到指定用例，找到相关报错信息，新建issue。issue的样例为：https://github.com/vllm-project/vllm-ascend/issues/20992

issue提完后整理成csv文件

issue提完后，


