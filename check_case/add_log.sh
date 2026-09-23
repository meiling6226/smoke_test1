input_file="new.txt"
log_dir="/home/yf/analyse_log_v0180"

while IFS= read -r line; do
    # 拼接完整路径
    full_path="/vllm-workspace/vllm/${line}"

    # 生成日志路径 (保持逻辑不变)
    logfile="${log_dir}/${line%.py}.log"
    dir_name=$(dirname $logfile)
    mkdir -p ${dir_name}

    # 断点续跑检查
    if [ -f "$logfile" ]; then
        continue
    fi

    # 打印拼接后的路径并执行测试
    echo "testing $full_path"
    #pytest -sv "$full_path" | tee $logfile
    pytest -sv "$full_path" 2>&1 | tee $logfile
    # 获取 pytest 的退出状态
    if [ ${PIPESTATUS[0]} -ne 0 ]; then
        # 如果退出码非 0，说明测试失败（FAILED）
        echo "FAILED: $full_path" >> ${log_dir}/failed_tests.txt
    elif grep -q "SKIPPED" $logfile; then
        # 如果退出码为 0，但日志中有 SKIPPED 字样，说明测试被跳过
        echo "skipped: $full_path" >> ${log_dir}/skipped_tests.txt
    fi
done < "$input_file"