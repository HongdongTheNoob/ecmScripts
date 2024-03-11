#!/bin/bash

# Check if folder path is provided as argument
help()
{
  echo "Arguments:"
  echo "-b|--build_label BuildLabel"
  echo "-c|--class Class | Video class to be decoded. If absent, all classes will be decoded"
  echo "-g|--config Config | AI, RA, LB or LP"
  echo "-o|--output | Write yuv outputs"
}

if [ $# -eq 0 ]
then
  help
  exit 1
fi

while [[ $# -gt 0 ]]; do
  case $1 in
    -b|--build)
      build="$2"
      shift # past argument
      shift # past value
      ;;
    -c|--class)
      class="$2"
      shift # past argument
      shift # past value
      ;;
    -g|--config)
      config="$2"
      shift # past argument
      shift # past value
      ;;
    -o|--output)
      write_output="$1"
      shift # past argument
      ;;
    -*|--*)
      echo "Unknown option $1"
      help
      exit 1
      ;;
    *)
      shift # past argument
      ;;
  esac
done

if ! [ -z "$class" ];
then
    class_string="Class$class"
fi

# Loop recursively through the folder and its subfolders
home_folder="/data"
output_folder="$home_folder/outputs/$build"
decoder_file="$home_folder/Preprocessing/App_$build/DecoderApp"
decoder_ecm_file="$home_folder/Preprocessing/App_ECM/DecoderApp"

echo "loop through $output_folder"
find "$output_folder" -type f -name "*.bin" | while read bin_file; do
    # Check if the path contains "ECM"
    if [[ "$bin_file" == *"$class_string"*"-ECM"*"-$config-"* ]]; then
        # Check if it's a split file
        integer_count=$(echo "$bin_file" | grep -oE '[0-9]+' | wc -l)
        if [ "$integer_count" -gt 1 ]; then # is split file, skip
            continue
        fi
        
        # Generate file names
        log_file="${bin_file%.bin}-decode.txt"

        test_bin_file="${bin_file/-ECM/}"
        test_log_file="${test_bin_file%.bin}-decode.txt"

        if ! [ -z write_output ]; then
          yuv_file="${bin_file%.bin}.yuv"
          test_yuv_file="${test_bin_file%.bin}.yuv"
        else
          yuv_file="\"\""
          test_yuv_file="\"\""
        fi
        
        # Run the decode command
        decode_command_ecm="$decoder_ecm_file -b $bin_file -o $yuv_file > $log_file &"
        decode_command="$decoder_file -b $test_bin_file -o $test_yuv_file > $test_log_file"
        echo "Working on $test_bin_file"

        # Evaluate
        eval $decode_command_ecm
        eval $decode_command
    fi
done
