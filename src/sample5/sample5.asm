; コントローラー入力でスプライトを動かす
.setcpu		"6502"
.autoimport	on

; iNESヘッダ
.segment "HEADER"
	.byte	$4E, $45, $53, $1A	; "NES" Header
	.byte	$02			; PRG-BANKS
	.byte	$01			; CHR-BANKS
	.byte	$01			; Vetrical Mirror
	.byte	$00			; 
	.byte	$00, $00, $00, $00	; 
	.byte	$00, $00, $00, $00	; 

.segment "STARTUP"
; リセット割り込み
.proc	Reset
	sei
	ldx	#$ff
	txs

; スクリーンオフ
	lda	#$00
	sta	$2000
	sta	$2001

; パレットテーブルへ転送(BG用のみ転送)
	lda	#$3f
	sta	$2006
;	lda	#$00
	lda	#$10 ; $1000のパレット領域のみ転送へ変更
	sta	$2006
	ldx	#$00
	ldy	#$10
copypal:
	lda	palettes, x
	sta	$2007
	inx
	dey
	bne	copypal

;属性テーブルへ転送
    lda #$23 ;$23c8への書きこみ開始を通知
    sta $2006
    lda #$c8
    sta $2006
    
    ldx #$00
    lda #%11100100 ;左下3,右下2,左上1,右下0の色番号を適応
    sta $2007

; スプライト初期値指定
    lda #100
    sta $0000 ;X座標を$0000に保存
    sta $0001 ;Y座標を$0001に保存


; スクロール設定
	lda	#$00
	sta	$2005
	sta	$2005

; スクリーンオン
	lda	#$08
	sta	$2000
	lda	#$1e
	sta	$2001

; 無限ループ
mainloop:
    ;ここでコントローラーからの入力を監視
    lda $2002 ; VBlankが発生すると、$2002の7ビット目が1になります。
    bpl mainloop ; bit7が0の間は、mainLoopラベルの位置に飛んでループして待ち続けます。
    ; スプライト描画
    lda #$00 ; $00(スプライトRAMのアドレスは8ビット長)をAにロード
    sta $2003 ; AのスプライトRAMのアドレスをストア
    lda $0001 ; Y座標の値をロード
    sta $2004     ; Y座標をレジスタにストアする
    lda #00     ; 0(10進数)をAにロード
    sta $2004 ; 0をストアして0番のスプライトを指定する
    sta $2004 ; 反転や優先順位は操作しないので、再度$00をストアする
    lda $0000 ; X座標の値をロード
    sta $2004     ; X座標をレジスタにストアする
    
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
    dec $0001    ; Y座標を1減算。ゼロページなので、以下のコードをこの１命令に短縮できる
;    lda $0001 ; Y座標をロード
;    sbc #1 ; #1減算する
;    sta $0001 ; Y座標をストア
    jmp NOTHINGdown

DOWNKEYdown:
    inc $0001 ; Y座標を1加算
    jmp NOTHINGdown

LEFTKEYdown:
    dec $0000    ; X座標を1減算
    jmp NOTHINGdown 

RIGHTKEYdown:
    inc $0000    ; X座標を1加算
    ; この後NOTHINGdownなのでジャンプする必要無し

NOTHINGdown:
    jmp    mainloop ; mainLoopの最初に戻る
.endproc

; パレットテーブル
palettes:
    .byte    $0f, $17, $28, $39
    .byte    $01, $02, $03, $04
    .byte    $05, $06, $07, $08
    .byte    $09, $0a, $0b, $0c


.segment "VECINFO"
	.word	$0000
	.word	Reset
	.word	$0000

; パターンテーブル
.segment "CHARS"
	.incbin	"character.chr"