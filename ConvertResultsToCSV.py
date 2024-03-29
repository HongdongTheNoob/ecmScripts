import os
import sys
import csv
import re
import pandas as pd

split_tasks = []
split_task_files = []

def search_files(directory, output_file):
  with open(output_file, 'w', newline='') as csvfile:
    writer = csv.writer(csvfile)
    writer.writerow(['File Path', 'Frame Count', '', 'Bit Rate', 'Y-PSNR', 'U-PSNR', 'V-PSNR', 'Encode Time', 'Decode Time', 'VM Peak'])
    for root, dirs, files in os.walk(directory):
      for file in files:
        if file.endswith('.txt') and ~file.endswith('decode.txt'):
          file_path = os.path.relpath(os.path.join(root, file), directory)
          file_name_with_extension = os.path.basename(file_path)
          file_name, _ = os.path.splitext(file_name_with_extension)
          match = re.search(r'/([^/0-9]*([0-9]+)[^/]*)$', file_name)
          if match:
            # Get the matched part containing integers
            matched_part = match.group(1)          
            # Count the number of integers in the matched part
            num_integers = len(re.findall(r'\d+', matched_part))
            # Skip splitted sequences
            if num_integers > 1:
              split_task_files.append(file_path)
              task = file_name.rsplit('-', 1)[0]
              if task not in split_tasks:
                split_tasks.append(task)
              continue
          with open(os.path.join(root, file), 'r') as txtfile:
            found_line = False
            vm_peak = ['']
            total_time = None
            row_values = ['', '', '', '', '', '', '', '']
            for line in txtfile:
              match = re.search(r'(\d+)\s+([a-zA-Z])\s+(\d+\.\d+)\s+(\d+\.\d+)\s+(\d+\.\d+)\s+(\d+\.\d+)\s+(\d+\.\d+)', line)
              if match:
                row_values = [file_path, match.group(1), match.group(2), match.group(3), match.group(4), match.group(5), match.group(6)]
                found_line = True
              if line.__contains__('VmPeak'):
                vm_match = re.search(r'\d+', line)
                if vm_match:
                  vm_peak = vm_match.group()
              if found_line and line.startswith(' Total Time'):
                total_time_match = re.search(r'(\d+\.\d+)', line)
                if total_time_match:
                  total_time = total_time_match.group(1)
                break
            if found_line and vm_match and total_time:
              row_values.append(total_time)
              row_values.append('')
              row_values.append(vm_peak)
              writer.writerow(row_values)

  df = pd.read_csv(output_file)
  df['File Path Upper'] = df['File Path'].str.upper()
  df = df.sort_values(by=['File Path Upper'], ascending = True)
  del df['File Path Upper']
  df.to_csv(output_file, index = False)

# def search_split_files(output_file):
#   with open(output_file, 'a', newline='') as csvfile:
#     for task in split_tasks:
      
def search_files_decode(directory, output_file):
  with open(output_file, 'w', newline='') as csvfile:
    writer = csv.writer(csvfile)
    writer.writerow(['File Path', 'Decode Time', 'VM Peak'])
    for root, dirs, files in os.walk(directory):
      for file in files:
        if file.endswith('decode.txt'):
          file_path = os.path.relpath(os.path.join(root, file), directory)
          with open(os.path.join(root, file), 'r') as txtfile:
            total_time = None
            memory_usage = None
            row_values = [file_path, '', '']
            for line in txtfile:
              if line.startswith(' Total Time'):
                total_time_match = re.search(r'(\d+\.\d+)', line)
                if total_time_match:
                  total_time = total_time_match.group(1)
              if line.startswith('Memory Usage'):
                memory_usage_match = re.search(r'\d+', line)
                if memory_usage_match:
                  memory_usage = memory_usage_match.group() 
            if total_time:
              row_values[1] = total_time
            if memory_usage:
              row_values[2] = memory_usage
            if total_time or memory_usage:  
              writer.writerow(row_values)

  df = pd.read_csv(output_file)
  df['File Path Upper'] = df['File Path'].str.upper()
  df = df.sort_values(by=['File Path Upper'], ascending = True)
  del df['File Path Upper']
  df.to_csv(output_file, index = False)

if __name__ == '__main__':
  if len(sys.argv) < 3:
    print("Usage: python program.py /path/to/directory /path/to/output_file")
    sys.exit(1)
  
  input_directory = sys.argv[1]
  output_file = sys.argv[2]

  # single coded files
  search_files(input_directory, output_file)
  # split coded files
  # search_split_files(output_file)

  output_file_decode = output_file.replace(".csv", "-decode.csv")
  search_files_decode(input_directory, output_file_decode)
