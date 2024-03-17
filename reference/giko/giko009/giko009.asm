	; スプライトDMAサンプル

	; INESヘッダー
	.inesprg 1 ;   - プログラムにいくつのバンクを使うか。今は１つ。
	.ineschr 1 ;   - グラフィックデータにいくつのバンクを使うか。今は１つ。
	.inesmir 0 ;   - 水平ミラーリング
	.inesmap 0 ;   - マッパー。０番にする。

	.bank 1      ; バンク１
	.org $FFFA   ; $FFFAから開始

	.dw 0        ; VBlank割り込み
	.dw Start    ; リセット割り込み。起動時とリセットでStartに飛ぶ
	.dw 0        ; ハードウェア割り込みとソフトウェア割り込みによって発生

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

	.org $8000	 ; $8000から開始
Start:
	lda $2002  ; VBlankが発生すると、$2002の7ビット目が1になる
	bpl Start  ; bit7が0の間は、Startラベルの位置に飛んでループして待つ

	; PPUコントロールレジスタ初期化
	lda #%00001000
	sta $2000
	lda #%00000110		; 初期化中はスプライトとBGを表示OFFにする
	sta $2001

	ldx #$00    ; Xレジスタクリア

	; VRAMアドレスレジスタの$2006に、パレットのロード先のアドレス$3F00を指定する。
	lda #$3F    ; have $2006 tell
	sta $2006   ; $2007 to start
	lda #$00    ; at $3F00 (pallete).
	sta $2006

loadPal:			; ラベルは、「ラベル名＋:」の形式で記述
	lda tilepal, x ; Aに(ourpal + x)番地のパレットをロードする

	sta $2007 ; $2007にパレットの値を読み込む

	inx ; Xレジスタに値を1加算している

	cpx #32 ; Xを32(10進数。BGとスプライトのパレットの総数)と比較して同じかどうか比較している	
	bne loadPal ;	上が等しくない場合は、loadpalラベルの位置にジャンプする
	; Xが32ならパレットロード終了

	; １番目のスプライト座標初期化
	lda X_Pos_Init
	sta Sprite1_X
	lda Y_Pos_Init
	sta Sprite1_Y
	; ２番目のスプライト座標初期化
	lda X_Pos_Init
	adc #7 		; ７ﾄﾞｯﾄ右にずらす
	sta Sprite2_X
	lda Y_Pos_Init
	sta Sprite2_Y
	; ２番目のスプライトを水平反転
	lda #%01000000
	sta Sprite2_S

	; PPUコントロールレジスタ2初期化
	lda #%00011110	; スプライトとBGの表示をONにする
	sta $2001

mainLoop:					; メインループ
	lda $2002  ; VBlankが発生すると、$2002の7ビット目が1になります。
	bpl mainLoop  ; bit7が0の間は、mainLoopラベルの位置に飛んでループして待ち続けます。

	; スプライト描画(DMAを利用)
	lda #$3  ; スプライトデータは$0300番地からなので、3をロードする。
	sta $4014 ; スプライトDMAレジスタにAをストアして、スプライトデータをDMA転送する
	
	; パッドI/Oレジスタの準備
	lda #$01
	sta $4016
	lda #$00 
	sta $4016

	; パッド入力チェック
	lda $4016  ; Aボタンをスキップ
	lda $4016  ; Bボタンをスキップ
	lda $4016  ; Selectボタンをスキップ
	lda $4016  ; Startボタンをスキップ
	lda $4016  ; 上ボタン
	and #1     ; AND #1
	bne UPKEYdown  ; 0でないならば押されてるのでUPKeydownへジャンプ
	
	lda $4016  ; 下ボタン
	and #1     ; AND #1
	bne DOWNKEYdown ; 0でないならば押されてるのでDOWNKeydownへジャンプ

	lda $4016  ; 左ボタン
	and #1     ; AND #1
	bne LEFTKEYdown ; 0でないならば押されてるのでLEFTKeydownへジャンプ

	lda $4016  ; 右ボタン
	and #1     ; AND #1
	bne RIGHTKEYdown ; 0でないならば押されてるのでRIGHTKeydownへジャンプ
	jmp NOTHINGdown  ; なにも押されていないならばNOTHINGdownへ

UPKEYdown:
	dec Sprite1_Y	; Y座標を1減算
	jmp NOTHINGdown

DOWNKEYdown:
	inc Sprite1_Y ; Y座標を1加算
	jmp NOTHINGdown

LEFTKEYdown:
	dec Sprite1_X	; X座標を1減算
	jmp NOTHINGdown 

RIGHTKEYdown:
	inc Sprite1_X	; X座標を1加算
	; この後NOTHINGdownなのでジャンプする必要無し

NOTHINGdown:
	; ２番目のスプライトの座標更新
	lda Sprite1_X
	adc #8 		; 8ﾄﾞｯﾄ右にずらす
	sta Sprite2_X
	lda Sprite1_Y
	sta Sprite2_Y

	jmp mainLoop				; mainLoopの最初に戻る

	; 初期データ
X_Pos_Init   .db 20       ; X座標初期値
Y_Pos_Init   .db 40       ; Y座標初期値

tilepal: .incbin "giko2.pal" ; パレットをincludeする

	.bank 2       ; バンク２
	.org $0000    ; $0000から開始

	.incbin "giko.bkg"  ; 背景データのバイナリィファイルをincludeする
	.incbin "giko2.spr"  ; スプライトデータのバイナリィファイルをincludeする