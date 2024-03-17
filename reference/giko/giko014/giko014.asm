	; スタックサンプル

	; INESヘッダー
	.inesprg 1 ;   - プログラムにいくつのバンクを使うか。今は１つ。
	.ineschr 1 ;   - グラフィックデータにいくつのバンクを使うか。今は１つ。
	.inesmir 0 ;   - 水平ミラーリング
	.inesmap 0 ;   - マッパー。０番にする。

	; ゼロページ変数
Scroll_X = $00	; Xスクロール値
Sound_A = $01	; Aサウンド（矩形波１）カウンタ
Sound_B = $02   ; Bサウンド（矩形波２）カウンタ
Sound_C = $03   ; Cサウンド（三角波）カウンタ
Sound_D = $04   ; Dサウンド（ノイズ）カウンタ
BGM_Index = $05 ; Cサウンド（三角波）インデックス

	.bank 1      ; バンク１
	.org $FFFA   ; $FFFAから開始

	.dw mainLoop ; VBlank割り込みハンドラ(1/60秒毎にmainLoopがコールされる)
	.dw Start    ; リセット割り込み。起動時とリセットでStartに飛ぶ
	.dw IRQ      ; ハードウェア割り込みとソフトウェア割り込みによって発生

	.bank 0			 ; バンク０
	.org $0300	 ; $0300から開始、スプライトDMAデータ配置
Sprite1_Y:     .db  0   ; スプライト#1 Y座標
Sprite1_T:     .db  0   ; スプライト#1 ナンバー
Sprite1_S:     .db  0   ; スプライト#1 属性
Sprite1_X:     .db  0   ; スプライト#1 X座標
Sprite2_Y:     .db  0   ; スプライト#2 Y座標
Sprite2_T:     .db  0   ; スプライト#2 ナンバー
Sprite2_S:     .db  0   ; スプライト#2 属性
Sprite2_X:     .db  0   ; スプライト#2 X座標


	.org $8000	; $8000から開始
Start:
	sei			; 割り込み不許可
	cld			; デシマルモードフラグクリア
	ldx #$ff
	txs			; スタックポインタ初期化 

	; PPUコントロールレジスタ1初期化
	lda #%00001000	; ここではVBlank割り込み禁止
	sta $2000

waitVSync:
	lda $2002			; VBlankが発生すると、$2002の7ビット目が1になる
	bpl waitVSync  ; bit7が0の間は、waitVSyncラベルの位置に飛んでループして待ち続ける


	; PPUコントロールレジスタ2初期化
	lda #%00000110	; 初期化中はスプライトとBGを表示OFFにする
	sta $2001

	; パレットをロード
	ldx #$00    ; Xレジスタクリア

	; VRAMアドレスレジスタの$2006に、パレットのロード先のアドレス$3F00を指定する。
	lda #$3F
	sta $2006
	lda #$00
	sta $2006

loadPal:			; ラベルは、「ラベル名＋:」の形式で記述
	lda tilepal, x ; Aに(ourpal + x)番地のパレットをロードする

	sta $2007 ; $2007にパレットの値を読み込む

	inx ; Xレジスタに値を1加算している

	cpx #32 ; Xを32(10進数。BGとスプライトのパレットの総数)と比較して同じかどうか比較している	
	bne loadPal ;	上が等しくない場合は、loadpalラベルの位置にジャンプする
	; Xが32ならパレットロード終了

	; 属性(BGのパレット指定データ)をロード

	; $23C0の属性テーブルにロードする
	lda #$23
	sta $2006
	lda #$C0
	sta $2006

	ldx #$00    ; Xレジスタクリア
	lda #%00000000				; ４つともパレット0番
	; 0番か1番にする
loadAttrib
	eor #%01010101				; XOR演算で一つおきのビットを交互に０か１にする
	sta $2007					; $2007に属性の値($0か$55)を読み込む
	; 64回(全キャラクター分)ループする
	inx
	cpx #64
	bne loadAttrib

	; ネームテーブル生成

	; $2000のネームテーブルに生成する
	lda #$20
	sta $2006
	lda #$00
	sta $2006

	lda #$00        ; 0番(真っ黒)
	ldy #$00    ; Yレジスタ初期化
loadNametable1:
	ldx Star_Tbl, y			; Starテーブルの値をXに読み込む
loadNametable2:
	sta $2007				; $2007に属性の値を読み込む
	dex						; X減算
	bne loadNametable2		; まだ0でないならばループして黒を出力する
	; 1番か2番のキャラをYの値から交互に取得
	tya							; Y→A
	and #1					; A AND 1
	adc #1					; Aに1加算して1か2に
	sta $2007				; $2007に属性の値を読み込む
	lda #$00        ; 0番(真っ黒)
	iny							; Y加算
	cpy #20					; 20回(星テーブルの数)ループする
	bne loadNametable1

	; １番目のスプライト座標初期化
	lda X_Pos_Init
	sta Sprite1_X
	lda Y_Pos_Init
	sta Sprite1_Y
	; ２番目のスプライト座標更新サブルーチンをコール
	jsr setSprite2
	; ２番目のスプライトを水平反転
	lda #%01000000
	sta Sprite2_S

	; ゼロページ初期化
	lda #$00
	ldx #$00
initZeroPage:
	sta <$00, x
	inx
	bne initZeroPage

	; PPUコントロールレジスタ2初期化
	lda #%00011110	; スプライトとBGの表示をONにする
	sta $2001

	; サウンドレジスタ初期化（三角波とノイズをON）
	lda #%00001100
	sta $4015

	; PPUコントロールレジスタ1の割り込み許可フラグを立てる
	lda #%10001000
	sta $2000

infinityLoop:					; VBlank割り込み発生を待つだけの無限ループ
	jmp infinityLoop

mainLoop:					; メインループ
	; スプライト描画(DMAを利用)
	lda #$3  ; スプライトデータは$0300番地からなので、3をロードする。
	sta $4014 ; スプライトDMAレジスタにAをストアして、スプライトデータをDMA転送する
	
	; BGスクロール
	lda $2002			; スクロール値クリア
	lda <Scroll_X	; Xのスクロール値をロード
	sta $2005			; X方向スクロール（Y方向は固定)
	inc <Scroll_X	; スクロール値を加算

	; 音楽とノイズ鳴らす
	jsr playBGM
	jsr playNoise

	; パッドI/Oレジスタの準備
	lda #$01
	sta $4016
	lda #$00
	sta $4016

	; パッド入力チェック
	lda $4016  ; Aボタン
	pha		   ; AをPUSH
	lda $4016  ; Bボタン
	pha		   ; AをPUSH
	lda $4016  ; Selectボタンをスキップ
	lda $4016  ; Startボタンをスキップ
	lda $4016  ; 上ボタン
	pha		   ; AをPUSH
	lda $4016  ; 下ボタン
	pha		   ; AをPUSH
	lda $4016  ; 左ボタン
	pha		   ; AをPUSH
	lda $4016  ; 右ボタン
	pha		   ; AをPUSH

	pla		   	; AをPULL(右ボタンの内容)
	and #1     	; AND #1
	beq pull_A1	; 0ならばPull_A1へジャンプ
	jsr RIGHTKEYdown
pull_A1:
	pla		   	; AをPULL(左ボタンの内容)
	and #1     	; AND #1
	beq pull_A2	; 0ならばPull_A2へジャンプ
	jsr LEFTKEYdown
pull_A2:
	pla		   	; AをPULL(下ボタンの内容)
	and #1     	; AND #1
	beq pull_A3	; 0ならばPull_A3へジャンプ
	jsr DOWNKEYdown
pull_A3:
	pla		   	; AをPULL(上ボタンの内容)
	and #1     	; AND #1
	beq pull_A4	; 0ならばPull_A4へジャンプ
	jsr UPKEYdown
pull_A4:
	pla		   	; AをPULL(Bボタンの内容)
	and #1     	; AND #1
	beq pull_A5	; 0ならばPull_A5へジャンプ
	jsr BKEYSound
pull_A5:
	pla		   	; AをPULL(Aボタンの内容)
	and #1     	; AND #1
	beq setSpr	; 0ならばsetSprへジャンプ
	jsr AKEYSound


setSpr:
	; ２番目のスプライト座標更新サブルーチンをコール
	jsr setSprite2
	
	; サウンド待ちカウンタA~D(ゼロページで連続した領域という前提)をそれぞれ-1減算する
	ldx #0
dec_Counter
	lda <Sound_A,x
	beq dec_Next
	dec <Sound_A,x 
dec_Next:	
	inx
	cpx #4			; 4回繰り返す
	bne dec_Counter
	
NMIEnd:
	rti				; 割り込みから復帰

UPKEYdown:
	dec Sprite1_Y	; Y座標を1減算
	rts

DOWNKEYdown:
	inc Sprite1_Y ; Y座標を1加算
	rts

LEFTKEYdown:
	dec Sprite1_X	; X座標を1減算
	rts

RIGHTKEYdown:
	inc Sprite1_X	; X座標を1加算
	rts

AKEYSound:
	; サウンド待ちカウンタAが0でない場合はサウンドを鳴らさない
	lda <Sound_A
	beq .soundSub
	rts
.soundSub
	lda #10			; 1/6秒に1回鳴らす
	sta <Sound_A

	lda $4015		; サウンドレジスタ
	ora #%00000001	; 矩形波チャンネル１を有効にする
	sta $4015

	lda #%10111111
	sta $4000		; 矩形波チャンネル１制御レジスタ１

	lda #%10101011
	sta $4001		; 矩形波チャンネル１制御レジスタ２
	lda Sprite1_X		; お遊びでX座標を入れてみる
	sta $4002		; 矩形波チャンネル１周波数レジスタ１

	lda #%11111011
	sta $4003		; 矩形波チャンネル１周波数レジスタ２

	rts

BKEYSound:
	; サウンド待ちカウンタBが0でない場合はサウンドを鳴らさない
	lda <Sound_B
	beq .soundSub
	rts
.soundSub
	lda #10			; 1/6秒に1回鳴らす
	sta <Sound_B

	lda $4015		; サウンドレジスタ
	ora #%00000010	; 矩形波チャンネル２を有効にする
	sta $4015

	lda #%10111111
	sta $4004		; 矩形波チャンネル２制御レジスタ１

	lda #%10000100
	sta $4005		; 矩形波チャンネル２制御レジスタ２
	lda Sprite1_Y		; お遊びでY座標を入れてみる
	sta $4006		; 矩形波チャンネル２周波数レジスタ１

	lda #%11111000
	sta $4007		; 矩形波チャンネル２周波数レジスタ２

	rts

playBGM:
	; サウンド待ちカウンタCが0でない場合はサウンドを鳴らさない
	lda <Sound_C
	beq .soundSub
	rts
.soundSub
	ldx BGM_Index				; BGMテーブルインデックスをXに読み込む
	lda BGM_Tbl, x				; BGMテーブルから待ちカウントを読み込む
	sta <Sound_C				; 待ちカウントを設定
	inx							; BGMテーブルインデックス進める

	lda #%11111111
	sta $4008					; 三角波チャンネル制御レジスタ

	lda BGM_Tbl, x				; BGMテーブルから音階を読み込む
	sta $400A					; 三角波チャンネル周波数レジスタ１

	lda #%11111001 
	sta $400B					; 三角波チャンネル周波数レジスタ２

	inx							; BGMテーブルインデックス進める
	cpx #20						; 最後に到達？
	bne playBGMEnd
	ldx #0						; インデックスを最初に戻す
playBGMEnd:
	stx BGM_Index				; BGMテーブルインデックスをXに読み込む

	rts

playNoise
	; サウンド待ちカウンタDが0でない場合はサウンドを鳴らさない
	lda <Sound_D
	beq .soundSub
	rts
.soundSub:
	lda #60			; 1秒に1回鳴らす
	sta <Sound_D

	lda #%11101111
	sta $400C		; ノイズ制御レジスタ

	lda Sprite1_X	; お遊びでX座標を入れてみる
	sta $400E		; ノイズ周波数レジスタ１

	lda #%11111111
	sta $400F		; ノイズ周波数レジスタ２

	rts

setSprite2:
	; ２番目のスプライトの座標更新サブルーチン
	clc					;　adcの前にキャリーフラグをクリア
	lda Sprite1_X
	adc #8 				; 8ﾄﾞｯﾄ右にずらす
	sta Sprite2_X
	lda Sprite1_Y
	sta Sprite2_Y
	rts

IRQ:
	rti

	; 初期データ
X_Pos_Init   .db 20       ; X座標初期値
Y_Pos_Init   .db 40       ; Y座標初期値

	; 星テーブルデータ(20個)
Star_Tbl    .db 60,45,35,60,90,65,45,20,90,10,30,40,65,25,65,35,50,35,40,35

	; BGMテーブルデータ(待ちカウンタ＆音階が10個)
BGM_Tbl		.db 20,$80,10,$10,30,$04,20,$40,10,$80,10,$20,20,$20,20,$30,10,$10,30,$00

tilepal: .incbin "giko2.pal" ; パレットをincludeする

	.bank 2       ; バンク２
	.org $0000    ; $0000から開始

	.incbin "giko2.bkg"  ; 背景データのバイナリィファイルをincludeする
	.incbin "giko2.spr"  ; スプライトデータのバイナリィファイルをincludeする