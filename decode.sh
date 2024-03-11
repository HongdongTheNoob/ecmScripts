#!/bin/bash

# Check if folder path is provided as argument
if [ $# -ne 1 ]; then
    echo "Usage: $0 <folder_path>"
    exit 1
fi

# Loop recursively through the folder and its subfolders
build=$1
output_folder="/data/hongdong.qin/outputs/$build"
decoder_file="/data/hongdong.qin/Preprocessing/App_$build/DecoderApp"
parcat_file="/data/hongdong.qin/Preprocessing/App_$build/parcat"

echo "loop through $output_folder"
# parcat split file
find "$output_folder" -type f -name "*.bin" | while read bin_file; do
    if [[ "$bin_file" != *"-ECM"* ]]; then
        # Check if it's a split file
        integer_count=$(echo "$bin_file" | grep -oE '[0-9]+' | wc -l)

        if [ "$integer_count" -gt 1 ]; then # is split, run parcat

        fi
    fi

find "$output_folder" -type f -name "*.bin" | while read bin_file; do
    # Check if the path does not contain "ECM"
    if [[ "$bin_file" != *"-ECM"* ]]; then
        # Check if it's a split file
        integer_count=$(echo "$bin_file" | grep -oE '[0-9]+' | wc -l)
        if [ "$integer_count" -gt 1 ]; then # is split file, skip
            continue
        fi
        # Generate yuv_file name
        yuv_file="${bin_file%.bin}.yuv"
        log_file="${bin_file%.bin}-decode.txt"
        
        # Run the decode command
        echo "Working on $bin_file"
        eval "$decoder_file -b $bin_file -o $yuv_file > $log_file"
    fi
done
