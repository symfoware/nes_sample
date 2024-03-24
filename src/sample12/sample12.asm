; 横スクロールサンプル
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
.proc	reset
	sei			; 割り込み不許可
	cld			; デシマルモードフラグクリア
	ldx #$ff
	txs			; スタックポインタ初期化 

	; PPUコントロールレジスタ1初期化
	lda #%00110000	; ここではVBlank割り込み禁止
	sta $2000

waitVSync:
	lda $2002		; VBlankが発生すると、$2002の7ビット目が1になる
	bpl waitVSync	; bit7が0の間は、waitVSyncラベルの位置に飛んでループして待ち続ける

	; PPUコントロールレジスタ2初期化
	lda #%00000110	; 初期化中はスプライトとBGを表示OFFにする
	sta $2001

	; ゼロページ初期化
	lda #$00
	ldx #$00
initZeroPage:
	sta $00, x
	inx
	bne initZeroPage

	; パレットをロード
	ldx #$00    ; Xレジスタクリア
	; VRAMアドレスレジスタの$2006に、パレットのロード先のアドレス$3F00を指定する。
	lda #$3f
	sta $2006
	lda #$00
	sta $2006
loadPal:			; ラベルは、「ラベル名＋:」の形式で記述
	lda s_palettes, x ; Aに(ourpal + x)番地のパレットをロードする
	sta $2007 ; $2007にパレットの値を読み込む
	inx ; Xレジスタに値を1加算している
	cpx #32 ; Xを32(10進数。BGとスプライトのパレットの総数)と比較して同じかどうか比較している	
	bne loadPal ;	上が等しくない場合は、loadpalラベルの位置にジャンプする
	; Xが32ならパレットロード終了

	; 属性(BGのパレット指定データ)をロード
	lda #$00
	sta NameTblNum
	
	; $23C0,27C0の属性テーブルにロードする
	; 属性テーブル0
	lda #$23
	sta $2006
	lda #$c0
	sta $2006
	ldx #$00
loadAttr0:
	lda #%00000000
	sta $2007
	inx
	cpx #32
	bne loadAttr0

	; 属性テーブル1
	lda #$27
	sta $2006
	lda #$c0
	sta $2006
	ldx #$00
loadAttr1:
	lda #%00000000
	sta $2007
	inx
	cpx #32
	bne loadAttr1

	; デフォルトの空と床を描画する
	; ネームテーブル0ロード
	lda #$20
	sta $2006
	lda #$00
	sta $2006
	; カウントが$ffを超えるので1回のループで回せない
	; 112 * 8と分けてループする
	ldx #112		; Xレジスタ初期化
	ldy #8			; Yレジスタ初期化
	lda #$00 ; 空
loadName0upper:
	sta $2007
	dex
	bne loadName0upper
	ldx #112
	dey
	bne loadName0upper

	ldx #64	 ; Xレジスタ初期化
	lda #$01 ; 床
loadName0lower:
	sta $2007
	dex
	bne loadName0lower

	; ネームテーブル1ロード
	; ネームテーブル0のロードと同じ処理内容
	lda #$24
	sta $2006
	lda #$00
	sta $2006
	ldx #112		; Xレジスタ初期化
	ldy #8			; Yレジスタ初期化
	lda #$00 ; 空
loadName1upper:
	sta $2007
	dex
	bne loadName1upper
	ldx #112
	dey
	bne loadName1upper

	ldx #64		; Xレジスタ初期化
	lda #$01 ; 床
loadName1lower:
	sta $2007
	dex
	bne loadName1lower

	
	; PPUコントロールレジスタ2初期化
	lda #%00011110	; スプライトとBGの表示をONにする
	sta $2001

	; PPUコントロールレジスタ1の割り込み許可フラグを立てる
	lda #%10110101				; スプライトは8x16、ネームテーブルは$2400を指定、PPUアドレスインクリメントを+32にする
	sta $2000

; VBlank割り込み発生を待つだけの無限ループ
infinityLoop:
    jmp infinityLoop
.endproc

; --------------------------------------------------------------------
.proc mainloop
	
	inc Floor_Wait ; 床更新タイミングをカウントアップ
	inc Scroll_X ; スクロール位置を2つ進める
	inc Scroll_X

	; 床描画判定(4周に1度、画面外に床を描画する)
	lda Floor_Wait
	cmp #4
	bne setBGScroll		; 床カウンタが4でないならまだ床を描画しない
	lda #0
	sta Floor_Wait		; 床カウンタクリア

	; Courseテーブル読み込み
	lda Floor_Cnt
	bne writeFloor		; 指定の床数を描画していない場合はスキップ

	; 指定の床数の描画が終わっていたら、次のデータを取得
	ldx Course_Index
	lda Course_Tbl, x	; Courseテーブルで指定された床Y座標読み込み
	sta Floor_Y			; 床Y座標格納
	inx 				; インデックス加算
	lda Course_Tbl, x	; Courseテーブルで指定された床数読み込み
	sta Floor_Cnt		; 床カウンタ格納
	inx
	stx Course_Index	; 次に使用するコースインデックス保存
	txa
	cmp #20				; コーステーブルは20個
	bne writeFloor
	lda #0				; インデックスの最大値20を超えたらインデックスを0に戻す
	sta Course_Index

	; 現在のネームテーブルに床を描画する
writeFloor:
	lda $2002			; PPUレジスタクリア
	dec Floor_Cnt		; 床カウンタ減算
	lda #$20			; ネームテーブルの上位アドレス($2000から)
	ldx NameTblNum
	cpx #1				; ネームテーブル選択番号が1なら$2400から
	bne writeFloorE
	lda #$24			; ネームテーブルの上位アドレス($2400から)
writeFloorE:
	sta $2006			; ネームテーブル上位アドレスをセット
	lda Floor_X		; 床X座標をロード(そのまま下位アドレスになる)
	sta $2006
	ldx #28				; 縦28回分ループする(地面が2キャラあるので30-2)
writeFloorSub:
	lda #$00			; 0番(透明)
	cpx Floor_Y
	bne writeFloorSub2	; 床のY座標と違うならwriteFloorSub2へ
	lda #$02			; 2番(レンガ)
writeFloorSub2:
	sta $2007
	dex
	bne writeFloorSub	; 28回ループする

	inc Floor_X		; 床X座標加算
	lda Floor_X
	cmp #32				; ネームテーブルのライン右端に到達した？
	bne setBGScroll
	lda #0				; 0に戻す
	sta Floor_X
	; ネームテーブル選択番号を切り替える
	lda NameTblNum
	eor #1				; ビット反転
	sta NameTblNum


setBGScroll:
	; BGスクロール(このタイミングで実行する)
	lda $2002			; スクロール値クリア
	lda Scroll_X		; Xのスクロール値をロード
	sta $2005			; X方向スクロール
	lda #0
	sta $2005			; Y方向スクロール（Y方向は固定)

	; 表示するネームテーブル番号(bit1~0)をセットする
	; PPUアドレスインクリメントは+32にする
	lda #%10110101				; ネームテーブル$2400を指定
	ldx NameTblNum
	bne setNameTblNum
	lda #%10110100				; ネームテーブル$2000を指定
setNameTblNum:
	sta $2000

	rti				; 割り込みから復帰

.endproc
; --------------------------------------------------------------------

.proc irq
	rti
.endproc

; 背景データ(10x2個・Y座標・継続カウンタ)
; 床を表示するY座標と、床を何枚表示するかのペアで指定
Course_Tbl:
	.byte $03, $04 ; Y座標3で、床を4枚連続
	.byte $05, $0a
	.byte $08, $0a
	.byte $03, $0a
	.byte $06, $05
	.byte $09, $0a
	.byte $0c, $0f
	.byte $07, $08
	.byte $0a, $0a
	.byte $05, $06

; パレットテーブル
s_palettes:
	.incbin "giko5.pal"

; ゼロページ
.org $0000
Scroll_X: .byte $00		; Xスクロール値
Floor_X: .byte $00	; 描画する縦ラインのX座標
Floor_Y: .byte $00	; 描画する床のY座標
Floor_Wait: .byte $00	; 床更新待ちカウンター
Course_Index: .byte $00 	; コーステーブルインデックス
Floor_Cnt: .byte $00 	; 床描画枚数
NameTblNum: .byte $00 ; ネームテーブル選択番号(0=$2000,1=$2400)

.segment "VECINFO"
	.word	mainloop
	.word	reset
	.word	irq

; パターンテーブル
.segment "CHARS"
	.incbin "giko3.spr"
	.incbin "giko5.bkg"
