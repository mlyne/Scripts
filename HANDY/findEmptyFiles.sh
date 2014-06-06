for file in *;
  do
    file_size=$(du $file | awk '{print $1}');
    if [ $file_size == 0 ]; then
        echo "$file";
    fi;
  done
