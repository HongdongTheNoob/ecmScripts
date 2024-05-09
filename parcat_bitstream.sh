#!/bin/bash

# Check if folder path is provided as argument
help()
{
  echo "Arguments:"
  echo "-b|--build_label BuildLabel"
  echo "-c|--class Class | Video class to be decoded. If absent, all classes will be decoded"
  echo "-o|--output | Write yuv outputs"
}

split_files_sort() {
    local input=("$@")
    local size=${#input[@]}
    
    for ((i = 0; i < size-1; i++)); do
        for ((j = i+1; j < size; j++)); do
            # Extract the last integer from the strings
            int1=$(echo "${input[i]}" | grep -oE '[0-9]+' | tail -n1)
            int2=$(echo "${input[j]}" | grep -oE '[0-9]+' | tail -n1)

            # Compare and swap if necessary
            if [ "$int1" -gt "$int2" ]; then
                temp="${input[i]}"
                input[i]="${input[j]}"
                input[j]="$temp"
            fi
        done
    done

    echo "${input[@]}"
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
      read -a BuildLabels <<< "$2"
      shift # past argument
      shift # past value
      ;;
    -c|--class)
      class="$2"
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

if [ -z "$BuildLabels" ]
then
  exit 1
fi

buildCount=${#BuildLabels[@]}

for ((i = 0; i < $buildCount; i++)); do
  build=${BuildLabels[i]}
  
  home_folder="/data/hongdong.qin"
  output_folder="$home_folder/outputs/$build"
  decoder_file="$home_folder/ecmScripts/App_$build/DecoderApp"
  parcat_file="$home_folder/ecmScripts/App_$build/parcat"
  all_tasks=()
  all_split_files=()

  echo "loop through $output_folder"
  # parcat split file
  while read -r bin_file; do
      if [[ "$bin_file" != *"$class_string"*"-RA-"* ]]; then
          continue
      fi    
      
      # Check if it's a split file
      # integer_count=$(echo "$bin_file" | awk -F'/' '{print $NF}' | grep -oE '[0-9]+' | wc -l)

      extracted_part=$(echo $(basename "$bin_file") | awk -F"-RA-" '{print $2}')
      integer_count=$(echo "$extracted_part" | grep -oE '[0-9]+' | wc -l)

      if [ "$integer_count" -ge 2 ]; then # is split, run parcat
          all_split_files+=("$bin_file")
          check_string="${bin_file%-*}"
            
          if [[ " ${all_tasks[@]} " =~ " $check_string " ]]; then
              continue
          else
              echo $check_string
              all_tasks+=("$check_string")
          fi
      fi
  done < <(find "$output_folder" -type f -name "*.bin")

  # Iterate through each element in list A
  for task in "${all_tasks[@]}"; do
      # Initialize an array to store items from list B containing the current elementA
      split_files=()

      # Iterate through each element in list B
      for split_file in "${all_split_files[@]}"; do
          # Check if the current elementB contains the current elementA
          if [[ "$split_file" == *"$task"* ]]; then
              # If yes, add it to the matchingItems array
              split_files+=("$split_file")
          fi
      done
      
      sorted_split_files=($(split_files_sort "${split_files[@]}"))
      concatenated_split_files=$(IFS=' '; echo "${sorted_split_files[*]}")
      output_file="$task.bin"

      command="$parcat_file $concatenated_split_files $output_file"
      echo $command
      eval $command
  done

done
