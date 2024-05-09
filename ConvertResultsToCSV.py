import os
import sys
import csv
import re
import pandas as pd
import numpy as np
import struct
import binascii

def hex2double(str):
  return struct.unpack('>d', binascii.unhexlify(str))[0]

# split_tasks = []
# split_task_files = []

sequence_names = ['Tango2', 'FoodMarket4', 'Campfire', 
                  'CatRobot', 'DaylightRoad2', 'ParkRunning3',
                  'MarketPlace', 'RitualDance', 'Cactus', 'BasketballDrive', 'BQTerrace',
                  'BasketballDrill', 'BQMall', 'PartyScene', 'RaceHorsesC',
                  'BasketballPass', 'BQSquare', 'BlowingBubbles', 'RaceHorses',
                  'FourPeople', 'Johnny', 'KristenAndSara', 
                  'BasketballDrillText', 'ArenaOfValor', 'SlideEditing', 'SlideShow',
                  'FlyingGraphics_420', 'Desktop_420', 'Console_420', 'ChineseEditing_420']

qps = ['22', '27', '32', '37']

video_sequences = {
  "A1": ["Tango2", "FoodMarket4", "Campfire"],
  "A2": ["CatRobot", "DaylightRoad2", "ParkRunning3"],
  "B": ["MarketPlace", "RitualDance", "Cactus", "BasketballDrive", "BQTerrace"],
  "C": ["BasketballDrill", "BQMall", "PartyScene", "RaceHorsesC"], 
  "D": ["BasketballPass", "BlowingBubbles", "BQSquare", "RaceHorses"],
  "E": ["FourPeople", "Johnny", "KristenAndSara"],
  "F": ["BasketballDrillText", "ArenaOfValor", "SlideEditing", "SlideShow"],
  "TGM": ["FlyingGraphic", "Desktop", "Console", "ChineseEditing"]
}

video_frame_rates = {
  "Tango2": 60,
  "FoodMarket4": 60,
  "Campfire": 30,
  "CatRobot": 60,
  "DaylightRoad2": 60,
  "ParkRunning3": 50,
  "MarketPlace": 60,
  "RitualDance": 60,
  "Cactus": 50,
  "BasketballDrive": 50,
  "BQTerrace": 60, 
  "BasketballDrill": 50,
  "BQMall": 60, 
  "PartyScene": 50,
  "RaceHorsesC": 30,
  "BasketballPass": 50,
  "BQSquare": 60,
  "BlowingBubbles": 50,
  "RaceHorses": 30,
  "FourPeople": 60,
  "Johnny": 60,
  "KristenAndSara": 60,
  "BasketballDrillText": 50,
  "ArenaOfValor": 60,
  "SlideEditing": 30,
  "SlideShow": 20,
  "FlyingGraphics_420": 60,
  "Desktop_420": 60,
  "Console_420": 60,
  "ChineseEditing_420": 60
}

def extract_after_last_ra(string):
    index = string.rfind("-RA-")
    if index != -1:
        return string[index + len("-RA-"):]
    else:
        return None  # Handle case when "-RA-" is not found

def count_integers(string):
    integers = re.findall(r'\d+', string)
    return len(integers)

def sort_frame_number(item):
    # Find all integers at the end of the string
    integers = re.findall(r'\d+$', item)
    # Convert the last integer to an integer and return it
    return int(integers[-1]) if integers else 0
    
def csv_file_reordering(df):
  new_df = pd.DataFrame(columns=df.columns)
  for _ in range(480):
    new_df.loc[len(new_df)] = [''] * len(new_df.columns)
  for index, row in df.iterrows():
    file_path = row['File Path']
    assign_index = 0
    if '-RA-' in file_path:
      assign_index += 120
    elif '-LB-' in file_path:
      assign_index += 240
    elif '-LP-' in file_path:
      assign_index += 360

    for i in range(len(sequence_names)):
      if '/' + sequence_names[i] + '/' in file_path:
        assign_index += 4 * i
        break

    if '-27.txt' in file_path:
      assign_index += 1
    elif '-32.txt' in file_path:
      assign_index += 2
    elif '-37.txt' in file_path:
      assign_index += 3

    if '-27-decode.txt' in file_path:
      assign_index += 1
    elif '-32-decode.txt' in file_path:
      assign_index += 2
    elif '-37-decode.txt' in file_path:
      assign_index += 3

    new_df.iloc[assign_index] = row

  return new_df

def search_files(directory, output_file):
  with open(output_file, 'w', newline='') as csvfile:
    writer = csv.writer(csvfile)
    writer.writerow(['File Path', 'Frame Count', '', 'Bit Rate', 'Y-PSNR', 'U-PSNR', 'V-PSNR', 'Encode Time', 'Decode Time', 'VM Peak'])
    for root, dirs, files in os.walk(directory):
      for file in files:
        # check file names, exclude split files
        if "-RA-" in file:
          if count_integers(extract_after_last_ra(file)) > 1:
            continue
        if file.endswith('.txt') and ~file.endswith('decode.txt'):
          file_path = os.path.relpath(os.path.join(root, file), directory)
          file_name_with_extension = os.path.basename(file_path)
          file_name, _ = os.path.splitext(file_name_with_extension)
          # match = re.search(r'/([^/0-9]*([0-9]+)[^/]*)$', file_name)
          # if match:
          #   # Get the matched part containing integers
          #   matched_part = match.group(1)          
          #   # Count the number of integers in the matched part
          #   num_integers = len(re.findall(r'\d+', matched_part))
          #   # Skip splitted sequences
          #   if num_integers > 1:
          #     # split_task_files.append(file_path)
          #     # task = file_name.rsplit('-', 1)[0]
          #     # if task not in split_tasks:
          #     #   split_tasks.append(task)
          #     continue
          if "-RA-" in file_name:
            index = file_name.find("-RA-")
            if len(re.findall(r'\d+', file_name[index:])) > 1:
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

  # df = pd.read_csv(output_file)
  # df['File Path Upper'] = df['File Path'].str.upper()
  # df = df.sort_values(by=['File Path Upper'], ascending = True)
  # del df['File Path Upper']
  # df.to_csv(output_file, index = False)

def search_split_files(directory, output_file):
  with open(output_file, 'a', newline='') as csvfile:
    writer = csv.writer(csvfile)
    for video_class in video_sequences.keys():
      for sequence in video_sequences[video_class]:
        video_directory = os.path.join(directory, "Class" + video_class, sequence)
        for qp in qps:
          split_log_files = []
          for root, dirs, files in os.walk(video_directory):
            for file in files:
              if not file.endswith('.txt'):
                continue
              if file.endswith('decode.txt'):
                continue
              if "-RA-" not in file:
                continue
              qp_and_frame_number = extract_after_last_ra(file)
              if qp != qp_and_frame_number.split('-')[0]:
                continue
              if count_integers(qp_and_frame_number) < 2:
                continue
              split_log_files.append(os.path.join(root, file))

          if len(split_log_files) == 0:
            continue
          
          # rank
          split_log_files = sorted(split_log_files, key = sort_frame_number)

          frame_count = 0
          total_bits = 0
          y_PSNR_sum = 0.0
          u_PSNR_sum = 0.0
          v_PSNR_sum = 0.0
          for i in range(len(split_log_files)):
            with open(split_log_files[i], 'r') as txtfile:
              found_first = False
              for line in txtfile:
                match_bits = re.search(r"(\d+) bits", line)
                match_psnr = re.search(r"xY (\w{16}) xU (\w{16}) xV (\w{16})", line)
                if match_bits and match_psnr:
                  if (not found_first) and i > 0: # discard first frame
                    found_first = True
                    continue
                  total_bits += int(match_bits.group(1))
                  y_PSNR_sum += hex2double(match_psnr.group(1))
                  u_PSNR_sum += hex2double(match_psnr.group(2))
                  v_PSNR_sum += hex2double(match_psnr.group(3))
                  frame_count += 1

          task_string = os.path.join("Class" + video_class, sequence, "log-" + sequence + "-RA-" + qp + ".txt")
          row_values = [task_string, '', '', str(float(total_bits)/(1000.0 * float(frame_count) / video_frame_rates[sequence])), str(y_PSNR_sum/frame_count), str(u_PSNR_sum/frame_count), str(v_PSNR_sum/frame_count), '', '']
          writer.writerow(row_values)
      
def search_files_decode(directory, output_file):
  with open(output_file, 'w', newline='') as csvfile:
    writer = csv.writer(csvfile)
    # writer.writerow(['File Path', 'Decode Time', '', 'VM Peak'])
    for root, dirs, files in os.walk(directory):
      for file in files:
        if file.endswith('decode.txt'):
          file_path = os.path.relpath(os.path.join(root, file), directory)
          with open(os.path.join(root, file), 'r') as txtfile:
            total_time = None
            memory_usage = None
            row_values = [file_path, '', '', '']
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
              row_values[3] = memory_usage
            if total_time or memory_usage:  
              writer.writerow(row_values)

  # df = pd.read_csv(output_file)
  # df['File Path Upper'] = df['File Path'].str.upper()
  # df = df.sort_values(by=['File Path Upper'], ascending = True)
  # del df['File Path Upper']
  # df.to_csv(output_file, index = False)
  df = pd.read_csv(output_file, header=0)
  new_df = csv_file_reordering(df)
  new_df.to_csv(output_file, index = False, header = False)


if __name__ == '__main__':
  if len(sys.argv) < 3:
    print("Usage: python program.py /path/to/directory /path/to/output_file")
    sys.exit(1)
  
  input_directory = sys.argv[1]
  output_file = sys.argv[2]
  
  convert_decode_file = False
  if len(sys.argv) >= 4:
    convert_decode_file = bool(sys.argv[3])

  # single coded files
  search_files(input_directory, output_file)
  # split coded files
  search_split_files(input_directory, output_file)
  # reorder everything
  df = pd.read_csv(output_file, header=0)
  new_df = csv_file_reordering(df)
  new_df.to_csv(output_file, index = False, header = False)

  if convert_decode_file:
    output_file_decode = output_file.replace(".csv", "-decode.csv")
    search_files_decode(input_directory, output_file_decode)
