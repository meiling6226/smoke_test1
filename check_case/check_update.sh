dirA=./tests
dirB=/home/ml/vllm/tests
save_file_new=new.txt
save_file_deleted=deleted.txt
rm -f $save_file_new
rm -f $save_file_deleted
touch $save_file_new
touch $save_file_deleted

find "$dirA" -type f -name "test*.py" -print0 | while IFS= read -r -d '' file; do
    relpath="${file#$dirA/}"
    if [ ! -f "$dirB/$relpath" ]; then
        echo "tests/$relpath" >> $save_file_new
    fi
done

find "$dirB" -type f -name "test*.py" -print0 | while IFS= read -r -d '' file; do
    relpath="${file#$dirB/}"
    if [ ! -f "$dirA/$relpath" ]; then
        echo "tests/$relpath" >> $save_file_deleted
    fi
done