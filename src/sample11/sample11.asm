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
	lda s_palettes, x	; Aに(ourpal + x)番地のパレットをロードする
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
	sta z_road_x

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
	sta z_road_yh
	lda #$C0
	sta z_road_yl
	
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
	inc z_road_cnt		; カウンタ増加
	lda z_road_cnt
	cmp #4
	bne scrollBG		; 4でないならまだ道路を描画しない
	
	; 描画更新
	lda #0
	sta z_road_cnt
	; 道路Y座標アドレス計算
	lda z_road_yl
	sec					; sbcの前にキャリーフラグをセット
	sbc #32				; 道路のY座標アドレス(下位)に32減算
	sta z_road_yl
	bcs setCourse		; 桁下がりしてなければsetCourseへ
	lda z_road_yh
	cmp #$20			; Y座標アドレス(上位)が$20まで下がったか？
	bne calcCourseSub

	; ネームテーブル選択番号を更新
	lda z_tbl_num
	eor #1
	sta z_tbl_num

	lda #$23			; 道路のY座標アドレス初期化($23C0)
	sta z_road_yh
	lda #$C0
	sta z_road_yl
	lda #03				; 次回更新するために、カウンタは4-1=3
	sta z_road_cnt
	jmp scrollBG		; 今回は更新しない

calcCourseSub:
	dec z_road_yh		; Y座標アドレスの上位は$23→$22→$21→$20→$23...
	
setCourse:
	; ネームテーブルのRoad_YH*$100+Road_YHに道路を1ライン描画する
	lda z_road_yh		; 上位アドレス
	ldx z_tbl_num
	beq setCourseSub	; z_tbl_numが0ならば$2000から更新する
	clc					; adcの前にキャリーフラグをクリア
	adc #8 				; z_tbl_numが1ならば$2800から更新する

setCourseSub:
	sta $2006
	lda z_road_yl		; 下位アドレス
	sta $2006
	jsr writeCourse

scrollBG:
	; コース設定
    jsr goCourse

	; BGスクロール
	lda $2002			; スクロール値クリア
	lda #0
	sta $2005			; X方向は固定
	lda z_scroll_y
	sta $2005			; Y方向スクロール
	dec z_scroll_y		; スクロール値を減算
	dec z_scroll_y		; スクロール値を減算
	cmp #254			; 254になった？
	bne end
	lda #238			; 16ドットスキップして238にする
	sta z_scroll_y

end:
	rti

	; コースを進める
goCourse:
	lda z_road_cnt
	beq goCourseSub	; 待ち中なら更新しない
	rts
goCourseSub:
	lda z_course_cnt
	bne goCourseSub2	; まだカウント中
	ldx z_course_index
	lda s_course_tbl, x	; Courseテーブルの値をAに読み込む
	pha					; AをPUSH
	and #$3				; bit0~1を取得
	sta z_course_dir		; コース方向に格納
	pla					; AをPULLして戻す
	lsr				; 左2シフトしてbit2~7を取得
	lsr
	sta z_course_cnt		; コースカウンターに格納
	inc z_course_index
	lda z_course_index
	cmp #10				; コーステーブル10回分ループする
	bne goCourseSub2
	lda #0				; インデックスを0に戻す
	sta z_course_index
goCourseSub2:
	lda z_course_dir
	bne goCourseLeft	; 0(直進)か？
	jmp goCourseEnd
goCourseLeft:
	cmp #$01			; 1(左折)か？
	bne goCourseRight
	dec z_road_x			; 道路X座標減算
	jmp goCourseEnd
goCourseRight:
	inc z_road_x			; 2(右折)なので道路X座標加算
goCourseEnd:
	dec z_course_cnt
	rts
.endproc


; --------------------------------------------------------------------
; BGに道路を１ライン描画する
.proc writeCourse
	; 左側の野原を描画
	ldx z_road_x
	dex
	lda #$01		; 左側の野原をx座標-1分書き込む
writeLeftField:
	sta $2007		; $2007に書き込む
	dex
	bne writeLeftField

	; 左側の路肩描画判定
	; コース方向(0:直進1:左折2:右折)
	lda z_course_dir
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
	ldx z_course_dir
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
	sbc z_road_x			; 道路のX座標を引く
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

; コースデータ(10個・bit0~1=方向・bit2~7カウンタ)
; (直進=0,左折=1,右折=2)
s_course_tbl:
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
s_palettes:
	.incbin "giko4.pal"

; ゼロページ
.org $0000
z_scroll_y:  .byte $00	; Yスクロール値
z_road_x:    .byte $00	; 道路のX座標
z_road_yl:   .byte $00	; 道路のY座標アドレス(下位)
z_road_yh:   .byte $00	; 道路のY座標アドレス(上位)
z_road_cnt:  .byte $00	; 道路更新待ちカウンター
z_course_index: .byte $00 ; コーステーブルインデックス
z_course_dir: .byte $00  ; コース方向(0:直進1:左折2:右折)
z_course_cnt: .byte $00 ; コース方向継続カウンター 
z_tbl_num: .byte $00	; ネームテーブル選択番号(0=$2000,1=$2800)

.segment "VECINFO"
	.word	mainloop
	.word	reset
	.word	irq

; パターンテーブル
.segment "CHARS"
	.incbin	"giko4.chr"
	.incbin	"giko2.spr"