;----------------------------------------------------------------------------
;				NES Sample1 "HELLO, WORLD!"
;					Copyright (C) 2007, Tekepen
;----------------------------------------------------------------------------
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
	lda	#$00
	sta	$2006
	ldx	#$00
	ldy	#$10
copypal:
	lda	palettes, x
	sta	$2007
	inx
	dey
	bne	copypal

; ネームテーブルへ転送(画面の中央付近)
;	lda	#$21
	lda	#$20 ; 左上に移動してみる
	sta	$2006
;	lda	#$c9
	lda	#$20
	sta	$2006
	ldx	#$00
;	ldy	#$0d		; 13文字表示
	ldy	#$0a		; 10文字表示
copymap:
	lda	string, x
	sta	$2007
	inx
	dey
	bne	copymap

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
    .byte    $0f, $08, $0f, $28
    .byte    $0f, $0f, $0f, $0f
    .byte    $0f, $0f, $0f, $0f
    .byte    $0f, $0f, $0f, $0f

; 表示文字列
string:
;	.byte	"HELLO, WORLD!"
;	.byte	"HELLO, SYMFO!"
	.byte	$89, $ad, $95, $90 ;こんにち
	.byte	$99, $00, $8d, $85 ;は＿せか
	.byte	$81, $21 ;い！

.segment "VECINFO"
	.word	$0000
	.word	Reset
	.word	$0000

; パターンテーブル
.segment "CHARS"
	.incbin	"character.chr"