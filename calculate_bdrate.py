import bjontegaard as bd
import pandas as pd
import sys

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

configs = ['AI', 'RA', 'LB', 'LP']

if __name__ == '__main__':
  if len(sys.argv) < 3:
    print("Usage: python calculate_bdrate.py /path/to/anchor.csv /path/to/test.csv")
    sys.exit(1)

  anchor_file = sys.argv[1]
  test_file =  sys.argv[2]

  df_anchor = pd.read_csv(anchor_file, header = None)
  df_test = pd.read_csv(test_file, header = None)

  data_anchor = df_anchor.iloc[:, 3:7].values
  data_test = df_test.iloc[:, 3:7].values

  # for i in range(len(data_anchor) // 4):

  current_class = ""
  for i in range(60):
    if i % 30 == 0:
      print(configs[i // 30])
    if (i % 30) in class_indices:
      current_class = classes[i % 30]
      
    anchor_check = pd.DataFrame(data_anchor[i*4:i*4+4])
    test_check = pd.DataFrame(data_test[i*4:i*4+4])

    if anchor_check.isna().any().any() or test_check.isna().any().any():
      continue

    anchor = data_anchor[i*4:i*4+4]
    test = data_test[i*4:i*4+4]
    anchor = [[row[i] for row in anchor] for i in range(len(anchor[0]))]
    test = [[row[i] for row in test] for i in range(len(test[0]))]
    
    bd_rates = [0, 0, 0]
    for colour in range(3):
      bd_rates[colour] = bd.bd_rate(anchor[0], anchor[colour + 1], test[0], test[colour + 1], method = 'pchip')

    print('{:<3}'.format(current_class), '{:<20}'.format(sequence_names[i % 30]), '{:>8.2f}'.format(bd_rates[0])+'%', '{:>8.2f}'.format(bd_rates[1])+'%', '{:>8.2f}'.format(bd_rates[2])+'%')
