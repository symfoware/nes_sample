; スプライト
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
    sta    $2007 ;go!

; スプライト描画
;多分、スプライトの番号
    lda #$00 ; $00(スプライトRAMのアドレスは8ビット長)をAにロード
    sta $2003 ; AのスプライトRAMのアドレスをストア
    
;１バイト目 Ｙ座標 
    lda #50     ; 50(10進数)をAにロード
    sta $2004 ; Y座標をレジスタにストアする
    
;２バイト目 タイルインデクス番号 （sprファイルの何番目のスプライトを表示するか）
    lda #00     ; 0(10進数)をAにロード
    sta $2004 ; 0をストアして0番のスプライトを指定する
    
;３バイト目　8ビットのビットフラグです。スプライトの属性を指定します。
    lda #%00000000
    sta $2004 ; 反転や優先順位は操作しないので、再度$00をストアする
    
;４バイト目　Ｘ座標 
    lda #20        ;    20(10進数)をAにロード
    sta $2004 ; X座標をレジスタにストアする
    
;スプライト2個目
;１バイト目 Ｙ座標 
    lda #100
    sta $2004
;２バイト目 タイルインデクス番号 （sprファイルの何番目のスプライトを表示するか）
    lda #00
    sta $2004
;３バイト目　8ビットのビットフラグ
    lda #%10000001
    sta $2004
;４バイト目　Ｘ座標 
    lda #40
    sta $2004
    
;スプライト3個目
;１バイト目 Ｙ座標 
    lda #150
    sta $2004
;２バイト目 タイルインデクス番号 （sprファイルの何番目のスプライトを表示するか）
    lda #00
    sta $2004
;３バイト目　8ビットのビットフラグ
    lda #%00000010
    sta $2004
;４バイト目　Ｘ座標 
    lda #60
    sta $2004    
    
;スプライト4個目
;１バイト目 Ｙ座標 
    lda #200
    sta $2004
;２バイト目 タイルインデクス番号 （sprファイルの何番目のスプライトを表示するか）
    lda #00
    sta $2004
;３バイト目　8ビットのビットフラグ
    lda #%10000011
    sta $2004
;４バイト目　Ｘ座標 
    lda #80
    sta $2004

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
	jmp	mainloop
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