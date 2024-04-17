.setcpu "6502"
.autoimport  on

; iNESヘッダ "HEADER"はcfgのSEGMENTSで定義
.segment "HEADER"
    .byte $4E, $45, $53, $1A    ; "NES" Header
    .byte $02                   ; PRG-BANKS
    .byte $01                   ; CHR-BANKS
    .byte $01                   ; Vetrical Mirror
    .byte $00                   ; 
    .byte $00, $00, $00, $00    ; 
    .byte $00, $00, $00, $00    ; 

.segment "STARTUP" ; "STARTUP"はcfgのSEGMENTSで定義
; リセット割り込み
.proc reset
    sei ; 割り込み不可
    cld ; デシマルモードクリア(作法)
    ldx #$ff
    txs ; スタックポインタ初期化

; スクリーンオフ
    lda #$00
    sta $2000 ; 基本設定をクリア
    sta $2001 ; マスク設定をクリア

; パレットテーブルへ転送
; VRAM BG用パレット $3F00～$3F0F へ転送を実施
; VRAM スプライト用パレット $3F10～$3F1F へ転送を実施
    lda #$3f ; VRAMアドレス上位1byte
    sta $2006
    lda #$00 ; VRAMアドレス下位1byte
    sta $2006 ; $2006 へ2回 store を行うことでVRAMのアクセス先番地を設定
    ldx #$00
    ldy #$20
copypal:
    lda palettes, x ; palettes + xの値をaへロード
    sta $2007 ; VRAMへデータ書き込み実行
    inx ; xインクリメント
    dey ; yデクリメント
    bne copypal ; yデクリメントの結果0にならなかったらcopypalに戻る


; マップの表示テスト
    jsr load_debug

; BGのスクリーン表示位置設定左上にぴったり(スクロール設定)
    lda #$00
    sta $2005
    sta $2005

; スクリーンオン
    lda #%11001000 ; NMI実行あり,BGのキャラクタテーブル番号を1に
    sta $2000
    lda #%00001110 ; スプライト表示,BG表示,左端8x8のスプライト表示,左端8x8のBG表示
    sta $2001
    
; ---------------------------------------------------------------------------------
; 無限ループ
infinity_loop:
    jmp infinity_loop

.endproc


; マップの読み込みテスト
.proc load_debug

; マップ情報を表示
    ; x:$07, y:$1d エジンベア
    ; x:$9f, y:$cd アリアハン
    ; x:$95, y:$b3 レーベ
    lda #$da
    sta z_debug4
    sta z_load_x
    lda #$96
    sta z_load_y


    lda #$20
    sta z_debug1
    lda #$00
    sta z_debug2
    lda #$20
    sta z_debug3
    jsr load_debug_line
; 2行目--
    lda z_debug4
    sta z_load_x
    inc z_load_y

    lda #$20
    sta z_debug1
    lda #$40
    sta z_debug2
    lda #$60
    sta z_debug3
    jsr load_debug_line

; 3行目--
    lda z_debug4
    sta z_load_x
    inc z_load_y

    lda #$20
    sta z_debug1
    lda #$80
    sta z_debug2
    lda #$a0
    sta z_debug3
    jsr load_debug_line

; 4行目--
    lda z_debug4
    sta z_load_x
    inc z_load_y

    lda #$20
    sta z_debug1
    lda #$c0
    sta z_debug2
    lda #$e0
    sta z_debug3
    jsr load_debug_line


; 5行目--
    lda z_debug4
    sta z_load_x
    inc z_load_y

    lda #$21
    sta z_debug1
    lda #$00
    sta z_debug2
    lda #$20
    sta z_debug3
    jsr load_debug_line


; 6行目--
    lda z_debug4
    sta z_load_x
    inc z_load_y

    lda #$21
    sta z_debug1
    lda #$40
    sta z_debug2
    lda #$60
    sta z_debug3
    jsr load_debug_line

; 7行目--
    lda z_debug4
    sta z_load_x
    inc z_load_y

    lda #$21
    sta z_debug1
    lda #$80
    sta z_debug2
    lda #$a0
    sta z_debug3
    jsr load_debug_line

; 8行目--
    lda z_debug4
    sta z_load_x
    inc z_load_y

    lda #$21
    sta z_debug1
    lda #$c0
    sta z_debug2
    lda #$e0
    sta z_debug3
    jsr load_debug_line

; 9行目--
    lda z_debug4
    sta z_load_x
    inc z_load_y

    lda #$22
    sta z_debug1
    lda #$00
    sta z_debug2
    lda #$20
    sta z_debug3
    jsr load_debug_line

; 10行目--
    lda z_debug4
    sta z_load_x
    inc z_load_y

    lda #$22
    sta z_debug1
    lda #$40
    sta z_debug2
    lda #$60
    sta z_debug3
    jsr load_debug_line

; 11行目--
    lda z_debug4
    sta z_load_x
    inc z_load_y

    lda #$22
    sta z_debug1
    lda #$80
    sta z_debug2
    lda #$a0
    sta z_debug3
    jsr load_debug_line

; 12行目--
    lda z_debug4
    sta z_load_x
    inc z_load_y

    lda #$22
    sta z_debug1
    lda #$c0
    sta z_debug2
    lda #$e0
    sta z_debug3
    jsr load_debug_line

; 13行目--
    lda z_debug4
    sta z_load_x
    inc z_load_y

    lda #$23
    sta z_debug1
    lda #$00
    sta z_debug2
    lda #$20
    sta z_debug3
    jsr load_debug_line

; 14行目--
    lda z_debug4
    sta z_load_x
    inc z_load_y

    lda #$23
    sta z_debug1
    lda #$40
    sta z_debug2
    lda #$60
    sta z_debug3
    jsr load_debug_line

; 15行目--
    lda z_debug4
    sta z_load_x
    inc z_load_y

    lda #$23
    sta z_debug1
    lda #$80
    sta z_debug2
    lda #$a0
    sta z_debug3
    jsr load_debug_line

    rts
.endproc



; 指定座標1行分ロード
.proc load_debug_line
    lda #$10
    sta z_debug


loop:
    jsr load_chip

    ; 描画
    lda z_debug1
    sta $2006
    lda z_debug2
    sta $2006
    lda z_chip_chr1
    sta $2007
    lda z_chip_chr2
    sta $2007
    lda z_debug1
    sta $2006
    lda z_debug3
    sta $2006
    lda z_chip_chr3
    sta $2007
    lda z_chip_chr4
    sta $2007

    inc z_debug2
    inc z_debug2
    inc z_debug3
    inc z_debug3

    inc z_load_x
    dec z_debug
    lda z_debug
    bne loop

    ; パレットは一旦保留
    ;lda #$23
    ;sta $2006
    ;lda #$c0
    ;sta $2006
    ;lda z_chip_plt
    ;sta $2007

    rts
.endproc


; ---------------------------------------------------------------------------
.proc load_chip
    ; 緯度を北にセット
    lda #$00
    sta z_latitude

    ; 読み込むチップのy座標
    lda z_load_y
    ; word単位で進むので2倍する
    clc
    adc z_load_y
    tay
    ; キャリーしたかで読み込むマップの上下を判定
    bcs load_down ; 南半球

    ; 北半球のデータロード
    ; 行の座標データ取得
    lda mapup, y
    sta z_adr_low
    iny
    lda mapup, y
    sta z_adr_high
    jmp load_y_end

load_down: ; 南半球のデータロード
    ; 緯度を南に設定
    lda #$01
    sta z_latitude

    lda mapdown, y
    sta z_adr_low
    iny
    lda mapdown, y
    sta z_adr_high

load_y_end:

    ; カウンター初期化
    lda #$00
    sta z_counter
    ; 対象列の最初のチップロード
    ldy #$00
loop:
    lda (z_adr_low), y
    sta z_load_chip
    tya
    pha
    ; z_load_chipに渡した圧縮情報をデコード
    jsr decode_chip

    pla
    tay
    iny

    ; 並ぶチップ数を加算
    lda z_chip_count
    clc
    adc z_counter
    sta z_counter
    ; 読み出し指定座標と比較
    lda z_load_x
    cmp z_counter
    ; 指定位置に到達するまでループ
    bcs loop

    ; 指定座標のチップ情報確定
    rts
.endproc


; ---------------------------------------------------------------------------
; z_load_chipにある圧縮チップ情報を解凍
; z_chip: チップナンバー, z_count: 並んでいる数
.proc decode_chip
    ; 解析対象のデータロード
    lda z_load_chip
    ; 並ぶチップス数を仮決め
    and #%00011111
    sta z_chip_count
    inc z_chip_count ; 値に1加える

    ; 上位3ビットを取得
    lda z_load_chip
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
    lda z_latitude
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
    lda z_load_chip
    
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



; ---------------------------------------------------------------------------


; ---------------------------------------------------------------------------
; VBlank中に行う処理
; ---------------------------------------------------------------------------
; ---------------------------------------------------------------------------
.proc vblank_loop

    ; VBlank中に値を書き換えると、呼び出し元の処理が壊れるので一旦退避
    ; これで様子見
    pha ; Aをスタックに
    txa ; X -> A
    pha ; A(=X)をスタックに
    tya ; Y -> A
    pha ; A(=Y)をスタックに
    php ; ステータスをスタックに

    inc z_frame ; フレームカウンター

    ; 退避した値を復帰
    ; 戻すときはスタックに積んだのと逆順で
    plp ; ステータス
    pla
    tay ; Y
    pla
    tax ; X
    pla ; A
    
    rti ; VBlank割り込みから復帰 ここでは何も行わず、後の流れのrtiで処理しても良さそう
.endproc


; ハード、ソフトウェア割り込み
.proc irq
    rti
.endproc


; ---------------------------------------------------------------------------
; データ定義
; ---------------------------------------------------------------------------
; パレットテーブル
palettes:
    ; BG
    .byte $0f, $30, $0c, $1c
    .byte $0f, $17, $27, $2a
    .byte $0f, $10, $00, $2a
    .byte $0f, $2a, $19, $27
    ; スプライト
    .byte $0f, $00, $10, $39
    .byte $0f, $16, $16, $26
    .byte $0f, $00, $18, $28
    .byte $0f, $0a, $10, $2a


; マップ情報
.include "mapdata.asm"

; 変数定義
.org $0000 ; ゼロページ領域
z_frame: .byte $00 ; VBlank毎にカウントアップ
z_chip_info: .byte $00 ; 読み込んだチップ情報
z_chip_count: .byte $00 ; 読み込んだチップのカウント
z_chip_chr1: .byte $00
z_chip_chr2: .byte $00
z_chip_chr3: .byte $00
z_chip_chr4: .byte $00
z_chip_plt: .byte $00

.org $0010
; サブルーチン呼び出し用の一時領域
z_load_x: .byte $00 ; 読み込むチップの座標x
z_load_y: .byte $00 ; 読み込むチップの座標y
z_load_chip: .byte $00 ; 読み込みチップの圧縮情報
z_adr_low: .byte $00 ; 間接アドレッシング用low
z_adr_high: .byte $00 ; 間接アドレッシング用high
z_latitude: .byte $00 ; 砂漠、氷判定用緯度 0:北半球, 1:南半球

.org $0040
z_counter: .byte $00

.org $0050
z_debug: .byte $00
z_debug1: .byte $00
z_debug2: .byte $00
z_debug3: .byte $00
z_debug4: .byte $00
; スタック領域は$0100~$01ff

; マップデータワーク
.org $0200
w_map: .byte $00


.segment "VECINFO"
    .word vblank_loop ; VBlank割り込み時に実行するルーチン
    .word reset ; リセット割り込み
    .word irq ; ハードウェア割り込みとソフトウェア割り込み

; パターンテーブル
.segment "CHARS"
    .incbin "dq3.chr"
    .incbin "empty.chr"
    
