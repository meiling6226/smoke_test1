#!/bin/bash

work_dir="/home/ml/analyse_log_v0290"
work_dir2="/home/ml"
# 输入文件（假设你的 FAILED 和 skipped 内容分别保存在这两个文件中）
file_failed="${work_dir}/failed_tests.txt"
file_skipped="${work_dir}/skipped_tests.txt"
file_new="${work_dir2}/new.txt"

# 输出文件
file3="${work_dir}/Repeated.txt"   # 存放重复内容
file4="${work_dir}/all_fail_skip.txt"   # 存放不重复内容
file5="${work_dir}/all_pass.txt"   #存放通过的内容

# --- 1. 预处理：去掉前缀并排序 ---
clean_failed_file="${work_dir}/clean_failed.txt"
clean_skipped_file="${work_dir}/clean_skipped.txt"
clean_new_file="${work_dir}/clean_new.txt"

# 去掉 FAILED: 前缀（注意冒号后有个空格），并排序
sed 's/^FAILED: //' "$file_failed" | sed 's|/vllm-workspace/vllm/||g' | sort > "$clean_failed_file"

# 去掉 skipped: 前缀，并排序
sed 's/^skipped: //' "$file_skipped" | sed 's|/vllm-workspace/vllm/||g' | sort > "$clean_skipped_file"

# 对所有新增用例排序
sort "$file_new" > "$clean_new_file"

# --- 2. 使用 comm 对比并输出 ---
# comm -12: 只显示共有的行（重复内容）-> 写入 file3
comm -12 "$clean_failed_file" "$clean_skipped_file" > "$file3"

# comm -3:  显示第1列（仅 FAILED 有）和第2列（仅 skipped 有）的独有行
# 注意：comm -3 输出时，第2列前面会有一个 Tab 符，这里用 sed 去掉它，看起来更整洁
comm -3 "$clean_failed_file" "$clean_skipped_file" | sed 's/^\t//' > "$file4"

# comm -23 表示排除第2列（仅文件2有）和第3列（共有），只保留第1列（仅文件1有）
comm -23 "$clean_new_file" "$file4" > "$file5"

# --- 3. 输出结果统计 ---
echo "===== 处理完成 ====="
echo "重复的内容已保存至: $file3 （共 $(wc -l < "$file3") 行）"
echo "不重复的内容已保存至: $file4 （共 $(wc -l < "$file4") 行）"
echo "通过的内容已保存至: $file5 （共 $(wc -l < "$file5") 行）"

# 清理临时文件
rm -f "$clean_failed_file" "$clean_skipped_file" "$clean_new_file"