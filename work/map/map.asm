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
    ; x:$da, y:$96 サマンオサ付近
    lda #$07
    sta z_debug4
    sta z_chip_load_x
    lda #$1d
    sta z_chip_load_y


    lda #$20
    sta z_debug1
    lda #$00
    sta z_debug2
    lda #$20
    sta z_debug3
    jsr load_debug_line
; 2行目--
    lda z_debug4
    sta z_chip_load_x
    inc z_chip_load_y

    lda #$20
    sta z_debug1
    lda #$40
    sta z_debug2
    lda #$60
    sta z_debug3
    jsr load_debug_line

; 3行目--
    lda z_debug4
    sta z_chip_load_x
    inc z_chip_load_y

    lda #$20
    sta z_debug1
    lda #$80
    sta z_debug2
    lda #$a0
    sta z_debug3
    jsr load_debug_line

; 4行目--
    lda z_debug4
    sta z_chip_load_x
    inc z_chip_load_y

    lda #$20
    sta z_debug1
    lda #$c0
    sta z_debug2
    lda #$e0
    sta z_debug3
    jsr load_debug_line


; 5行目--
    lda z_debug4
    sta z_chip_load_x
    inc z_chip_load_y

    lda #$21
    sta z_debug1
    lda #$00
    sta z_debug2
    lda #$20
    sta z_debug3
    jsr load_debug_line


; 6行目--
    lda z_debug4
    sta z_chip_load_x
    inc z_chip_load_y

    lda #$21
    sta z_debug1
    lda #$40
    sta z_debug2
    lda #$60
    sta z_debug3
    jsr load_debug_line

; 7行目--
    lda z_debug4
    sta z_chip_load_x
    inc z_chip_load_y

    lda #$21
    sta z_debug1
    lda #$80
    sta z_debug2
    lda #$a0
    sta z_debug3
    jsr load_debug_line

; 8行目--
    lda z_debug4
    sta z_chip_load_x
    inc z_chip_load_y

    lda #$21
    sta z_debug1
    lda #$c0
    sta z_debug2
    lda #$e0
    sta z_debug3
    jsr load_debug_line

; 9行目--
    lda z_debug4
    sta z_chip_load_x
    inc z_chip_load_y

    lda #$22
    sta z_debug1
    lda #$00
    sta z_debug2
    lda #$20
    sta z_debug3
    jsr load_debug_line

; 10行目--
    lda z_debug4
    sta z_chip_load_x
    inc z_chip_load_y

    lda #$22
    sta z_debug1
    lda #$40
    sta z_debug2
    lda #$60
    sta z_debug3
    jsr load_debug_line

; 11行目--
    lda z_debug4
    sta z_chip_load_x
    inc z_chip_load_y

    lda #$22
    sta z_debug1
    lda #$80
    sta z_debug2
    lda #$a0
    sta z_debug3
    jsr load_debug_line

; 12行目--
    lda z_debug4
    sta z_chip_load_x
    inc z_chip_load_y

    lda #$22
    sta z_debug1
    lda #$c0
    sta z_debug2
    lda #$e0
    sta z_debug3
    jsr load_debug_line

; 13行目--
    lda z_debug4
    sta z_chip_load_x
    inc z_chip_load_y

    lda #$23
    sta z_debug1
    lda #$00
    sta z_debug2
    lda #$20
    sta z_debug3
    jsr load_debug_line

; 14行目--
    lda z_debug4
    sta z_chip_load_x
    inc z_chip_load_y

    lda #$23
    sta z_debug1
    lda #$40
    sta z_debug2
    lda #$60
    sta z_debug3
    jsr load_debug_line

; 15行目--
    lda z_debug4
    sta z_chip_load_x
    inc z_chip_load_y

    lda #$23
    sta z_debug1
    lda #$80
    sta z_debug2
    lda #$a0
    sta z_debug3
    jsr load_debug_line

    rts
.endproc


; 指定座標から1行分の情報をメモリw_mapにロード
.proc load_horizontal
    lda #$10
    sta z_load_counter
    ldy #$00

loop:
    jsr load_chip

    ; メモリに転送
    lda z_chip_chr1
    sta w_map, y
    iny

    lda z_chip_chr2
    sta w_map, y
    iny

    lda z_chip_chr3
    sta w_map, y
    iny

    lda z_chip_chr4
    sta w_map, y
    iny

    ; x座標を進める
    inc z_chip_load_x
    dec z_load_counter
    lda z_load_counter
    bne loop

    ; 終端マーカー
    lda #$00
    sta w_map, y

    ; この後パレット情報の指定が必要になる
    ; どう実装すればよいか要検討
    ; 妙案浮かばず

    rts
.endproc

; 指定座標から1列分の情報をメモリw_mapにロード
.proc load_vertical
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

    inc z_chip_load_x
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


; マップ情報読み込み
.include "load_chip.asm"

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
; チップ読み込み関連
z_chip_load_x: .byte $00 ; 読み込むチップの座標x
z_chip_load_y: .byte $00 ; 読み込むチップの座標y
z_chip_load_chip: .byte $00 ; 読み込みチップの圧縮情報
z_chip_adr_low: .byte $00 ; 間接アドレッシング用low
z_chip_adr_high: .byte $00 ; 間接アドレッシング用high
z_chip_latitude: .byte $00 ; 砂漠、氷判定用緯度 0:北半球, 1:南半球
z_chip_counter: .byte $00 ; チップロードサブルーチンで使用するカウンター


z_load_counter: .byte $00

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
    
