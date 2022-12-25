; パレット
; 属性テーブルのアドレスへの書き込み
; サブルーチン化
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

;属性テーブルへ転送
    lda #$23 ;$23c8への書きこみ開始を通知
    sta $2006
    lda #$c8
    sta $2006
    
    ldx #$00
    lda #%11100100 ;左下3,右下2,左上1,右下0の色番号を適応
    sta    $2007 ;go!

; ネームテーブルへ転送(画面の左上)
    lda    #$20
    sta    $2006
    lda    #$80
    sta    $2006
    
    ldx    #$00
    ldy    #$04        ; 4文字表示
    jsr copymap
;ネームテーブルへ転送(画面の左上2行目)
    lda    #$20
    sta    $2006
    lda    #$a0
    sta    $2006
    
    ldx    #$00
    ldy    #$04        ; 4文字表示
    jsr copymap
    
;ネームテーブルへ転送(画面の左上3行目)
    lda    #$20
    sta    $2006
    lda    #$c0
    sta    $2006
    
    ldx    #$00
    ldy    #$04        ; 4文字表示
    jsr copymap
    
;ネームテーブルへ転送(画面の左上4行目)
    lda    #$20
    sta    $2006
    lda    #$e0
    sta    $2006
    
    ldx    #$00
    ldy    #$04        ; 4文字表示
    jsr copymap

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

; 指定数分データ出力
copymap:
    lda #$01
    sta    $2007
    inx
    dey
    bne    copymap
    rts

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