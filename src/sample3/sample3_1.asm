; 背景(ネームテーブル)
; 左上に4つ上下に並べて0x01の図形を描画
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

; ネームテーブルへ転送(画面の左上1行目)
    lda #$20
    sta $2006
    lda #$20
    sta $2006
    ldx #$00
    ldy #$02        ; 2回ループ
copymap:
    lda #$01        ; 0x01番地のデータを出力
    sta $2007
    inx
    dey
    bne copymap

; ネームテーブルへ転送(画面の左上2行目)
    lda #$20
    sta $2006
    lda #$40
    sta $2006
    ldx #$00
    ldy #$02        ; 2回ループ
copymap2:
    lda #$01        ; 0x01番地のデータを出力
    sta $2007
    inx
    dey
    bne copymap2

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
    .byte    $0f, $0f, $0f, $0f
    .byte    $0f, $0f, $0f, $0f
    .byte    $0f, $0f, $0f, $0f


.segment "VECINFO"
	.word	$0000
	.word	Reset
	.word	$0000

; パターンテーブル
.segment "CHARS"
	.incbin	"character.chr"