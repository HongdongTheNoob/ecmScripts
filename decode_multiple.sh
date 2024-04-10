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

BuildLabels=()
IFS=','

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
home_folder="/data/hongdong.qin"

if [ -z "$BuildLabels" ]
then
  exit 1
fi

buildCount=${#BuildLabels[@]}
output_folders=()
decoder_files=()
for ((i = 0; i < $buildCount; i++)); do
  output_folders+=("$home_folder/outputs/${BuildLabels[i]}")
  decoder_files+=("$home_folder/Preprocessing/App_${BuildLabels[i]}/DecoderApp")
done

find "${output_folders[0]}" -type f -name "*.bin" | while read bin_file; do
  # Loop through folder in the first build label
  if [[ "$bin_file" == *"$class_string"*"-$config-"* ]]; then
    # Check if it's a split file
    integer_count=$(echo "$bin_file" | grep -oE '[0-9]+' | wc -l)
    if [ "$integer_count" -gt 1 ]; then # is split file, skip
      continue
    fi
    
    log_files=()
    bin_files=()
    yuv_files=()
    decode_commands=()

    bin_files+=($bin_file)

    # Generate file names for the first build label
    log_file="${bin_file%.bin}-decode.txt"
    log_files+=($log_file)
    if ! [ -z write_output ]; then
      yuv_file="${bin_file%.bin}.yuv"
    else
      yuv_file="\"\""
    fi
    yuv_files+=($yuv_file)
    
    # Collect file names for other build labels
    for ((i = 1; i < $buildCount; i++)); do
      bin_file=$(echo "${bin_files[0]}" | sed "s/${BuildLabels[0]}/${BuildLabels[i]}/")
      log_file=$(echo "${log_files[0]}" | sed "s/${BuildLabels[0]}/${BuildLabels[i]}/")
      yuv_file=$(echo "${yuv_files[0]}" | sed "s/${BuildLabels[0]}/${BuildLabels[i]}/")
      bin_files+=($bin_file)
      log_files+=($log_file)
      yuv_files+=($yuv_file)
    done

    # Compose decoding command
    for ((i = 0; i < $buildCount; i++)); do
      decode_command="${decoder_files[i]} -b ${bin_file[i]} -o ${yuv_file[i]} > ${log_file[i]}"
      if (( i + 1 < $buildCount )); then
        decode_command="$decode_command &"
      fi
      decode_commands+=($decode_command)
    done

    # Evaluate
    for ((i = 0; i < $buildCount; i++)); do
      echo ${decode_commands[i]}
      # eval ${decode_commands[i]}
    done
  fi
done
