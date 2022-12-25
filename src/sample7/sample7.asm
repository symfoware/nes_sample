; VBlank割り込み
.setcpu        "6502"
.autoimport    on
; iNESヘッダ
.segment "HEADER"
    .byte    $4E, $45, $53, $1A    ; "NES" Header
    .byte    $02            ; PRG-BANKS
    .byte    $01            ; CHR-BANKS
    .byte    $01            ; Vetrical Mirror
    .byte    $00            ; 
    .byte    $00, $00, $00, $00    ; 
    .byte    $00, $00, $00, $00    ; 

; ゼロページ変数
; $0000,$0001という記載でもOKみたい
Pos_X = $00    ;X座標
Pos_Y = $01    ;Y座標

.segment "STARTUP"
; リセット割り込み
.proc    Reset
    sei            ; 割り込み不許可
    ldx    #$ff
    txs            ; スタックポインタ初期化(Xレジスタ→Sレジスタ) 
; スクリーンオフ
    lda    #$00
    sta    $2000
waitVSync:
    lda $2002            ; VBlankが発生すると、$2002の7ビット目が1になる
    bpl waitVSync ; bit7が0の間は、waitVSyncラベルの位置に飛んでループして待ち続ける
    
    lda    #$00
    sta    $2001
; パレットテーブルへ転送(パレット用のみ転送)
    lda    #$3f
    sta    $2006
    lda    #$10
    sta    $2006
    ldx    #$00
    ldy    #$10
    
copypal:
    lda    palettes, x
    sta    $2007
    inx
    dey
    bne    copypal
    
    ; スプライトDMA領域初期化(0と1以外は全て奥にし、画面に表示されないように)
    lda #%00100000
    ldx #$00
initSpriteDMA:
    sta $0700, x
    inx
    bne initSpriteDMA

    ;スプライトの初期表示位置を設定
    lda #100
    sta Pos_X ;X座標を$0000に保存
    sta Pos_Y ;Y座標を$0001に保存
    
    
    ;解像度　256x240
    ; スプライト描画
    
    ;スプライト１
    ;Ｙ座標 
    lda Pos_Y ; Y座標($0001)をロード
    sta $0700 ; Y座標をレジスタにストアする
    
    ;２バイト目 タイルインデクス番号
    lda #$0
    sta $0701
    
    ;３バイト目　8ビットのビットフラグです。スプライトの属性を指定します。
    sta $0702
    
    ;４バイト目　Ｘ座標 
    lda Pos_X    ; X座標($0000)をロード
    sta $0703 ; X座標をレジスタにストアする
    ;スプライト２
    ;Ｙ座標 
    lda Pos_Y ; Y座標($0001)をロード
    sta $0704 ; Y座標をレジスタにストアする
    
    ;２バイト目 タイルインデクス番号
    lda #$01
    sta $0705
    
    ;３バイト目　8ビットのビットフラグです。スプライトの属性を指定します。
    lda #$0
    sta $0706
    
    ;４バイト目　Ｘ座標 
    lda Pos_X    ; X座標($0000)をロード
    adc #8        ; 8ドット移動
    sta $0707 ; X座標をレジスタにストアする
    
    
    ;スプライト３
    ;Ｙ座標 
    lda Pos_Y ; Y座標($0001)をロード
    adc #8        ; 8ドット移動
    sta $0708 ; Y座標をレジスタにストアする
    
    ;２バイト目 タイルインデクス番号
    lda #$02
    sta $0709
    
    ;３バイト目　8ビットのビットフラグです。スプライトの属性を指定します。
    lda #$0
    sta $070a
    
    ;４バイト目　Ｘ座標 
    lda Pos_X    ; X座標($0000)をロード
    sta $070b ; X座標をレジスタにストアする
    ;スプライト４
    ;Ｙ座標 
    lda Pos_Y ; Y座標($0001)をロード
    adc #8        ; 8ドット移動
    sta $070c ; Y座標をレジスタにストアする
    
    ;２バイト目 タイルインデクス番号
    lda #$03
    sta $070d
    
    ;３バイト目　8ビットのビットフラグです。スプライトの属性を指定します。
    lda #$0
    sta $070e
    
    ;４バイト目　Ｘ座標 
    lda Pos_X    ; X座標($0000)をロード
    adc #8        ; 8ドット移動
    sta $070f ; X座標をレジスタにストアする

; スクロール設定
    lda    #$00
    sta    $2005
    sta    $2005

; スクリーンオン
    lda    #%10001000    ;※※※最初のビットを1にして、VBlank時にNMIを実行する※※※
    sta    $2000 ;PPUコントロールレジスタ１
    lda    #%00011110
    sta    $2001 ;PPUコントロールレジスタ２

infinityLoop:                    ; VBlank割り込み発生を待つだけの無限ループ
    jmp infinityLoop
.endproc
; 無限ループ
.proc mainloop
    
    ;ここでコントローラーからの入力を監視
    ;lda $2002 ; VBlankが発生すると、$2002の7ビット目が1になります。
    ;bpl mainloop ; bit7が0の間は、mainLoopラベルの位置に飛んでループして待ち続けます。
    ; スプライト描画
    lda #$7 ; スプライトデータは$0700番地にしたので、7を設定
    sta $4014 ; スプライトDMAレジスタにAをストアして、スプライトデータをDMA転送する
        
    ; パッドI/Oレジスタの準備
    lda #$01
    sta $4016
    lda #$00 
    sta $4016
    ; パッド入力チェック
    lda $4016 ; Aボタンをスキップ
    lda $4016 ; Bボタンをスキップ
    lda $4016 ; Selectボタンをスキップ
    lda $4016 ; Startボタンをスキップ
    lda $4016 ; 上ボタン
    and #1     ; AND #1
    bne UPKEYdown ; 0でないならば押されてるのでUPKeydownへジャンプ
    
    lda $4016 ; 下ボタン
    and #1     ; AND #1
    bne DOWNKEYdown ; 0でないならば押されてるのでDOWNKeydownへジャンプ
    lda $4016 ; 左ボタン
    and #1     ; AND #1
    bne LEFTKEYdown ; 0でないならば押されてるのでLEFTKeydownへジャンプ
    lda $4016 ; 右ボタン
    and #1     ; AND #1
    bne RIGHTKEYdown ; 0でないならば押されてるのでRIGHTKeydownへジャンプ
    jmp NOTHINGdown ; なにも押されていないならばNOTHINGdownへ
UPKEYdown:
    dec Pos_Y    ; Y座標を1減算。
    jmp NOTHINGdown
DOWNKEYdown:
    inc Pos_Y ; Y座標を1加算
    jmp NOTHINGdown
LEFTKEYdown:
    dec Pos_X    ; X座標を1減算
    jmp NOTHINGdown 
RIGHTKEYdown:
    inc Pos_X    ; X座標を1加算
    ; この後NOTHINGdownなのでジャンプする必要無し
NOTHINGdown:
    ;ここで各スプライト座標の再計算
    
    lda Pos_X ;X座標取り出し
    ;各スプライトのX座標変更
    sta $0703 ; スプライト1 - X座標
    sta $070b ; スプライト3 - X座標
    adc #8        ; 8ドット移動
    sta $0707 ; スプライト2 - X座標
    sta $070f ; スプライト4 - X座標
    
    lda Pos_Y ;Y座標取り出し
    ;各スプライトのY座標変更
    sta $0700 ; スプライト1 - Y座標
    sta $0704 ; スプライト2 - Y座標
    adc #8        ; 8ドット移動
    sta $0708 ; スプライト3 - Y座標
    sta $070c ; スプライト4 - Y座標
    ;jmp    mainloop ; mainLoopの最初に戻る
    rti    ; ※※※割り込みから復帰※※※
.endproc
; パレットテーブル
palettes:
    .byte    $0f, $17, $28, $39
    .byte    $01, $02, $03, $04
    .byte    $05, $06, $07, $08
    .byte    $09, $0a, $0b, $0c
    
.segment "VECINFO"
    .word    mainloop    ; ※※※VBlank割り込み※※※
    .word    Reset        ;リセット割り込み
    .word    $0000
; パターンテーブル
.segment "CHARS"
    .incbin    "character.chr"
