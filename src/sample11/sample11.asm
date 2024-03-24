; 縦スクロールサンプル
.setcpu		"6502"
.autoimport	on

; iNESヘッダ
.segment "HEADER"
	.byte	$4E, $45, $53, $1A	; "NES" Header
	.byte	$02			; PRG-BANKS
	.byte	$01			; CHR-BANKS
	.byte	$00			; Horizontal Mirror
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
	lda #%00001000	; ここではVBlank割り込み禁止
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
init_zero_page:
	sta $00, x
	inx
	bne init_zero_page

	; パレットをロード
	; VRAMアドレスレジスタの$2006に、パレットのロード先のアドレス$3F00を指定する。
	lda #$3f
	sta $2006
	lda #$00
	sta $2006

	ldx #$00    	; Xレジスタクリア
loadPal:			; ラベルは、「ラベル名＋:」の形式で記述
	lda palettes, x	; Aに(ourpal + x)番地のパレットをロードする
	sta $2007 ; $2007にパレットの値を読み込む
	inx ; Xレジスタに値を1加算している
	cpx #32 	; Xを32(10進数。BGとスプライトのパレットの総数)と比較して同じかどうか比較している	
	bne loadPal ;	上が等しくない場合は、loadpalラベルの位置にジャンプする
	; Xが32ならパレットロード終了

	; 属性テーブル(BGのパレット指定)ロード
	; 水平ミラーなので、$23c0-$23ffと$2bc0-$2bffを設定
	; $23c0-$23ff
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

	; $2bc0-$2bff
	lda #$2b
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

	;---------------------
	lda #$0b		; 道路の初期X座標=11
	sta Road_X

	; ネームテーブル0 $2000-$23BF描画
	lda #$20
	sta $2006
	lda #$00
	sta $2006
	ldy #30
writeName1:
	jsr writeCourse ; コース1行分描画
	dey
	bne writeName1

	; ネームテーブル2 $2800-$2BBF描画
	lda #$28
	sta $2006
	lda #$00
	sta $2006
	ldy #30
writeName2:
	jsr writeCourse ; コース1行分描画
	dey
	bne writeName2

	
	lda #$23	; 道路のY座標アドレス初期化($23C0)
	sta Road_YH
	lda #$C0
	sta Road_YL
	
	; PPUコントロールレジスタ2初期化
	lda #%00001110	; BGの表示をONにする
	sta $2001

	; PPUコントロールレジスタ1の割り込み許可フラグを立てる
	lda #%10001010
	sta $2000

; VBlank割り込み発生を待つだけの無限ループ
infinityLoop:
    jmp infinityLoop
.endproc

; --------------------------------------------------------------------
.proc mainloop

	; 道路描画判定(4周に1度、画面外に道路を描画する)
	inc Road_Cnt		; カウンタ増加
	lda Road_Cnt
	cmp #4
	bne scrollBG		; 4でないならまだ道路を描画しない
	
	; 描画更新
	lda #0
	sta Road_Cnt
	; 道路Y座標アドレス計算
	lda Road_YL
	sec					; sbcの前にキャリーフラグをセット
	sbc #32				; 道路のY座標アドレス(下位)に32減算
	sta Road_YL
	bcs setCourse		; 桁下がりしてなければsetCourseへ
	lda Road_YH
	cmp #$20			; Y座標アドレス(上位)が$20まで下がったか？
	bne calcCourseSub

	; ネームテーブル選択番号を更新
	lda NameTblNum
	eor #1
	sta NameTblNum

	lda #$23			; 道路のY座標アドレス初期化($23C0)
	sta Road_YH
	lda #$C0
	sta Road_YL
	lda #03				; 次回更新するために、カウンタは4-1=3
	sta Road_Cnt
	jmp scrollBG		; 今回は更新しない

calcCourseSub:
	dec Road_YH		; Y座標アドレスの上位は$23→$22→$21→$20→$23...
	
setCourse:
	; ネームテーブルのRoad_YH*$100+Road_YHに道路を1ライン描画する
	lda Road_YH		; 上位アドレス
	ldx NameTblNum
	beq setCourseSub	; NameTblNumが0ならば$2000から更新する
	clc					; adcの前にキャリーフラグをクリア
	adc #8 				; NameTblNumが1ならば$2800から更新する

setCourseSub:
	sta $2006
	lda Road_YL		; 下位アドレス
	sta $2006
	jsr writeCourse

scrollBG:
	; コース設定
    jsr goCourse

	; BGスクロール
	lda $2002			; スクロール値クリア
	lda #0
	sta $2005			; X方向は固定
	lda Scroll_Y
	sta $2005			; Y方向スクロール
	dec Scroll_Y		; スクロール値を減算
	dec Scroll_Y		; スクロール値を減算
	cmp #254			; 254になった？
	bne end
	lda #238			; 16ドットスキップして238にする
	sta Scroll_Y

end:
	rti

	; コースを進める
goCourse:
	lda Road_Cnt
	beq goCourseSub	; 待ち中なら更新しない
	rts
goCourseSub:
	lda Course_Cnt
	bne goCourseSub2	; まだカウント中
	ldx Course_Index
	lda Course_Tbl, x	; Courseテーブルの値をAに読み込む
	pha					; AをPUSH
	and #$3				; bit0~1を取得
	sta Course_Dir		; コース方向に格納
	pla					; AをPULLして戻す
	lsr a				; 左2シフトしてbit2~7を取得
	lsr a
	sta Course_Cnt		; コースカウンターに格納
	inc Course_Index
	lda Course_Index
	cmp #10				; コーステーブル10回分ループする
	bne goCourseSub2
	lda #0				; インデックスを0に戻す
	sta Course_Index
goCourseSub2:
	lda Course_Dir
	bne goCourseLeft	; 0(直進)か？
	jmp goCourseEnd
goCourseLeft:
	cmp #$01			; 1(左折)か？
	bne goCourseRight
	dec Road_X			; 道路X座標減算
	jmp goCourseEnd
goCourseRight:
	inc Road_X			; 2(右折)なので道路X座標加算
goCourseEnd:
	dec Course_Cnt
	rts
.endproc


; --------------------------------------------------------------------
; BGに道路を１ライン描画する
.proc writeCourse
	; 左側の野原を描画
	ldx Road_X
	dex
	lda #$01		; 左側の野原をx座標-1分書き込む
writeLeftField:
	sta $2007		; $2007に書き込む
	dex
	bne writeLeftField

	; 左側の路肩描画判定
	; コース方向(0:直進1:左折2:右折)
	lda Course_Dir
	bne writeLeftLeft	; 0(直進)か？
	lda #$02			; 左側の路肩(直進)
	jmp writeLeftEnd
writeLeftLeft:
	cmp #$01			; 1(左折)か?
	bne writeLeftRight
	sta $2007			; Road_Xが-1されてるので野原を1キャラ多く書き込む
	lda #$04			; 左側の路肩(左折)
	jmp writeLeftEnd
writeLeftRight:
	lda #$06			; 左側の路肩(右折)

writeLeftEnd:
	sta $2007			; $2007に書き込む

	; 中央の道路を描画
	ldx #$09				; 道幅=10だがここでは9
	lda #$00			; 道路
writeRoad:
	sta $2007			; $2007に書き込む
	dex
	bne writeRoad


	; 右側の路肩を描画
	ldx Course_Dir
	bne writeRightLeft	; 0(直進)か？
	sta $2007			; 書いた道路は9なので野原を1キャラ多く書き込む
	lda #$03			; 右側の路肩(直進)
	jmp writeRightEnd
writeRightLeft:
	cpx #$01			; 1(左折)か?
	bne writeRightRight
	lda #$05			; 右側の路肩(左折)
	jmp writeRightEnd
writeRightRight:
	lda #$07			; 右側の路肩(右折)
writeRightEnd:
	sta $2007			; $2007に書き込む

	; 右側の野原を描画
	lda #31
	sec					; sbcの前にキャリーフラグをセット
	sbc Road_X			; 道路のX座標を引く
	sec					; sbcの前にキャリーフラグをセット
	sbc #10				; 道幅を引く
	tax
	lda #$01			; 右側の野原
writeRightField:
	sta $2007			; $2007に書き込む
	dex
	bne writeRightField
	rts
.endproc

.proc irq
	rti
.endproc

	; 初期データ
X_Pos_Init:
	.byte 120      ; X座標初期値
Y_Pos_Init:
	.byte 200      ; Y座標初期値

	; コースデータ(10個・bit0~1=方向・bit2~7カウンタ)
	; (直進=0,左折=1,右折=2)
Course_Tbl:
	.byte %00100001
	.byte %01000000
	.byte %00110010
	.byte %00100000
	.byte %00100001
	.byte %00100010
	.byte %00100000
	.byte %00100001
	.byte %00010010
	.byte %00110000

; パレットテーブル
palettes:
	.incbin "giko4.pal"

; ゼロページ
.org $0000
Scroll_Y:  .byte $00	; Yスクロール値
Road_X:    .byte $00	; 道路のX座標
Road_YL:   .byte $00	; 道路のY座標アドレス(下位)
Road_YH:   .byte $00	; 道路のY座標アドレス(上位)
Road_Cnt:  .byte $00	; 道路更新待ちカウンター
Course_Index: .byte $00 ; コーステーブルインデックス
Course_Dir: .byte $00  ; コース方向(0:直進1:左折2:右折)
Course_Cnt: .byte $00 ; コース方向継続カウンター 
NameTblNum: .byte $00	; ネームテーブル選択番号(0=$2000,1=$2800)

.segment "VECINFO"
	.word	mainloop
	.word	reset
	.word	irq

; パターンテーブル
.segment "CHARS"
	.incbin	"giko4.chr"
	.incbin	"giko2.spr"