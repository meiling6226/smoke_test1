#!/bin/bash
# 对比容器内新版本与工作目录中老版本 tests 下可被 pytest 收集的用例文件。
# 范围：tests/**/test_*.py。在容器内执行，当前目录就是工作目录。
set -euo pipefail

workdir=$(pwd)
new_tests=/vllm-workspace/vllm/tests
old_tests="$workdir/vllm/tests"
out_dir="$workdir"
save_file_new="$out_dir/new.txt"
save_file_deleted="$out_dir/deleted.txt"

if [ ! -d "$new_tests" ]; then
    echo "新版本 tests 不存在: $new_tests" >&2
    exit 1
fi
if [ ! -d "$old_tests" ]; then
    echo "老版本 tests 不存在: $old_tests" >&2
    exit 1
fi

new_list="$out_dir/new_list.txt"
old_list="$out_dir/old_list.txt"

find "$new_tests" -type f -name 'test_*.py' | sed "s|^$new_tests/|tests/|" | sort -u > "$new_list"
find "$old_tests" -type f -name 'test_*.py' | sed "s|^$old_tests/|tests/|" | sort -u > "$old_list"

comm -23 "$new_list" "$old_list" > "$save_file_new"
comm -13 "$new_list" "$old_list" > "$save_file_deleted"

echo "new: $(wc -l < "$save_file_new") -> $save_file_new"
echo "deleted: $(wc -l < "$save_file_deleted") -> $save_file_deleted"