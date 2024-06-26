import bjontegaard as bd
import pandas as pd
import sys
import os
import numpy as np

sequence_names = ['Tango2', 'FoodMarket4', 'Campfire', 
                  'CatRobot', 'DaylightRoad2', 'ParkRunning3',
                  'MarketPlace', 'RitualDance', 'Cactus', 'BasketballDrive', 'BQTerrace',
                  'BasketballDrill', 'BQMall', 'PartyScene', 'RaceHorsesC',
                  'BasketballPass', 'BQSquare', 'BlowingBubbles', 'RaceHorses',
                  'FourPeople', 'Johnny', 'KristenAndSara', 
                  'BasketballDrillText', 'ArenaOfValor', 'SlideEditing', 'SlideShow',
                  'FlyingGraphics_420', 'Desktop_420', 'Console_420', 'ChineseEditing_420']

classes = ['A1', 'A2', 'B', 'C', 'D', 'E', 'F', 'TGM']
class_indices = [0, 3, 6, 11, 15, 19, 22, 26]
class_video_counts = [3, 3, 5, 4, 4, 3, 4, 4]


configs = ['AI', 'RA', 'LB', 'LP']

def safe_float_conversion(s):
    try:
        return float(s)
    except ValueError:
        return np.nan  # or any other default value

def convert_to_numbers(data):
    for row in data:
        yield [safe_float_conversion(value) for value in row]

if __name__ == '__main__':
  if len(sys.argv) < 3:
    print("Usage: python calculate_bdrate.py /path/to/anchor.csv /path/to/test.csv")
    sys.exit(1)

  anchor_file = sys.argv[1]
  test_file =  sys.argv[2]

  if ".csv" not in anchor_file:
    anchor_file = "./Analysis/" + anchor_file + ".csv" 
  if not os.path.isfile(anchor_file):
    print("Anchor file does not exist.")
    sys.exit(1)

  if ".csv" not in test_file:
    test_file = "./Analysis/" + test_file + ".csv" 
  if not os.path.isfile(test_file):
    print("Test file does not exist.")
    sys.exit(1)

  df_anchor = pd.read_csv(anchor_file, header = None)
  df_test = pd.read_csv(test_file, header = None)

  data_anchor = df_anchor.iloc[:, 3:7].values
  data_test = df_test.iloc[:, 3:7].values

  fill_lines = [np.nan] * 4

  if len(data_test) % 4 > 0:
    for i in range(4 - (len(data_test) % 4)):
      data_test.append(fill_lines)

  current_class = ""
  current_class_result_count = 0
  class_bd_rates = [0.0, 0.0, 0.0]

  for i in range(min(len(data_anchor), len(data_test))//4):
    if i % 30 == 0:
      print(configs[i // 30])
    if (i % 30) in class_indices:
      current_class = classes[class_indices.index(i % 30)]
      current_class_result_count = 0
      class_bd_rates = [0.0, 0.0, 0.0]
      
    anchor_check = pd.DataFrame(data_anchor[i*4:i*4+4])

    if anchor_check.isna().any().any():
      continue

    anchor = data_anchor[i*4:i*4+4]
    anchor = list(convert_to_numbers(anchor))

    test = data_test[i*4:i*4+4]
    fill_anchor = 0
    for r in range(4):
      test_check = pd.DataFrame(data_test[i*4+r])
      if test_check.isna().any().any():
        test[r][:] = anchor[r][:]
        fill_anchor += 1
    if fill_anchor > 3:
      continue

    anchor = [[row[i] for row in anchor] for i in range(len(anchor[0]))]
    test = [[row[i] for row in test] for i in range(len(test[0]))]
    
    bd_rates = [0, 0, 0]
    for colour in range(3):
      bd_rates[colour] = bd.bd_rate(anchor[0], anchor[colour + 1], test[0], test[colour + 1], method = 'pchip')
      class_bd_rates[colour] += bd_rates[colour]

    plural_suffix = 's' if fill_anchor > 1 else ''
    missing_line_prompt = f'  {fill_anchor} line{plural_suffix} missing' if fill_anchor > 0 else ''
    print('{:<4}'.format(current_class), '{:<20}'.format(sequence_names[i % 30]), '{:>8.2f}'.format(bd_rates[0])+'%', '{:>8.2f}'.format(bd_rates[1])+'%', '{:>8.2f}'.format(bd_rates[2])+'%', missing_line_prompt)
    current_class_result_count += 1

    if current_class_result_count == class_video_counts[classes.index(current_class)]:
      print('{:<4}'.format(current_class), '{:<20}'.format("===== Average ====="), '{:>8.2f}'.format(class_bd_rates[0]/current_class_result_count)+'%', '{:>8.2f}'.format(class_bd_rates[1]/current_class_result_count)+'%', '{:>8.2f}'.format(class_bd_rates[2]/current_class_result_count)+'%')
      