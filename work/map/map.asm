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
    jsr load_map

    ; 描画位置の右端座標
    lda #$20
    sta z_current_left_high
    lda #$00
    sta z_current_left_low

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
    ; 処理済のフレームかチェック
    lda z_frame_processed
    bne infinity_loop ; 1なら処理済

    jsr main_loop
    jmp infinity_loop

.endproc

; ---------------------------------------------------------------------------
; VBlank外での処理
.proc main_loop

    rts
.endproc




; ---------------------------------------------------------------------------
; 初期マップの表示
.proc load_map
    ;描画の開始座標設定
    lda #$20
    sta $2006
    lda #$00
    sta $2006

    ; 読み込み開始y設定
    lda #$00
    sta z_arg2

vetrical:
    ; 読み込み開始x設定
    lda #$00
    sta z_arg1
    jsr load_horizontal
    ; メモリに展開した内容描画

    ldx #$00
    ldy #$40
loop:
    lda w_map, x
    sta $2007
    inx
    dey
    bne loop

    ; y座標を1進める
    inc z_arg2
    lda z_arg2
    cmp #$0f
    bcc vetrical

    rts
.endproc



; ---------------------------------------------------------------------------
; 指定座標から横16の情報を読み取り、w_mapに設定
; arg1: x座標, arg2:y座標
.proc load_horizontal
    ; 2列同時に書き込む
    lda #$00
    sta z_counter1
    lda #$20
    sta z_counter2

    lda #$10
    sta z_counter3
load:
    ; 対象座標のデータ取得
    jsr get_chip
    lda z_return
    beq floor; 0なら床
    ; 1なら壁
    ; 1列目
    ldx z_counter1
    lda #$04
    sta w_map, x
    inx

    lda #$05
    sta w_map, x
    inx
    stx z_counter1

    ; 2列目
    ldx z_counter2
    lda #$06
    sta w_map, x
    inx

    lda #$07
    sta w_map, x
    inx
    stx z_counter2
    jmp end

floor:
    ; 0なら床 データは全て$01
    ; 1列目
    lda #$01
    ldx z_counter1
    sta w_map, x
    inx

    sta w_map, x
    inx
    stx z_counter1

    ; 2列目
    ldx z_counter2
    sta w_map, x
    inx

    sta w_map, x
    inx
    stx z_counter2
    jmp end

end:
    ; x座標を1進める
    inc z_arg1
    ; @todo 右端をオーバーしたら0リセット
    dec z_counter3
    lda z_counter3
    bne load
    
    rts
.endproc


; ---------------------------------------------------------------------------
; 指定座標から縦15の情報を読み取り、w_mapに設定
; arg1: x座標, arg2:y座標
.proc load_vetrical

    rts
.endproc

; ---------------------------------------------------------------------------
; 指定座標の情報を読み取り、z_returnに設定
; arg1: x座標, arg2:y座標
.proc get_chip
    ; y座標を読み込み
    ldy #$06
    lda #$00
mul: ;y * 6 = yを6回足せば良い
    clc
    adc z_arg2
    dey
    bne mul
    ; 読み出し開始位置y
    sta z_tmp1

    ; 読み出しx座標取得
    lda z_arg1
    and #%00000111
    sta z_tmp2 ; 下位ビットが初期ビットシフト数
    lda z_arg1
    and #%11111000 ; 上位ビットがmapのインデックス
    lsr ; 3つビットシフト
    lsr
    lsr
    ; 退避しておいたy開始にxを加算
    clc
    adc z_tmp1
    sta z_tmp1 ; 最終的なマップの開始indexを退避
    
    ; 対象のマップ情報があるデータをロード
    ldy z_tmp1
    lda map, y

    ; ビットシフト実行
    ldx #$00
seek:
    cpx z_tmp2
    beq found ; 該当ビット発見
    inx
    asl
    jmp seek

    inc z_debug

found:
    asl
    bcc floor ; 0の場合は床

    ; 1の場合は壁
    lda #$01
    jmp end

floor:
    lda #$00

end:
    ; 指定座標のマップIDを戻り値として設定
    sta z_return

    rts
.endproc



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

    inc z_frame
    
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
    .byte %10000000, %00000001, %10000000, %00000001, %10000000, %00000001
    .byte %00000000, %00000000, %10000000, %00000001, %10000000, %00000001
    .byte %00000000, %00000000, %00000000, %00000000, %10000000, %00000001
    .byte %00000001, %11000000, %00000111, %11000000, %00000111, %11110000
    .byte %00000000, %10000000, %00000010, %10000000, %00000010, %10100000
    .byte %00000000, %10000000, %00000010, %10000000, %00000010, %10100000
    .byte %00000000, %10000000, %00000010, %10000000, %00000010, %10100000
    .byte %00000000, %10000000, %00000010, %10000000, %00000010, %10100000
    .byte %00000000, %10000000, %00000010, %10000000, %00000010, %10100000
    .byte %00000000, %10000000, %00000010, %10000000, %00000010, %10100000
    .byte %00000000, %10000000, %00000010, %10000000, %00000010, %10100000
    .byte %00000001, %11000000, %00000111, %11000000, %00000111, %11110000
    .byte %00000000, %00000000, %00000000, %00000000, %10000000, %00000001
    .byte %00000000, %00000000, %10000000, %00000001, %10000000, %00000001
    .byte %10000000, %00000001, %10000000, %00000001, %10000000, %00000001

    .byte %10000000, %00000001, %10000000, %00000001, %10000000, %00000001
    .byte %00000000, %00000001, %10000000, %00000001, %10000000, %00000001
    .byte %00000000, %00000000, %00000000, %00000000, %10000000, %00000001
    .byte %00011111, %11111000, %00001111, %11110000, %00011111, %11111000
    .byte %00001010, %00010000, %00000100, %00100000, %00001000, %01010000
    .byte %00001010, %00010000, %00000100, %00100000, %00001000, %01010000
    .byte %00001001, %00100000, %00000100, %00100000, %00000100, %10010000
    .byte %00001001, %00100000, %00000010, %01000000, %00000100, %10010000
    .byte %00001001, %00100000, %00000010, %01000000, %00000100, %10010000
    .byte %00001000, %11000000, %00000001, %10000000, %00000011, %00010000
    .byte %00001000, %11000000, %00000001, %10000000, %00000011, %00010000
    .byte %00011111, %11111000, %00000001, %10000000, %00011111, %11111000
    .byte %10000000, %00000001, %00000000, %00000000, %10000000, %00000001
    .byte %10000000, %00000001, %10000000, %00000001, %10000000, %00000001
    .byte %11110000, %00000111, %10000000, %00000001, %10000000, %00000001

; 参照のアドレスを指定できるかテスト
maprow:
    .word map

; 変数定義
.org $0000 ; ゼロページ領域
z_arg1: .byte $00 ; サブルーチン汎用引数1
z_arg2: .byte $00 ; サブルーチン汎用引数2
z_return: .byte $00 ; サブルーチン戻り値
z_tmp1: .byte $00 ; 計算時のテンポラリ1
z_tmp2: .byte $00 ; 計算時のテンポラリ2
z_counter1: .byte $00 ; 計算時のカウンター1
z_counter2: .byte $00 ; 計算時のカウンター2
z_counter3: .byte $00 ; 計算時のカウンター3

.org $0010
z_frame: .byte $00 ; VBlank毎にカウントアップ
z_frame_processed: .byte $00 ; 描画準備ができているか0:未処理、1:準備済
z_frame_operation: .byte $00 ; VBlank中にやってほしいこと bit0:スクロール bit1:描画
z_controller_1: .byte $00 ; コントローラー1入力


; ----- 



z_chip: .byte $00   ; 処理中のマップ情報
z_index: .byte $00  ; ループカウンタ値保存用
z_name_index: .byte $00 ; 対象ネームテーブルの番号0/1
z_map_low: .byte $00 ; 読み込みマップのアドレス
z_map_high: .byte $00 
; -- 09 --
z_x: .byte $00 ; スクロールx
z_y: .byte $00 ; スクロールy
z_world_x: .byte $00 ; 絶対座標x
z_world_y: .byte $00 ; 絶対座標y
z_2000: .byte $00 ; スクロール用
z_name_high: .byte $00
z_name_low: .byte $00
; -- 10 --
z_current_left_high: .byte $00 ; 現在左側の座標情報(high)
z_current_left_low: .byte $00 ; 現在左側の座標情報(low)
z_load_x: .byte $00 ; ロードするマップのx座標
z_load_y: .byte $00 ; ロードするマップのy座標
z_map_index: .byte $00 ; マップ読み込み時の退避領域
z_map_index2: .byte $00 ; マップ読み込み時の退避領域
z_auto_move: .byte $00 ; 自動移動中かの判定

; スタック領域は$0100~$01ff

.org $0050
z_debug: .byte $00

.org $0200 ; ワークエリア
w_map: .byte $00
; $07000以降はスプライトDMAで予約

.segment "VECINFO"
    .word vblank_loop ; VBlank割り込み時に実行するルーチン
    .word reset ; リセット割り込み
    .word irq ; ハードウェア割り込みとソフトウェア割り込み

; パターンテーブル
.segment "CHARS"
    .incbin "downlad.chr"
