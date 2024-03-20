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

; スプライト情報表示
    ; スプライト描画
    ; 変更するスプライトの番号(1スプライトで4byte消費するので、4の倍ごとに指定となる)
    lda #$00 ; $00(スプライトRAMのアドレスは8ビット長)をAにロード
    sta $2003 ; AのスプライトRAMのアドレスをストア
    
    ;１バイト目 Ｙ座標 
    lda #$df
    sta $2004 ; Y座標をレジスタにストアする
    sta z_sprite_y
    
    ;２バイト目 タイルインデクス番号 （$1000から保存している何番目のスプライトを表示するか）
    lda #$00
    sta $2004 ; 0をストアして0番のスプライトを指定する
    
    ;３バイト目　8ビットのビットフラグです。スプライトの属性を指定します。
    sta $2004 ; 反転や優先順位は操作しないので、再度$00をストアする
    
    ;４バイト目　Ｘ座標 
    lda #$08
    sta $2004 ; X座標をレジスタにストアする
    sta z_sprite_x

    ldy #$3f ; スプライトは64個 未使用のスプライト63個の座標を移動して隠す
spritehide:
    lda #$00
    sta $2004 ; Y座標0
    sta $2004 ; タイルのインデックス0
    ; スプライト属性指定
    ; bit7:垂直反転(１で反転)
    ; bit6:水平反転(１で反転)
    ; bit5:BGとの優先順位(0:手前、1:奥)
    ; bit4-2 未使用?
    ; bit0-1:パレットの上位2bit
    lda #%00100000
    sta $2004 ; スプライト属性 BGの後ろを指定
    lda #$00
    sta $2004 ; X座標0
    dey
    bne spritehide



; BGのスクリーン表示位置設定左上にぴったり(スクロール設定)
    lda #$00
    sta $2005
    sta $2005

; スクリーンオン
    lda #%10001000 ; NMI実行あり,BGのキャラクタテーブル番号を1に
    sta $2000
    lda #%00011110 ; スプライト表示,BG表示,左端8x8のスプライト表示,左端8x8のBG表示
    sta $2001

; 無限ループ
infinityLoop:
    lda $2002 ; VBlankが発生すると、$2002の7ビット目(N)が1になります。
    bmi infinityLoop ; bit7(N)が1の間は、VBlank中なので処理をキャンセル
    
    ; ここで入力キーを拾う
    

    jmp infinityLoop

.endproc

; 関数定義テスト
.proc drawchip
    ; 書き込み開始座標指定
    lda #$20
    sta $2006
    lda #$00
    sta $2006
    
    ; ループカウンタ
    ldx #$00
    ldy #$78
maploop:
    ; マップ情報を読み込みメモリーに退避
    lda map, x
    sta z_chip
    ; サブルーチンでyを書き換えるので、現在のy値をメモリーに退避
    sty z_index
    ; z_chipを情報を解析して書き込み
    jmp draw8chip
draw8chipr:
    ; yの値が書き換わっているのでメモリーから復帰
    ldy z_index
    inx
    dey
    bne maploop

    rts

; map情報から画面表示
draw8chip:
    ; 1bit単位で0なら通路、1なら壁)
    ldy #$08
loop:
    ; map情報の断片をロード
    lda z_chip
    ; bit演算した結果を出力BGデータでで 0は空白、1は塗りつぶしのパネルを設定している
    and #$01
    sta $2007
    ; 右にビットシフト
    lsr z_chip
    dey
    bne loop
    jmp draw8chipr ; ルーチンが近い場合はjmpしてみるテスト
.endproc

.proc mainloop
    ; ここでコントローラーからの入力を監視
    ;lda $2002 ; VBlankが発生すると、$2002の7ビット目が1になります。
    ;bpl mainloop ; bit7が0の間は、mainLoopラベルの位置に飛んでループして待ち続けます。
    ; タイマーカウントアップ
    inc <z_timer

    ; VBlank間の処理
    ; スプライト描画
    lda #$00 ; $00(スプライトRAMのアドレスは8ビット長)をAにロード
    sta $2003 ; AのスプライトRAMのアドレスをストア
    lda z_sprite_y ; Y座標の値をロード
    sta $2004     ; Y座標をレジスタにストアする
    lda #$00     ; 0(10進数)をAにロード
    sta $2004 ; 0をストアして0番のスプライトを指定する
    sta $2004 ; 反転や優先順位は操作しないので、再度$00をストアする
    lda z_sprite_x ; X座標の値をロード
    sta $2004     ; X座標をレジスタにストアする

    ; パッドI/Oレジスタの初期化($4016に1,0の順で書き込むのが作法)
    lda #$01
    sta $4016
    lda #$00 
    sta $4016

    ; コントローラー1 パッド入力チェック(2コンは$4017)
    lda $4016 ; Aボタンをスキップ
    lda $4016 ; Bボタンをスキップ
    lda $4016 ; Selectボタンをスキップ
    lda $4016 ; Startボタンをスキップ
    lda $4016 ; 上ボタン
    and #$01     ; AND #1
    bne UPKEYdown ; 0でないならば押されてるのでUPKeydownへジャンプ
    
    lda $4016 ; 下ボタン
    and #$01     ; AND #1
    bne DOWNKEYdown ; 0でないならば押されてるのでDOWNKeydownへジャンプ
    lda $4016 ; 左ボタン
    and #$01     ; AND #1
    bne LEFTKEYdown ; 0でないならば押されてるのでLEFTKeydownへジャンプ
    lda $4016 ; 右ボタン
    and #$01     ; AND #1
    bne RIGHTKEYdown ; 0でないならば押されてるのでRIGHTKeydownへジャンプ
    jmp NOTHINGdown ; なにも押されていないならばNOTHINGdownへ

UPKEYdown:
    dec z_sprite_y    ; Y座標を1減算。ゼロページなので、以下のコードをこの１命令に短縮できる
;    lda z_sprite_y ; Y座標をロード
;    sbc #$01 ; 1減算する
;    sta z_sprite_y ; Y座標をストア
    jmp NOTHINGdown

DOWNKEYdown:
    inc z_sprite_y ; Y座標を1加算
    jmp NOTHINGdown

LEFTKEYdown:
    dec z_sprite_x    ; X座標を1減算
    jmp NOTHINGdown 

RIGHTKEYdown:
    inc z_sprite_x    ; X座標を1加算
    ; この後NOTHINGdownなのでジャンプする必要無し

NOTHINGdown:
    rti ; VBlank割り込みから復帰 ここでは何も行わず、後の流れのrtiで処理しても良さそう
.endproc

; ハード、ソフトウェア割り込み
.proc irq
    rti
.endproc

; パレットテーブル
palettes:
    ; BG
    .byte $0f, $20, $1a, $12
    .byte $0f, $16, $16, $26
    .byte $0f, $00, $18, $28
    .byte $0f, $0a, $10, $2a
    ; スプライト
    .byte $0f, $16, $1a, $12
    .byte $0f, $16, $16, $26
    .byte $0f, $00, $18, $28
    .byte $0f, $0a, $10, $2a

; マップ情報
map:
    .byte %11111111, %11111111, %11111111, %11111111
    .byte %00000001, %00000000, %00000000, %10000000
    .byte %11110101, %11111111, %11111111, %11111111
    .byte %11110101, %11111111, %11111111, %11111111
    .byte %11110101, %11111111, %11111111, %11111111
    .byte %11110101, %11111111, %11111111, %11111111
    .byte %11110101, %11111111, %11111111, %11111111
    .byte %11110101, %11111111, %11111111, %11111111
    .byte %11111101, %11111111, %11111111, %11111111
    .byte %11000001, %11111111, %11111111, %11111111
    .byte %11111101, %11111111, %11111111, %11111111
    .byte %11111101, %11111111, %11111111, %11111111
    .byte %11111101, %11111111, %11111111, %11111111
    .byte %11111101, %11111111, %11111111, %11111111
    .byte %11111101, %11111111, %11111111, %11111111
    .byte %11111101, %11111111, %11111111, %11111111
    .byte %11111101, %11111111, %11111111, %11111111
    .byte %11111101, %11111111, %11111111, %11111111
    .byte %11111101, %11111111, %11111111, %11111111
    .byte %11111101, %11111111, %11111111, %11111111
    .byte %11111101, %11111111, %11111111, %11111111
    .byte %11111101, %11111111, %11111111, %11111111
    .byte %11111101, %11111111, %11111111, %11111111
    .byte %11111101, %11111111, %11111111, %11111111
    .byte %11111101, %11111111, %11111111, %11111111
    .byte %11111101, %11111111, %11111111, %11111111
    .byte %11111101, %11111111, %11111111, %11111111
    .byte %11111101, %11111111, %11111111, %11111111
    .byte %11111101, %11111111, %11111111, %11111111
    .byte %11111111, %11111111, %11111111, %01111111


; 変数定義
.org $0000 ; ゼロページ
z_timer: .byte $00 ; VBlank毎にカウントアップ
z_sprite_x: .byte $00 ; スプライトのx座標
z_sprite_y: .byte $00 ; スプライトのx座標
z_chip: .byte $00   ; 処理中のマップ情報
z_index: .byte $00  ; ループカウンタ値保存用
; スタック領域は$0100~$01ff

.segment "VECINFO"
    .word mainloop ; VBlank割り込み時に実行するルーチン
    .word reset ; リセット割り込み
    .word irq ; ハードウェア割り込みとソフトウェア割り込み

; パターンテーブル
.segment "CHARS"
    .incbin "downlad.chr"
