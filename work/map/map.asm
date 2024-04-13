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

; マップ情報を表示
    ; 初期mapをネームテーブル0へ
    jsr load_map_test

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

; ---------------------------------------------------------------------------
.proc load_map
    ldx #$00
    lda map16, x
    ; 上位3ビットを取得
    and #%11100000
    lsr
    lsr
    lsr
    lsr
    lsr
    sta z_chip
    lda map16, x
    and #%00011111
    sta  z_count
    jsr load_chip
    ; z_count: .byte $00
    ;sta z_debug
    rts
.endproc

.proc load_chip
    lda z_chip
    cmp #$00
    beq chip000

chip000:
    jsr s_chip000
    jmp end

end:

    rts
.endproc

; 海描画
.proc s_chip000
    ; 000:海
    lda #$20
    sta $2006
    lda #$00
    sta $2006
    lda #$10
    sta $2007
    lda #$11
    sta $2007
    lda #$20
    sta $2006
    lda #$20
    sta $2006
    lda #$12
    sta $2007
    lda #$13
    sta $2007
    rts    
.endproc


; ---------------------------------------------------------------------------
.proc load_map_test
    ; 000:海
    lda #$20
    sta $2006
    lda #$00
    sta $2006
    lda #$10
    sta $2007
    lda #$11
    sta $2007
    lda #$20
    sta $2006
    lda #$20
    sta $2006
    lda #$12
    sta $2007
    lda #$13
    sta $2007

    ; 001:砂漠(または氷) - p1 - 36, 5
    lda #$20
    sta $2006
    lda #$02
    sta $2006
    lda #$14
    sta $2007
    sta $2007
    lda #$20
    sta $2006
    lda #$22
    sta $2006
    lda #$14
    sta $2007
    sta $2007

    ; 010:草原 - p3 - 9
    lda #$20
    sta $2006
    lda #$04
    sta $2006
    lda #$15
    sta $2007
    sta $2007
    lda #$20
    sta $2006
    lda #$24
    sta $2006
    lda #$15
    sta $2007
    sta $2007

    ; 011:茂み - p3 - 8
    lda #$20
    sta $2006
    lda #$06
    sta $2006
    lda #$16
    sta $2007
    lda #$17
    sta $2007
    lda #$20
    sta $2006
    lda #$26
    sta $2006
    lda #$18
    sta $2007
    lda #$19
    sta $2007

    ; 100:木 - p3 - 3, 35
    lda #$20
    sta $2006
    lda #$08
    sta $2006
    lda #$a0
    sta $2007
    lda #$a1
    sta $2007
    lda #$20
    sta $2006
    lda #$28
    sta $2006
    lda #$a2
    sta $2007
    lda #$a3
    sta $2007

    ; 101:山 - p2 - 20
    lda #$20
    sta $2006
    lda #$0a
    sta $2006
    lda #$1a
    sta $2007
    lda #$1b
    sta $2007
    lda #$20
    sta $2006
    lda #$2a
    sta $2006
    lda #$1c
    sta $2007
    lda #$1d
    sta $2007

    ; 110:岩山 - p2 - 18
    lda #$20
    sta $2006
    lda #$0c
    sta $2006
    lda #$1e
    sta $2007
    lda #$1f
    sta $2007
    lda #$20
    sta $2006
    lda #$2c
    sta $2006
    lda #$20
    sta $2007
    lda #$21
    sta $2007

    ; 111:毒沼 - p3 - 34
    lda #$20
    sta $2006
    lda #$0e
    sta $2006
    lda #$22
    sta $2007
    sta $2007
    lda #$20
    sta $2006
    lda #$2e
    sta $2006
    lda #$22
    sta $2007
    sta $2007

    ; 01100:街左 - p2 - 10
    lda #$20
    sta $2006
    lda #$10
    sta $2006
    lda #$34
    sta $2007
    lda #$35
    sta $2007
    lda #$20
    sta $2006
    lda #$30
    sta $2006
    lda #$36
    sta $2007
    lda #$37
    sta $2007
    ; 01101:街右 - p2 - 11
    lda #$20
    sta $2006
    lda #$12
    sta $2006
    lda #$38
    sta $2007
    lda #$39
    sta $2007
    lda #$20
    sta $2006
    lda #$32
    sta $2006
    lda #$3a
    sta $2007
    lda #$3b
    sta $2007

    ; 01110:村 - p1 - 25
    lda #$20
    sta $2006
    lda #$14
    sta $2006
    lda #$3c
    sta $2007
    lda #$3d
    sta $2007
    lda #$20
    sta $2006
    lda #$34
    sta $2006
    lda #$3e
    sta $2007
    lda #$3f
    sta $2007

    ; 01111:祠 - p2 - 30
    lda #$20
    sta $2006
    lda #$16
    sta $2006
    lda #$40
    sta $2007
    lda #$41
    sta $2007
    lda #$20
    sta $2006
    lda #$36
    sta $2006
    lda #$42
    sta $2007
    lda #$43
    sta $2007

    ; 10010:洞窟 - p2 - 17
    lda #$20
    sta $2006
    lda #$18
    sta $2006
    lda #$4c
    sta $2007
    lda #$4d
    sta $2007
    lda #$20
    sta $2006
    lda #$38
    sta $2006
    lda #$4e
    sta $2007
    lda #$4f
    sta $2007

    ; 10011:岩礁 - p0 - 16
    lda #$20
    sta $2006
    lda #$1a
    sta $2006
    lda #$50
    sta $2007
    lda #$51
    sta $2007
    lda #$20
    sta $2006
    lda #$3a
    sta $2006
    lda #$52
    sta $2007
    lda #$53
    sta $2007

    ; 10100:橋左右 - p0 - 31
    lda #$20
    sta $2006
    lda #$1c
    sta $2006
    lda #$54
    sta $2007
    lda #$55
    sta $2007
    lda #$20
    sta $2006
    lda #$3c
    sta $2006
    lda #$56
    sta $2007
    lda #$57
    sta $2007

    ; 10101:橋上下 - p0 - 41
    lda #$20
    sta $2006
    lda #$1e
    sta $2006
    lda #$58
    sta $2007
    lda #$59
    sta $2007
    lda #$20
    sta $2006
    lda #$3e
    sta $2006
    lda #$5a
    sta $2007
    lda #$5b
    sta $2007

    ; 10111:ピラミッド - p1 - 38
    lda #$20
    sta $2006
    lda #$40
    sta $2006
    lda #$5c
    sta $2007
    lda #$5d
    sta $2007
    lda #$20
    sta $2006
    lda #$60
    sta $2006
    lda #$5e
    sta $2007
    lda #$5f
    sta $2007

    ; 海 ----
    ; >上 - 13
    lda #$20
    sta $2006
    lda #$42
    sta $2006
    lda #$60
    sta $2007
    lda #$61
    sta $2007
    lda #$20
    sta $2006
    lda #$62
    sta $2006
    lda #$62
    sta $2007
    lda #$63
    sta $2007

    ; >右 - 7
    lda #$20
    sta $2006
    lda #$44
    sta $2006
    lda #$64
    sta $2007
    lda #$65
    sta $2007
    lda #$20
    sta $2006
    lda #$64
    sta $2006
    lda #$66
    sta $2007
    lda #$67
    sta $2007

    ; >上右 - 15
    lda #$20
    sta $2006
    lda #$46
    sta $2006
    lda #$68
    sta $2007
    lda #$69
    sta $2007
    lda #$20
    sta $2006
    lda #$66
    sta $2006
    lda #$6a
    sta $2007
    lda #$6b
    sta $2007

    ; >下 - 1
    lda #$20
    sta $2006
    lda #$48
    sta $2006
    lda #$6c
    sta $2007
    lda #$6d
    sta $2007
    lda #$20
    sta $2006
    lda #$68
    sta $2006
    lda #$6e
    sta $2007
    lda #$6f
    sta $2007

    ; >上下 24
    lda #$20
    sta $2006
    lda #$4a
    sta $2006
    lda #$70
    sta $2007
    lda #$71
    sta $2007
    lda #$20
    sta $2006
    lda #$6a
    sta $2006
    lda #$72
    sta $2007
    lda #$73
    sta $2007

    ; >右下 - 2
    lda #$20
    sta $2006
    lda #$4c
    sta $2006
    lda #$74
    sta $2007
    lda #$75
    sta $2007
    lda #$20
    sta $2006
    lda #$6c
    sta $2006
    lda #$76
    sta $2007
    lda #$77
    sta $2007

    ; >上右下 - 22
    lda #$20
    sta $2006
    lda #$4e
    sta $2006
    lda #$78
    sta $2007
    lda #$79
    sta $2007
    lda #$20
    sta $2006
    lda #$6e
    sta $2006
    lda #$7a
    sta $2007
    lda #$7b
    sta $2007

    ; >左 - 6
    lda #$20
    sta $2006
    lda #$50
    sta $2006
    lda #$7c
    sta $2007
    lda #$7d
    sta $2007
    lda #$20
    sta $2006
    lda #$70
    sta $2006
    lda #$7e
    sta $2007
    lda #$7f
    sta $2007

    ; >左上 - 12
    lda #$20
    sta $2006
    lda #$52
    sta $2006
    lda #$80
    sta $2007
    lda #$81
    sta $2007
    lda #$20
    sta $2006
    lda #$72
    sta $2006
    lda #$82
    sta $2007
    lda #$83
    sta $2007

    ; >左右 - 21
    lda #$20
    sta $2006
    lda #$54
    sta $2006
    lda #$84
    sta $2007
    lda #$85
    sta $2007
    lda #$20
    sta $2006
    lda #$74
    sta $2006
    lda #$86
    sta $2007
    lda #$87
    sta $2007

    ; >左上右 - 19
    lda #$20
    sta $2006
    lda #$56
    sta $2006
    lda #$88
    sta $2007
    lda #$89
    sta $2007
    lda #$20
    sta $2006
    lda #$76
    sta $2006
    lda #$8a
    sta $2007
    lda #$8b
    sta $2007

    ; >左下 - 4
    lda #$20
    sta $2006
    lda #$58
    sta $2006
    lda #$8c
    sta $2007
    lda #$8d
    sta $2007
    lda #$20
    sta $2006
    lda #$78
    sta $2006
    lda #$8e
    sta $2007
    lda #$8f
    sta $2007

    ; >下左上 - 14
    lda #$20
    sta $2006
    lda #$5a
    sta $2006
    lda #$90
    sta $2007
    lda #$91
    sta $2007
    lda #$20
    sta $2006
    lda #$7a
    sta $2006
    lda #$92
    sta $2007
    lda #$93
    sta $2007

    ; >左下右 - 39
    lda #$20
    sta $2006
    lda #$5c
    sta $2006
    lda #$94
    sta $2007
    lda #$95
    sta $2007
    lda #$20
    sta $2006
    lda #$7c
    sta $2006
    lda #$96
    sta $2007
    lda #$97
    sta $2007

    ; 全て - 42
    lda #$20
    sta $2006
    lda #$5e
    sta $2006
    lda #$98
    sta $2007
    lda #$99
    sta $2007
    lda #$20
    sta $2006
    lda #$7e
    sta $2006
    lda #$9a
    sta $2007
    lda #$9b
    sta $2007


    ; 01000:城上部左上 - p2 - 26
    lda #$20
    sta $2006
    lda #$80
    sta $2006
    lda #$23
    sta $2007
    lda #$24
    sta $2007
    lda #$20
    sta $2006
    lda #$a0
    sta $2006
    lda #$25
    sta $2007
    lda #$26
    sta $2007

    ; 01001:城上部右上 - p2 - 27
    lda #$20
    sta $2006
    lda #$82
    sta $2006
    lda #$27
    sta $2007
    lda #$28
    sta $2007
    lda #$20
    sta $2006
    lda #$a2
    sta $2006
    lda #$29
    sta $2007
    lda #$2a
    sta $2007

    ; 01010:城上部左下 - p2 - 28
    lda #$20
    sta $2006
    lda #$c0
    sta $2006
    lda #$2b
    sta $2007
    lda #$2c
    sta $2007
    lda #$20
    sta $2006
    lda #$e0
    sta $2006
    lda #$2d
    sta $2007
    lda #$2e
    sta $2007

    ; 01011:城上部右下 - p2 - 29
    lda #$20
    sta $2006
    lda #$c2
    sta $2006
    lda #$30
    sta $2007
    lda #$31
    sta $2007
    lda #$20
    sta $2006
    lda #$e2
    sta $2006
    lda #$32
    sta $2007
    lda #$33
    sta $2007


    ; 10000:塔上 - p1 - 32
    lda #$20
    sta $2006
    lda #$84
    sta $2006
    lda #$44
    sta $2007
    lda #$45
    sta $2007
    lda #$20
    sta $2006
    lda #$a4
    sta $2006
    lda #$46
    sta $2007
    lda #$47
    sta $2007

    ; 10001:塔下 - p1 - 33
    lda #$20
    sta $2006
    lda #$c4
    sta $2006
    lda #$48
    sta $2007
    lda #$49
    sta $2007
    lda #$20
    sta $2006
    lda #$e4
    sta $2006
    lda #$4a
    sta $2007
    lda #$4b
    sta $2007

    ; 001:氷(北半球) - p1 - 36, 5
    lda #$20
    sta $2006
    lda #$86
    sta $2006
    lda #$9c
    sta $2007
    lda #$9d
    sta $2007
    lda #$20
    sta $2006
    lda #$a6
    sta $2006
    lda #$9e
    sta $2007
    lda #$9f
    sta $2007

    ; パレット指定
    lda #$23
    sta $2006
    lda #$c0
    sta $2006
    lda #%00010100 ; ピラミット, 砂漠,海
    sta $2007

    lda #%00001111 ; 茂み,草原
    sta $2007

    lda #%00000111 ; 山,木
    sta $2007

    lda #%00001110 ; 毒沼,岩山
    sta $2007

    lda #%00001010 ; 街右,街左
    sta $2007

    lda #%00001001 ; 祠,村
    sta $2007

    lda #%00000010 ; 岩礁,洞窟
    sta $2007

    lda #%00000000 ; 橋上下, 橋左右
    sta $2007
    
    lda #%10101010 ; 城
    sta $2007

    lda #%00010001 ; 氷, 塔
    sta $2007



;---

;11000::ブランク(火口) - 40

    rts

.endproc


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
.include "data/mapdata.asm"

; 変数定義
.org $0000 ; ゼロページ領域
z_frame: .byte $00 ; VBlank毎にカウントアップ
z_chip: .byte $00
z_count: .byte $00

.org $0050
z_debug: .byte $00

; スタック領域は$0100~$01ff

.segment "VECINFO"
    .word vblank_loop ; VBlank割り込み時に実行するルーチン
    .word reset ; リセット割り込み
    .word irq ; ハードウェア割り込みとソフトウェア割り込み

; パターンテーブル
.segment "CHARS"
    .incbin "dq3.chr"
    .incbin "empty.chr"
    
