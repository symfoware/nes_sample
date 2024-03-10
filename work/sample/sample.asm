;----------------------------------------------------------------------------
;				NES Sample1 "HELLO, WORLD!"
;					Copyright (C) 2007, Tekepen
;----------------------------------------------------------------------------
.setcpu		"6502"
.autoimport	on

; iNESヘッダ "HEADER"はcfgのSEGMENTSで定義
.segment "HEADER"
	.byte	$4E, $45, $53, $1A	; "NES" Header
	.byte	$02			; PRG-BANKS
	.byte	$01			; CHR-BANKS
	.byte	$01			; Vetrical Mirror
	.byte	$00			; 
	.byte	$00, $00, $00, $00	; 
	.byte	$00, $00, $00, $00	; 

.segment "STARTUP" ;  "STARTUP"はcfgのSEGMENTSで定義
; リセット割り込み
.proc	Reset
	sei
	ldx	#$ff
	txs

; スクリーンオフ
	lda	#$00
	sta	$2000 ; 基本設定をクリア
	sta	$2001 ; マスク設定をクリア

; パレットテーブルへ転送(BG用のみ転送)
; VRAM BG用パレット $3F00～$3F0F へ転送を実施
	lda	#$3f ; VRAMアドレス上位1byte
	sta	$2006
	lda	#$00 ; VRAMアドレス下位1byte
	sta	$2006 ; $2006 へ2回 store を行うことでVRAMのアクセス先番地を設定
	ldx	#$00
	ldy	#$10
copypal:
	lda	palettes, x ; palettes + xの値をaへロード
	sta	$2007 ; VRAMへデータ書き込み事項
	inx ; xインクリメント
	dey ; yデクリメント
	bne	copypal ; yデクリメントの結果0にならなかったらcopypalに戻る


; ネームテーブルへ転送(画面の中央付近)
; VRAM ネームテーブル $2000～$23BF 画面0のBG配置パターン
	lda	#$21
	sta	$2006
	lda	#$c9
	sta	$2006
	ldx	#$00
	ldy	#$0d		; 13文字表示
copymap:
	lda	string, x
	sta	$2007
	inx
	dey
	bne	copymap

; BGのスクリーン表示位置設定左上にぴったり(スクロール設定)
	lda	#$00
	sta	$2005
	sta	$2005

; スクリーンオン
	lda	#$08 ; 00001000 BGのキャラクタテーブル番号を1に
	sta	$2000
	lda	#$1e ; 00011110 スプライト表示,BG表示,左端8x8のスプライト表示,左端8x8のBG表示
	sta	$2001

; 無限ループ
mainloop:
	jmp	mainloop
.endproc

; パレットテーブル
palettes:
	.byte	$0f, $00, $10, $20
	.byte	$0f, $06, $16, $26
	.byte	$0f, $08, $18, $28
	.byte	$0f, $0a, $1a, $2a

; 表示文字列
string:
	.byte	"HELLO, SYMFO!"

.segment "VECINFO"
	.word	$0000
	.word	Reset
	.word	$0000

; パターンテーブル
.segment "CHARS"
	.incbin	"character.chr"
;	.incbin	"yychr.chr"
	