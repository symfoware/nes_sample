; z_chip_load_y, z_chip_load_yで指定した座標のマップ情報を
; z_chip_info
; z_chip_chr1, z_chip_chr2, z_chip_chr3, z_chip_chr4
; z_chip_plt
; に設定する
; 使用
; z_chip_latitude
; z_chip_adr_low
; z_chip_adr_high
; z_chip_counter
; z_chip_load_chip
.proc load_chip
    ; 緯度を北にセット
    lda #$00
    sta z_chip_latitude

    ; 読み込むチップのy座標
    lda z_chip_load_y
    ; word単位で進むので2倍する
    clc
    adc z_chip_load_y
    tay
    ; キャリーしたかで読み込むマップの上下を判定
    bcs load_down ; 南半球

    ; 北半球のデータロード
    ; 行の座標データ取得
    lda mapup, y
    sta z_chip_adr_low
    iny
    lda mapup, y
    sta z_chip_adr_high
    jmp load_y_end

load_down: ; 南半球のデータロード
    ; 緯度を南に設定
    lda #$01
    sta z_chip_latitude

    lda mapdown, y
    sta z_chip_adr_low
    iny
    lda mapdown, y
    sta z_chip_adr_high

load_y_end:

    ; カウンター初期化
    lda #$00
    sta z_chip_counter
    ; 対象列の最初のチップロード
    ldy #$00
loop:
    lda (z_chip_adr_low), y
    sta z_chip_load_chip
    tya
    pha
    ; z_chip_load_chipに渡した圧縮情報をデコード
    jsr decode_chip

    pla
    tay
    iny

    ; 並ぶチップ数を加算
    lda z_chip_count
    clc
    adc z_chip_counter
    sta z_chip_counter
    ; 読み出し指定座標と比較
    lda z_chip_load_x
    cmp z_chip_counter
    ; 指定位置に到達するまでループ
    bcs loop

    ; 指定座標のチップ情報確定
    rts
.endproc

; ---------------------------------------------------------------------------
; z_chip_load_chipにある圧縮チップ情報を解凍
; z_chip: チップナンバー, z_count: 並んでいる数
.proc decode_chip
    ; 解析対象のデータロード
    lda z_chip_load_chip
    ; 並ぶチップス数を仮決め
    and #%00011111
    sta z_chip_count
    inc z_chip_count ; 値に1加える

    ; 上位3ビットを取得
    lda z_chip_load_chip
    and #%11100000
    
    ; 代表的なチップはここで判定してしまう
    cmp #%00000000 ; 海
    bne check_001
    ; 海確定
    lda #$00
    sta z_chip_info

    ldx #$10
    stx z_chip_chr1
    inx
    stx z_chip_chr2
    inx
    stx z_chip_chr3
    inx
    stx z_chip_chr4
    ldx #$00
    stx z_chip_plt
    rts

check_001: ; 001:砂漠(または氷)
    cmp #%00100000
    bne check_010
    ; 砂漠(氷)確定 (01 or 18)
    lda #$01
    sta z_chip_info
    
    ; 南北判定
    lda z_chip_latitude
    beq check_001_north; 北 - 氷
    
    ; 砂漠
    ldx #$14
    stx z_chip_chr1
    inx
    stx z_chip_chr2
    inx
    stx z_chip_chr3
    inx
    stx z_chip_chr4
    ldx #$01
    stx z_chip_plt
    rts

check_001_north: ; 氷
    ldx #$9c
    stx z_chip_chr1
    inx
    stx z_chip_chr2
    inx
    stx z_chip_chr3
    inx
    stx z_chip_chr4
    ldx #$00
    stx z_chip_plt
    rts


check_010: ; 草原
    cmp #%01000000
    bne check_011
    ; 草原確定
    lda #$02
    sta z_chip_info

    ldx #$15
    stx z_chip_chr1
    stx z_chip_chr2
    stx z_chip_chr3
    stx z_chip_chr4
    ldx #$03
    stx z_chip_plt
    rts

check_011: ; 茂み
    cmp #%01100000
    bne check_100
    ; 茂み確定
    lda #$03
    sta z_chip_info

    ldx #$16
    stx z_chip_chr1
    inx
    stx z_chip_chr2
    inx
    stx z_chip_chr3
    inx
    stx z_chip_chr4
    ldx #$03
    stx z_chip_plt
    rts

check_100: ; 木
    cmp #%10000000
    bne check_101
    ; 木確定
    lda #$04
    sta z_chip_info

    ldx #$a0
    stx z_chip_chr1
    inx
    stx z_chip_chr2
    inx
    stx z_chip_chr3
    inx
    stx z_chip_chr4
    ldx #$03
    stx z_chip_plt
    rts

check_101: ; 山
    cmp #%10100000
    bne check_110
    ; 山確定
    lda #$05
    sta z_chip_info

    ldx #$1a
    stx z_chip_chr1
    inx
    stx z_chip_chr2
    inx
    stx z_chip_chr3
    inx
    stx z_chip_chr4
    ldx #$02
    stx z_chip_plt
    rts

check_110: ; 岩山
    cmp #%11000000
    bne check_111
    ; 岩山確定
    lda #$06
    sta z_chip_info

    ldx #$1e
    stx z_chip_chr1
    inx
    stx z_chip_chr2
    inx
    stx z_chip_chr3
    inx
    stx z_chip_chr4
    ldx #$02
    stx z_chip_plt
    rts
    
check_111: ; 代表チップ以外
    ; 毒沼チェック countが9未満なら確定(countは1足しているので)
    lda #$08
    cmp z_chip_count
    ; 8以上なら固定チップ
    bcc check_one
    ; 毒沼確定
    lda #$07
    sta z_chip_info

    ldx #$22
    stx z_chip_chr1
    stx z_chip_chr2
    stx z_chip_chr3
    stx z_chip_chr4
    ldx #$03
    stx z_chip_plt
    rts

; 以降、1つだけ配置の特殊チップ
check_one:
    ; カウントを1に設定
    lda #$01
    sta z_chip_count

    ; チップ判定
    lda z_chip_load_chip
    
    ; 城上部左上
    cmp #%11101000
    bne check_11101001
    ; 城上部左上確定
    lda #$08
    sta z_chip_info

    ldx #$23
    stx z_chip_chr1
    inx
    stx z_chip_chr2
    inx
    stx z_chip_chr3
    inx
    stx z_chip_chr4
    ldx #$02
    stx z_chip_plt
    rts

check_11101001: ; 城上部右上
    cmp #%11101001
    bne check_11101010
    lda #$09
    sta z_chip_info

    ldx #$27
    stx z_chip_chr1
    inx
    stx z_chip_chr2
    inx
    stx z_chip_chr3
    inx
    stx z_chip_chr4
    ldx #$02
    stx z_chip_plt
    rts

check_11101010: ; 城上部左下
    cmp #%11101010
    bne check_11101011
    lda #$0a
    sta z_chip_info

    ldx #$2b
    stx z_chip_chr1
    inx
    stx z_chip_chr2
    inx
    stx z_chip_chr3
    inx
    stx z_chip_chr4
    ldx #$02
    stx z_chip_plt
    rts

check_11101011: ; 城上部右下
    cmp #%11101011
    bne check_11101100
    lda #$0b
    sta z_chip_info

    ldx #$30
    stx z_chip_chr1
    inx
    stx z_chip_chr2
    inx
    stx z_chip_chr3
    inx
    stx z_chip_chr4
    ldx #$02
    stx z_chip_plt
    rts

check_11101100: ; 街左
    cmp #%11101100
    bne check_11101101
    lda #$0c
    sta z_chip_info

    ldx #$34
    stx z_chip_chr1
    inx
    stx z_chip_chr2
    inx
    stx z_chip_chr3
    inx
    stx z_chip_chr4
    ldx #$02
    stx z_chip_plt
    rts

check_11101101: ; 街右
    cmp #%11101101
    bne check_11101110
    lda #$0d
    sta z_chip_info

    ldx #$38
    stx z_chip_chr1
    inx
    stx z_chip_chr2
    inx
    stx z_chip_chr3
    inx
    stx z_chip_chr4
    ldx #$02
    stx z_chip_plt
    rts

check_11101110: ; 村
    cmp #%11101110
    bne check_11101111
    lda #$0e
    sta z_chip_info

    ldx #$3c
    stx z_chip_chr1
    inx
    stx z_chip_chr2
    inx
    stx z_chip_chr3
    inx
    stx z_chip_chr4
    ldx #$01
    stx z_chip_plt
    rts

check_11101111: ; 祠
    cmp #%11101111
    bne check_11110000
    lda #$0f
    sta z_chip_info

    ldx #$40
    stx z_chip_chr1
    inx
    stx z_chip_chr2
    inx
    stx z_chip_chr3
    inx
    stx z_chip_chr4
    ldx #$02
    stx z_chip_plt
    rts

check_11110000: ; 塔上
    cmp #%11110000
    bne check_11110001
    lda #$10
    sta z_chip_info

    ldx #$44
    stx z_chip_chr1
    inx
    stx z_chip_chr2
    inx
    stx z_chip_chr3
    inx
    stx z_chip_chr4
    ldx #$01
    stx z_chip_plt
    rts

check_11110001: ; 塔下
    cmp #%11110001
    bne check_11110010
    lda #$11
    sta z_chip_info

    ldx #$48
    stx z_chip_chr1
    inx
    stx z_chip_chr2
    inx
    stx z_chip_chr3
    inx
    stx z_chip_chr4
    ldx #$01
    stx z_chip_plt
    rts

check_11110010: ; 洞窟
    cmp #%11110010
    bne check_11110011
    lda #$12
    sta z_chip_info

    ldx #$4c
    stx z_chip_chr1
    inx
    stx z_chip_chr2
    inx
    stx z_chip_chr3
    inx
    stx z_chip_chr4
    ldx #$02
    stx z_chip_plt
    rts

check_11110011: ; 岩礁
    cmp #%11110011
    bne check_11110100
    lda #$13
    sta z_chip_info

    ldx #$50
    stx z_chip_chr1
    inx
    stx z_chip_chr2
    inx
    stx z_chip_chr3
    inx
    stx z_chip_chr4
    ldx #$00
    stx z_chip_plt
    rts

check_11110100: ; 橋左右
    cmp #%11110100
    bne check_11110101
    lda #$14
    sta z_chip_info

    ldx #$54
    stx z_chip_chr1
    inx
    stx z_chip_chr2
    inx
    stx z_chip_chr3
    inx
    stx z_chip_chr4
    ldx #$00
    stx z_chip_plt
    rts

check_11110101: ; 橋上下
    cmp #%11110101
    bne check_11110110
    lda #$15
    sta z_chip_info

    ldx #$58
    stx z_chip_chr1
    inx
    stx z_chip_chr2
    inx
    stx z_chip_chr3
    inx
    stx z_chip_chr4
    ldx #$00
    stx z_chip_plt
    rts

check_11110110: ; ピラミッド
    cmp #%11110110
    bne check_11110111
    lda #$16
    sta z_chip_info

    ldx #$5c
    stx z_chip_chr1
    inx
    stx z_chip_chr2
    inx
    stx z_chip_chr3
    inx
    stx z_chip_chr4
    ldx #$01
    stx z_chip_plt
    rts

check_11110111: ; ブランク(火口)
    lda #$17
    sta z_chip_info

    ldx #$00
    stx z_chip_chr1
    stx z_chip_chr2
    stx z_chip_chr3
    stx z_chip_chr4
    stx z_chip_plt

    rts
.endproc
