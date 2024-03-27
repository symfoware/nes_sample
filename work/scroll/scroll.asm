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
    ; mapをネームテーブル0へ
    lda #$00
    sta z_name_index
    lda #<map
    sta z_map_low
    lda #>map
    sta z_map_high
    jsr drawchip

; BGのスクリーン表示位置設定左上にぴったり(スクロール設定)
    lda #$00
    sta z_x
    sta $2005
    sta $2005

; スクリーンオン
    lda #%11001000 ; NMI実行あり,BGのキャラクタテーブル番号を1に
    sta $2000
    lda #%00001110 ; スプライト表示,BG表示,左端8x8のスプライト表示,左端8x8のBG表示
    sta $2001

; 初期表示
    lda #$01
    sta z_frame_processed

; ---------------------------------------------------------------------------------
; 無限ループ
infinityLoop:

    ; 処理済のフレームかチェック
    lda #$01
    bit z_frame_processed
    bne infinityLoop ; 1なら処理済

    lda #$01
    sta z_auto_move ; 自動移動中かの判定

    ; きりの良いところまで移動するまで待機
    ; ストライプ左上の座標で判断
    lda z_x ; x座標
    ; 0-3bitが0ならキリがよい
    and #%00001111
    bne bgmove

    lda z_y ; x座標
    ; 0-3bitで0ならキリがよい
    and #%00001111
    bne bgmove

    lda #$00
    sta z_auto_move ; 自動移動中かの判定


    ;lda $0703 ; x座標
    ; コントローラー1入力取得
    ; パッドI/Oレジスタの初期化($4016に1,0の順で書き込むのが作法)
    lda #$01
    sta $4016
    lda #$00 
    sta $4016

    ; Aボタンから右ボタンまで取得
    ldx #$08
keycheck_loop:
    ; コントローラー1 パッド入力チェック(2コンは$4017)
    lda $4016
    lsr ; 論理右シフト Aの0bit目がCに設定される
    rol z_controller_1 ; Cの値を0bit目に詰めつつ左ローテート
    dex
    bne keycheck_loop ; 8個読み取るまでループ
    
    cmp z_controller_1
    beq infinityLoop ; なにも押されていないならばループに戻る
    
    ; 以降変更なし
    ; bit:キー
    ; 7:A
    ; 6:B
    ; 5:SELECT
    ; 4:START
    ; 3:UP
    ; 2:DOWN
    ; 1:LEFT
    ; 0:RIGHT

bgmove:
;UPKEYdown
    lda #%00001000
    and z_controller_1
    beq keycheck1 ; 結果が0なら押されてない判定
    ; 縦スクロールは後ほど
    jmp keycheckend

keycheck1:
;DOWNKEYdown:
    lda #%00000100
    and z_controller_1
    beq keycheck2 ; 結果が0なら押されてない判定
    ; 縦スクロールは後ほど
    jmp keycheckend

keycheck2:
;LEFTKEYdown:
    lda #%00000010
    and z_controller_1
    beq keycheck3

    ; x座標を1引く
    lda z_x
    sec
    sbc #$01
    sta z_x
    bcs keycheckend ; ボローが発生しなければそのまま処理

    lda #$ff
    sta z_x
    ; ボローしたらname_table切り替え
    lda z_name_index
    eor #$01
    sta z_name_index
    jmp keycheckend
    
keycheck3:
;RIGHTKEYdown:
    lda #%00000001
    and z_controller_1
    beq keycheckend

    lda z_auto_move
    bne keycheck31 ; きりのよいところからの移動でなければ
    ; きりのよい座標から右に移動する場合はworldアドレスを加算
    inc z_world_x
    ; メモリーに次に表示する内容を展開
    jsr loadRight

keycheck31:
    ; x座標を1足す
    lda z_x
    clc
    adc #$01
    sta z_x
    bcc keycheckend ; キャリーしていなければそのまま処理
    
    ; キャリーしたらname_table切り替え
    lda z_name_index
    eor #$01
    sta z_name_index
    jmp keycheckend

keycheckend:

    ; スクロール位置リセット
    lda $2002
    lda z_x
    sta $2005
    lda z_y
    sta $2005

	; 表示するネームテーブル番号(bit1~0)をセットする
    ; 末尾がネームテーブル 0:$2000,1:$2400
    lda #%11001000
    ora z_name_index
    sta $2000
    sta w_2000

    ; 処理済と設定
    lda #$01
    sta z_frame_processed

    jmp infinityLoop

.endproc


; ---------------------------------------------------------------------------
.proc loadRight
    lda z_world_x
    lda #$01
    sta z_draw
    rts
.endproc


; ---------------------------------------------------------------------------
; ソースを別ファイルに記載し.includeで取り込める
;.include "drawchip.asm"
.proc drawchip
    ; 書き込み開始座標指定
    lda z_name_index
    bne name1
    ; ネームテーブル0描画
    lda #$20
    jmp drawstart

name1:
    lda #$24

drawstart:
    sta $2006
    lda #$00
    sta $2006

    ; ループカウンタ
    ldx #$00
    ldy #$0f
maploop:
    ; サブルーチンでyを書き換えるので、現在のy値をメモリーに退避
    sty z_index

    ; マップ情報を読み込みメモリーに退避(16-y行目左側)
    txa
    tay
    lda (z_map_low), y
    sta z_chip
    ; z_chipを情報を解析して書き込み
    jsr drawChipUp
    inx

    ; マップ情報を読み込みメモリーに退避(16-y行目右側)
    txa
    tay
    lda (z_map_low), y
    sta z_chip
    ; z_chipを情報を解析して書き込み
    jsr drawChipUp
    dex ; 一つ前に戻す
    
    ; マップ情報を読み込みメモリーに退避
    txa
    tay
    lda (z_map_low), y ; (16-y行目左側)
    sta z_chip
    jsr drawChipLow
    inx
    
    txa
    tay
    lda (z_map_low), y ; (16-y行目右側)
    sta z_chip
    jsr drawChipLow
    inx
    
    ; インデックスを飛ばす
    inx
    inx
    inx
    inx

    ; yの値が書き換わっているのでメモリーから復帰
    ldy z_index
    dey
    bne maploop

    rts


; map情報から画面表示(16x16の上半分)
drawChipUp:
    ; 1bit単位で0なら通路、1なら壁)
    ldy #$08
loopup:
    ; map情報の断片をロード
    lda z_chip
    ; bit演算した結果を出力BGデータでで 0は床、1は壁のパネルを設定している
    and #%10000000
    beq floorup ; 0なら床
    jmp wallup

floorup:
    lda #$00
    sta $2007
    lda #$01
    sta $2007
    jmp finup

wallup:
    lda #$04
    sta $2007
    lda #$05
    sta $2007
    
finup:
    ; 左ローテート
    rol z_chip
    dey
    bne loopup
    ;jmp draw8chipr ; ルーチンが近い場合はjmpしてみるテスト
    rts



; map情報から画面表示(16x16の下半分)
drawChipLow:
    ; 1bit単位で0なら通路、1なら壁)
    ldy #$08
looplow:
    ; map情報の断片をロード
    lda z_chip
    ; bit演算した結果を出力BGデータでで 0は床、1は壁のパネルを設定している
    and #%10000000
    beq floorlow ; 0なら床
    jmp walllow

floorlow:
    lda #$02
    sta $2007
    lda #$03
    sta $2007
    jmp finlow

walllow:
    lda #$06
    sta $2007
    lda #$07
    sta $2007
    
finlow:
    ; 左ローテート
    rol z_chip
    dey
    bne looplow
    ;jmp draw8chipr ; ルーチンが近い場合はjmpしてみるテスト
    rts
.endproc


; ---------------------------------------------------------------------------
.proc mainloop
    ; NMIによる割り込み処理に変更したのでチェック不要
    ;lda $2002 ; VBlankが発生すると、$2002の7ビット目が1になります。
    ;bpl mainloop ; bit7が0の間は、mainLoopラベルの位置に飛んでループして待ち続けます。

    ; VBlank中に値を書き換えると、呼び出し元の処理が壊れるので一旦退避
    ; これで様子見
    pha ; Aをスタックに
    txa ; X -> A
    pha ; A(=X)をスタックに
    tya ; Y -> A
    pha ; A(=Y)をスタックに
    php ; ステータスをスタックに

    inc z_frame ; タイマーカウントアップ
    lda #$01
    bit z_frame_processed
    beq bvlank_end ; 1でなければ処理するものがない

    lda z_draw ; 描画内容がなければ狩猟
    beq bvlank_end



    lda #%11001100 ; bit2 1でインクリメント32
    sta $2000
    lda #$24
    sta $2006
    lda #$00
    sta $2006
    
    ldy #$0f
draw:
    lda #$04
    sta $2007
    lda #$06
    sta $2007
    dey
    bne draw

    lda #$24
    sta $2006
    lda #$01
    sta $2006
    
    ldy #$0f
draw2:
    lda #$05
    sta $2007
    lda #$07
    sta $2007
    dey
    bne draw2
    
    ;lda #$04
    ;sta $2007
    ;lda #$06
    ;sta $2007

    lda #$00
    sta z_draw



    ;lda #$07 ; スプライトデータは$0700-$07ff番地にしたので、先頭の上位ビット07を設定
    ;sta $4014 ; スプライトDMAレジスタにAをストアして、スプライトデータをDMA転送する




bvlank_end:
    ; 描画済にフラグを更新
    lda #$00
    sta z_frame_processed



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

; パレットテーブル
palettes:
    ; BG
    .byte $0f, $05, $00, $10
    .byte $0f, $16, $16, $26
    .byte $0f, $00, $18, $28
    .byte $0f, $0a, $10, $2a
    ; スプライト
    .byte $0f, $00, $10, $39
    .byte $0f, $16, $16, $26
    .byte $0f, $00, $18, $28
    .byte $0f, $0a, $10, $2a

; マップ情報
map:
    .byte %00000000, %00000000, %00000000, %00000000, %00000000, %00000000
    .byte %00000000, %00000000, %00000000, %00000000, %00000000, %00000000
    .byte %00000000, %00000000, %00000000, %00000000, %00000000, %00000000
    .byte %00000001, %11000000, %00000111, %11000000, %00000111, %11110000
    .byte %00000000, %10000000, %00000010, %10000000, %00000010, %10100000
    .byte %00000000, %10000000, %00000010, %10000000, %00000010, %10100000
    .byte %00000000, %10000000, %00000010, %10000000, %00000010, %10100000
    .byte %00000000, %10000000, %00000010, %10000000, %00000010, %10100000
    .byte %00000000, %10000000, %00000010, %10000000, %00000010, %10100000
    .byte %00000000, %10000000, %00000010, %10000000, %00000010, %10100000
    .byte %00000000, %10000000, %00000010, %10000000, %00000010, %10100000
    .byte %00000001, %11000000, %00000111, %11000000, %00000111, %11110000
    .byte %00000000, %00000000, %00000000, %00000000, %00000000, %00000000
    .byte %00000000, %00000000, %00000000, %00000000, %00000000, %00000000
    .byte %00000000, %00000000, %00000000, %00000000, %00000000, %00000000

; 参照のアドレスを指定できるかテスト
maprow:
    .byte >map, <map

; 変数定義
.org $0000 ; ゼロページ
z_frame: .byte $00 ; VBlank毎にカウントアップ
z_frame_processed: .byte $00 ; 処理済フレーム
z_controller_1: .byte $00 ; コントローラー1入力
z_chip: .byte $00   ; 処理中のマップ情報
z_index: .byte $00  ; ループカウンタ値保存用
z_name_index: .byte $00 ; 対象ネームテーブルの番号0/1
z_map_low: .byte $00 ; 読み込みマップのアドレス
z_map_high: .byte $00 
z_x: .byte $00
z_y: .byte $00
z_world_x: .byte $00
z_auto_move: .byte $00
z_draw: .byte $00
z_tmp: .byte $00
z_debug: .byte $00
; スタック領域は$0100~$01ff

.org $0200 ; ワークエリア
w_2000: .byte $00

; $07000以降はスプライトDMAで予約

.segment "VECINFO"
    .word mainloop ; VBlank割り込み時に実行するルーチン
    .word reset ; リセット割り込み
    .word irq ; ハードウェア割り込みとソフトウェア割り込み

; パターンテーブル
.segment "CHARS"
    .incbin "downlad.chr"
