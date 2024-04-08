from PIL import Image  

# 16x16の範囲を読み込み
# 適当にハッシュを取ればチップが海か陸かなどの判定が行えるのでは？
def read_chip(im, cx, cy):
    line = ''
    
    for y in range(cy * 16, cy * 16 + 16):
        for x in range(cx * 16, cx * 16 + 16):
            # png画像を読み込んでいるので、getpixelはrgbではなくカラーパレットの情報を返す
            # 画素判定を行う分にはこちらの方が都合がよい
            line += format(im.getpixel((x, y)), 'x')

    return line

def write_chip(chip, im, x, y, index):
    
    lines = []
    for i in range(16):
        lines.append(chip[0:16])
        chip = chip[16:]
        #lines.append(chip[i*16:i*16+16])

    with open('images/%s.txt' % (index), 'w') as f:
        f.write('\n'.join(lines))

    # 対応する画像を出力
    tx = x * 16
    ty = y * 16
    im_crop = im.crop((tx, ty, tx+16, ty+16))
    im_crop = im_crop.resize((256, 256))
    im_crop.save('images/%s.png' % (index))


def main():
    im = Image.open('3tikyu1.png')  # 画像を開く  
    width, height = im.size

    chips = {}
    mapinfo = open('mapinfo.txt', 'w')
    for y in range(256):
        chipfinfo = []
        for x in range(256):
            chip = read_chip(im, x, y)
            if chip in chips:
                chipfinfo.append(str(chips[chip]))
                continue
            chips[chip] = len(chips)
            write_chip(chip, im, x, y, str(chips[chip]))
            chipfinfo.append(str(chips[chip]))

        mapinfo.write(','.join(chipfinfo))
        mapinfo.write('\n')


    mapinfo.close()

if __name__ == '__main__':
    main()


