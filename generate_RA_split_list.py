frame_counts = {
    'Tango2': 294,
    'FoodMarket4': 300,
    'Campfire': 300,
    'CatRobot': 300,
    'DaylightRoad2': 300,
    'ParkRunning3': 300,
    'MarketPlace': 600,
    'RitualDance': 600,
    'Cactus': 500,
    'BasketballDrive': 500,
    'BQTerrace': 600,
    'RaceHorsesC': 300,
    'BQMall': 600,
    'PartyScene': 500,
    'BasketballDrill': 500,
    'RaceHorses': 300,
    'BQSquare': 600,
    'BlowingBubbles': 500,
    'BasketballPass': 500,
    'FourPeople': 600,
    'Johnny': 600,
    'KristenAndSara': 600,
    'ArenaOfValor': 600,
    'BasketballDrillText': 500,
    'SlideEditing': 300,
    'SlideShow': 500,
    'FlyingGraphics_420': 300,
    'Desktop_420': 600,
    'Console_420': 600,
    'ChineseEditing_420': 600,
}

ip_32 = ['Campfire', 'RaceHorsesC', 'RaceHorses', 'SlideEditing', 'SlideShow']

classes = ['A', 'B', 'C', 'D', 'F', 'TGM']

def find_frame_count(input_string, duration_dict):
    for key in duration_dict:
        if key in input_string:
            return duration_dict[key]
    return None

def contains_substring(s, lst):
    for substr in lst:
        if substr in s:
            return True
    return False

for c in classes:
  with open('./sort/sort_list_' + c + '_RA_split.txt', 'w') as output_file:
    with open('./sort/sort_list_' + c + '_RA.txt', 'r') as sort_list_file:
      lines = sort_list_file.read().splitlines()
      for line in lines:
        if not line.startswith('RA'):
          continue

        ip = 64

        if contains_substring(line, ip_32):
          ip = 32

        frame_count = find_frame_count(line, frame_counts)
        for i in range(0, frame_count, ip):
          line_to_write = line + ' ' + str(i) + ' ' + str(min(ip + 1, frame_count - i)) + '\n'
          output_file.write(line_to_write)
