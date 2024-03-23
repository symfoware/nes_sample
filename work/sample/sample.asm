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
    jsr drawchip


; スプライトの初期化
    ldx #$00
    ldy #$40 ; スプライトは64個 一旦全てを隠す

spritehide:
    lda #$ff
    sta $0700, x ; Y座標ff
    inx
    sta $0700, x ; タイルのインデックスff
    inx
    ; スプライト属性指定
    ; bit7:垂直反転(１で反転)
    ; bit6:水平反転(１で反転)
    ; bit5:BGとの優先順位(0:手前、1:奥)
    ; bit4-2 未使用?
    ; bit0-1:パレットの上位2bit
    lda #%00100000
    sta $0700, x ; スプライト属性 BGの後ろを指定
    inx
    lda #$ff
    sta $0700, x ; X座標ff
    inx
    dey
    bne spritehide


; スプライト情報表示
    ; $0x0700から0x07ffを使用しDMA転送
    ; 変更するスプライトの番号(1スプライトで4byte消費するので、4の倍ごとに指定となる)    
    ;１バイト目 Ｙ座標 
    lda #$d0
    sta $0700 ; Y座標をレジスタにストアする
    
    ;２バイト目 タイルインデクス番号 （$1000から保存している何番目のスプライトを表示するか）
    lda #$00
    sta $0701 ; 0をストアして0番のスプライトを指定する
    
    ;３バイト目　8ビットのビットフラグです。スプライトの属性を指定します。
    lda #$00
    sta $0702 ; 反転や優先順位は操作しないので、再度$00をストアする
    
    ;４バイト目　Ｘ座標 
    lda #$10
    sta $0703 ; X座標をレジスタにストアする


; -----
    lda #$d0
    sta $0704 ; Y座標をレジスタにストアする
    
    ;２バイト目 タイルインデクス番号 （$1000から保存している何番目のスプライトを表示するか）
    lda #$01
    sta $0705 ; 0をストアして0番のスプライトを指定する
    
    ;３バイト目　8ビットのビットフラグです。スプライトの属性を指定します。
    lda #$00
    sta $0706 ; 反転や優先順位は操作しないので、再度$00をストアする
    
    ;４バイト目　Ｘ座標 
    lda #$18
    sta $0707 ; X座標をレジスタにストアする

; -----
    lda #$d8
    sta $0708 ; Y座標をレジスタにストアする
    
    ;２バイト目 タイルインデクス番号 （$1000から保存している何番目のスプライトを表示するか）
    lda #$02
    sta $0709 ; 0をストアして0番のスプライトを指定する
    
    ;３バイト目　8ビットのビットフラグです。スプライトの属性を指定します。
    lda #$10
    sta $070a ; 反転や優先順位は操作しないので、再度$00をストアする
    
    ;４バイト目　Ｘ座標 
    lda #$10
    sta $070b ; X座標をレジスタにストアする

; -----
    lda #$d8
    sta $070c ; Y座標をレジスタにストアする
    
    ;２バイト目 タイルインデクス番号 （$1000から保存している何番目のスプライトを表示するか）
    lda #$03
    sta $070d ; 0をストアして0番のスプライトを指定する
    
    ;３バイト目　8ビットのビットフラグです。スプライトの属性を指定します。
    lda #$00
    sta $070e ; 反転や優先順位は操作しないので、再度$00をストアする
    
    ;４バイト目　Ｘ座標 
    lda #$18
    sta $070f ; X座標をレジスタにストアする



; BGのスクリーン表示位置設定左上にぴったり(スクロール設定)
    lda #$00
    sta $2005
    sta $2005

; スクリーンオン
    lda #%10001000 ; NMI実行あり,BGのキャラクタテーブル番号を1に
    sta $2000
    lda #%00011110 ; スプライト表示,BG表示,左端8x8のスプライト表示,左端8x8のBG表示
    sta $2001

; 初期表示
    lda #$01
    sta z_frame_processed

; ---------------------------------------------------------------------------------
; 無限ループ
infinityLoop:
    ; どうせ処理中に割り込まれるのでチェックは不要
    ;lda $2002 ; VBlankが発生すると、$2002の7ビット目(N)が1になります。
    ;bmi infinityLoop ; bit7(N)が1の間は、VBlank中なので処理をキャンセル

    ; ゴール判定
    lda #$00
    cmp z_goal
    bne infinityLoop ; ゴールしていたら処理終了


    ; 処理済のフレームかチェック
    lda #$01
    bit z_frame_processed
    bne infinityLoop ; 1なら処理済

    lda #$01
    sta z_auto_move ; 自動移動中かの判定

    ; きりの良いところまで移動するまで待機
    ; ストライプ左上の座標で判断
    lda $0700 ; y座標
    ; 0-3bitが0ならキリがよい
    and #%00001111
    bne spritemove

    lda $0703 ; x座標
    ; 0-3bitで0ならキリがよい
    and #%00001111
    bne spritemove

    lda #$00
    sta z_auto_move ; 自動移動中かの判定

    ; ゴールしているかチェック
    jsr is_goal


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

spritemove:
;UPKEYdown
    lda #%00001000
    and z_controller_1
    beq keycheck1 ; 結果が0なら押されてない判定
    ; 上に行けるかチェック
    jsr check_move_up
    bcs keycheckend

    ; 押されたら減算
    dec $0700
    dec $0704
    dec $0708
    dec $070c
    jmp keycheckend

keycheck1:
;DOWNKEYdown:
    lda #%00000100
    and z_controller_1
    beq keycheck2 ; 結果が0なら押されてない判定
    ; 下に行けるかチェック
    jsr check_move_down
    bcs keycheckend

    inc $0700 ; Y座標を1加算
    inc $0704
    inc $0708
    inc $070c
    jmp keycheckend

keycheck2:
;LEFTKEYdown:
    lda #%00000010
    and z_controller_1
    beq keycheck3
    jsr check_move_left
    bcs keycheckend

    dec $0703    ; X座標を1減算
    dec $0707
    dec $070b
    dec $070f
    jmp keycheckend
    
keycheck3:
;RIGHTKEYdown:
    lda #%00000001
    and z_controller_1
    beq keycheckend
    jsr check_move_right
    bcs keycheckend

    inc $0703    ; X座標を1加算
    inc $0707
    inc $070b
    inc $070f

keycheckend:

    ; 処理済と設定
    lda #$01
    sta z_frame_processed

    jmp infinityLoop


; 上に行けるか判定
check_move_up:
    clc
    lda z_auto_move
    bne check_end

    ; 現在のxy座標を設定
    jsr get_xy

    ; mapデータから移動後のオブジェクトを取得
    ; 対象データがあるのは、x%2 + y*2
    ; y*2はyを左シフトして得る
    ; x%2はand 01をすればすればよい
    lda z_y
    ; 一つ上に移動
    sec ; sbcする前に設定必須
    sbc #$01
    sta z_y ; 移動後の座標を設定

    jsr check_move
    rts


; 下に行けるか判定
check_move_down:
    clc
    lda z_auto_move
    bne check_end

    ; 現在のxy座標を設定
    jsr get_xy

    lda z_y
    ; 一つ下に移動
    clc ; adcする前に設定必須
    adc #$01
    sta z_y ; 移動後の座標を設定

    jsr check_move
    rts


; 左に行けるか判定
check_move_left:
    clc
    lda z_auto_move
    bne check_end

    ; 現在のxy座標を設定
    jsr get_xy

    ; mapデータから移動後のオブジェクトを取得
    ; 対象データがあるのは、x%2 + y*2
    ; y*2はyを左シフトして得る
    ; x%2はand 01をすればすればよい
    lda z_x
    ; 一つ左に移動
    sec ; sbcする前に設定必須
    sbc #$01
    sta z_x ; 移動後の座標を設定

    jsr check_move
    rts

; 右に行けるか判定
check_move_right:
    clc
    lda z_auto_move
    bne check_end

    ; 現在のxy座標を設定
    jsr get_xy

    lda z_x
    ; 一つ下に移動
    clc ; adcする前に設定必須
    adc #$01
    sta z_x ; 移動後の座標を設定

    jsr check_move
    rts

check_move:

    ; 移動後のY座標
    lda z_y
    sta z_tmp

    ; 対象データがあるマップ情報を取得
    lda z_x
    lsr
    lsr
    lsr
    lsr
    rol z_tmp
    
    ; x座標のデータを取得
    lda z_x
    and #%00000111 ; 8bit毎に2行目に行くのでマスク
    tay
    iny

    ; マップ情報を取得
    ldx z_tmp
    lda map, x
    

loop:
    asl
    dey
    bne loop

check_end:
    rts



get_xy:
    ; y
    lda $0700
    ; 上位4bit
    lsr
    lsr
    lsr
    lsr
    sta z_y ; y座標

    ; x
    lda $0703
    lsr
    lsr
    lsr
    lsr
    sta z_x ; x座標
    rts


; ゴールしたかチェック
is_goal:
    jsr get_xy
    ldx z_x
    cpx #$0e
    ;cpx #$01
    beq check_y
    rts

check_y:
    ldx z_y
    cpx #$01
    ;cpx #$0c
    beq set_goal
    rts

set_goal:
    lda #$01
    sta z_goal
    sta z_frame_processed
    ; ゴール部分を書き込み
    lda $2002
    lda #$21
    sta $2006
    lda #$8c
    sta $2006

    ldx #$10
    ldy #$08
goal_upper:
    txa
    sta $2007
    inx
    dey
    bne goal_upper

    ; ゴール下段
    lda $2002
    lda #$21
    sta $2006
    lda #$ac
    sta $2006

    ldx #$20
    ldy #$08
goal_lower:
    txa
    sta $2007
    inx
    dey
    bne goal_lower

    lda #$00
    sta $2005
    sta $2005

    rts


.endproc


; ---------------------------------------------------------------------------
; ソースを別ファイルに記載し.includeで取り込める
;.include "drawchip.asm"
.proc drawchip
    ; 書き込み開始座標指定
    lda #$20
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
    lda map, x
    sta z_chip
    ; z_chipを情報を解析して書き込み
    jsr drawChipUp
    inx

    ; マップ情報を読み込みメモリーに退避(16-y行目右側)
    lda map, x
    sta z_chip
    ; z_chipを情報を解析して書き込み
    jsr drawChipUp
    dex ; 一つ前に戻す
    
    ; マップ情報を読み込みメモリーに退避
    lda map, x ; (16-y行目左側)
    sta z_chip
    jsr drawChipLow
    inx
    
    lda map, x ; (16-y行目右側)
    sta z_chip
    jsr drawChipLow

    ; yの値が書き換わっているのでメモリーから復帰
    ldy z_index
    inx
    dey
    bne maploop

    ; ゴール部分を書き込み
    lda #$20
    sta $2006
    lda #$5c
    sta $2006
    lda #$08
    sta $2007
    lda #$09
    sta $2007

    lda #$20
    sta $2006
    lda #$7c
    sta $2006
    lda #$0a
    sta $2007
    lda #$0b
    sta $2007
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

    lda #$07 ; スプライトデータは$0700-$07ff番地にしたので、先頭の上位ビット07を設定
    sta $4014 ; スプライトDMAレジスタにAをストアして、スプライトデータをDMA転送する

    ; 描画済にフラグを更新
    lda #$00
    sta z_frame_processed


bvlank_end:

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
    .byte %11111111, %11111111
    .byte %10000000, %00000001
    .byte %10111111, %11111111
    .byte %10000000, %00000001
    .byte %11111111, %11111101
    .byte %10000000, %00000101
    .byte %10111111, %11110101
    .byte %10100000, %00010101
    .byte %10101111, %11110101
    .byte %10100000, %00000101
    .byte %10111111, %11111101
    .byte %10000000, %00000001
    .byte %10111111, %11111111
    .byte %10000000, %00000001
    .byte %11111111, %11111111

;.incbin "map.dat"

; 変数定義
.org $0000 ; ゼロページ
z_frame: .byte $00 ; VBlank毎にカウントアップ
z_frame_processed: .byte $00 ; 処理済フレーム
z_controller_1: .byte $00 ; コントローラー1入力
z_chip: .byte $00   ; 処理中のマップ情報
z_index: .byte $00  ; ループカウンタ値保存用
z_x: .byte $00
z_y: .byte $00
z_auto_move: .byte $00
z_goal: .byte $00
z_tmp: .byte $00
z_debug: .byte $00
; スタック領域は$0100~$01ff


.segment "VECINFO"
    .word mainloop ; VBlank割り込み時に実行するルーチン
    .word reset ; リセット割り込み
    .word irq ; ハードウェア割り込みとソフトウェア割り込み

; パターンテーブル
.segment "CHARS"
    .incbin "downlad.chr"
