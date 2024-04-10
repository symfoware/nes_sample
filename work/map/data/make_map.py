mapping1 = {
    # 000:海 - p0 - 0, 37, 1, 2, 4, 6, 7, 12, 13, 14, 15, 19, 21, 22, 23, 24, 39, 42, 43, 44
    0: '000', 37: '000', 1: '000', 2: '000', 4: '000', 6: '000', 7: '000', 12: '000', 13: '000', 14: '000', 15: '000', 19: '000', 21: '000', 22: '000', 23: '000', 24: '000', 39: '000', 42: '000', 43: '000', 44: '000',
    # 001:砂漠(または氷) - p1 - 36, 5
    36:'001', 5:'001',
    # 010:草原 - p3 - 9
    9: '010',
    # 011:茂み - p3 - 8
    8: '011',
    # 100:木 - p1 - 3, 35
    3:'100', 35:'100',
    # 101:山 - p2 - 20
    20: '101',
    # 110:岩山 - p2 - 18
    18: '110',
    # 111:毒沼 - p3 - 34
    34: '111',
}
mapping2 = {
    # 01000:城上部左上 - p2 - 26
    26: '01000',
    # 01001:城上部右上 - p2 - 27
    27: '01001',
    # 01010:城上部左下 - p2 - 28
    28: '01010',
    # 01011:城上部右下 - p2 - 29
    29: '01011',
    # 01100:街左 - p2 - 10
    10: '01100',
    # 01101:街右 - p2 - 11
    11: '01101',
    # 01110:村 - p1 - 25
    25: '01110',
    # 01111:祠 - p2 - 30
    30: '01111',
    # 10000:塔上 - p1 - 32
    32: '10000',
    # 10001:塔下 - p1 - 33
    33: '10001',
    # 10010:洞窟 - p2 - 17
    17: '10010',
    # 10011:岩礁 - p0 - 16
    16: '10011',
    # 10100:橋左右 - p0 - 31
    31: '10100',
    # 10101:橋上下 - p0 - 41
    41: '10101',
    # 10111:ピラミッド - p1 - 38
    38: '10111',
    # 11000::ブランク(火口) - 40
    40: '11000'
}

def get_chip_number(d):
    d = int(d)
    chip = None
    if d in mapping1:
        chip = mapping1[d]
    elif d in mapping2:
        chip = mapping2[d]
    else:
        print('not found %d' % d)
    return chip

def make_binary(chip, count):
    return chip+format(count-1, 'b').zfill(5)

def make_line_binary(row_index, line):
    data = line.strip().split(',')
    current = ''
    count = 0
    ary = []
    # max: 32
    for d in data:
        chip = get_chip_number(d)
        # 頻出チップ
        if len(chip) == 3:
            # 前と同じなら加算
            if current == chip:
                count += 1
                # maxに達したら出力
                if 32 <= count:
                    ary.append(make_binary(current, count))
                    count = 0
            else:
                # 前のチップ情報があったら一旦出力
                if count:
                    ary.append(make_binary(current, count))
                current = chip
                count = 1
        else:
            # 前のチップ情報があったら一旦出力
            if count:
                ary.append(make_binary(current, count))
            ary.append('111'+chip)
            current = chip
            count = 0

    mapline = 'map%d .byte ' % (row_index)
    mapline += '%'+', %'.join(ary)
    return mapline
    

def main():
    with open('mapdata.asm', 'w') as map, \
        open('mapinfo.txt', 'r') as f:
        for i, line in enumerate(f):
            row = make_line_binary(i, line)
            map.write(row+'\n')


if __name__ == '__main__':
    main()



"""
map:
    .byte %10000000, %00000001, %10000000, %00000001, %10000000, %00000001


チップの並び
000:海 - p0 - 0, 37, 1, 2, 4, 6, 7, 12, 13, 14, 15, 19, 21, 22, 23, 24, 39, 42, 43, 44
001:砂漠(または氷) - p1 - 36, 5
010:草原 - p3 - 9
011:茂み - p3 - 8
100:木 - p1 - 3, 35
101:山 - p2 - 20
110:岩山 - p2 - 18
111:毒沼 - p3 - 34
01000:城上部左上 - p2 - 26
01001:城上部右上 - p2 - 27
01010:城上部左下 - p2 - 28
01011:城上部右下 - p2 - 29
01100:街左 - p2 - 10
01101:街右 - p2 - 11
01110:村 - p1 - 25
01111:祠 - p2 - 30
---
10000:塔上 - p1 - 32
10001:塔下 - p1 - 33
10010:洞窟 - p2 - 17
10011:岩礁 - p0 - 16
10100:橋左右 - p0 - 31
10101:橋上下 - p0 - 41
10111:ピラミッド - p1 - 38
11000::ブランク(火口) - 40
"""