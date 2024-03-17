	; 数値比較サンプル

	; INESヘッダー
	.inesprg 1 ;   - プログラムにいくつのバンクを使うか。今は１つ。
	.ineschr 1 ;   - グラフィックデータにいくつのバンクを使うか。今は１つ。
	.inesmir 0 ;   - 水平ミラーリング
	.inesmap 0 ;   - マッパー。０番にする。

	; ゼロページ
StrAdr_L = $00		; 文字列下位アドレス
StrAdr_H = $01		; 文字列上位アドレス
Value_A  = $02		; 数値A
Value_B  = $03		; 数値A

	.bank 1      ; バンク１
	.org $FFFA   ; $FFFAから開始

	.dw mainLoop ; VBlank割り込みハンドラ(1/60秒毎にmainLoopがコールされる)
	.dw Start    ; リセット割り込み。起動時とリセットでStartに飛ぶ
	.dw IRQ      ; ハードウェア割り込みとソフトウェア割り込みによって発生

	.bank 0			 ; バンク０

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
	lda $2002		; VBlankが発生すると、$2002の7ビット目が1になる
	bpl waitVSync  	; bit7が0の間は、waitVSyncラベルの位置に飛んでループして待ち続ける

	; PPUコントロールレジスタ2初期化
	lda #%00000110	; 初期化中はスプライトとBGを表示OFFにする
	sta $2001

	; パレットをロード
	ldx #$00    	; Xレジスタクリア

	; VRAMアドレスレジスタの$2006に、パレットのロード先のアドレス$3F00を指定する。
	lda #$3F
	sta $2006
	lda #$00
	sta $2006

loadPal:			; ラベルは、「ラベル名＋:」の形式で記述
	lda tilepal, x	; Aに(ourpal + x)番地のパレットをロードする
	sta $2007		; $2007にパレットの値を読み込む
	inx				; Xレジスタに値を1加算している
	cpx #32 		; Xを32(10進数。BGとスプライトのパレットの総数)と比較して同じかどうか比較している	
	bne loadPal		;	上が等しくない場合は、loadpalラベルの位置にジャンプする
	; Xが32ならパレットロード終了

	; 属性(BGのパレット指定データ)をロード

	; $23C0の属性テーブルにロードする
	lda #$23
	sta $2006
	lda #$C0
	sta $2006

	ldx #$00    	; Xレジスタクリア
	lda #%00000000	; ４つともパレット0番
loadAttrib
	sta $2007		; $2007に属性の値を読み込む
	; 64回(全キャラクター分)ループする
	inx
	cpx #64
	bne loadAttrib

	; ネームテーブル生成
	; ネームテーブルの$2000から生成する
	lda #$20
	sta $2006
	lda #$00
	sta $2006
	lda #$00        ; 0番(透明)
	ldx #240		; 240回繰り返す
	ldy #4			; それを4回、計960回繰り返す
loadNametable:
	sta $2007
	dex
	bne loadNametable
	ldx #240
	dey
	bne loadNametable

	; ゼロページ初期化
	lda #$00
	ldx #$00
initZeroPage:
	sta <$00, x
	inx
	bne initZeroPage

	; PPUコントロールレジスタ2初期化
	lda #%00001110	; BGの表示をONにする
	sta $2001

	; PPUコントロールレジスタ1の割り込み許可フラグを立てる
	lda #%10001000
	sta $2000

infinityLoop:					; VBlank割り込み発生を待つだけの無限ループ
	jmp infinityLoop

mainLoop:			; メインループ
	; タイトル文字列表示
	lda $2002
	lda #$20
	sta $2006
	lda #$40
	sta $2006
	; タイトル文字列アドレスセット
	lda #low(S_Title)			; テーブル下位アドレス取得
	sta <StrAdr_L
	lda #high(S_Title)			; テーブル上位アドレス取得
	sta <StrAdr_H
	jsr putStr

	; Value文字列表示
	lda $2002
	lda #$20
	sta $2006
	lda #$A0
	sta $2006
	; Value文字列アドレスセット
	lda #low(S_Value)			; テーブル下位アドレス取得
	sta <StrAdr_L
	lda #high(S_Value)			; テーブル上位アドレス取得
	sta <StrAdr_H
	jsr putStr

	; 値A表示
	lda $2002
	lda #$20
	sta $2006
	lda #$EA
	sta $2006
	lda <Value_A
	; 10の位取得
	lsr a
	lsr a
	lsr a
	lsr a
	jsr putHEX
	lda <Value_A
	; 1の位取得
	jsr putHEX

	; 値B表示
	lda #$20
	sta $2006
	lda #$F9
	sta $2006
	lda <Value_B
	; 10の位取得
	lsr a
	lsr a
	lsr a
	lsr a
	jsr putHEX
	lda <Value_B
	; 1の位取得
	jsr putHEX

	; パッドI/Oレジスタの準備
	lda #$01
	sta $4016
	lda #$00
	sta $4016

	; パッド入力チェック
	lda $4016  ; Aボタン
	and #1     ; AND #1
	bne AKEYdown ; 0でないならば押されてるのでAKeydownへジャンプ
	lda $4016  ; Bボタン
	and #1     ; AND #1
	bne BKEYdown ; 0でないならば押されてるのでBKeydownへジャンプ
	lda $4016  ; Selectボタンをスキップ
	lda $4016  ; Startボタンをスキップ
	lda $4016  ; 上ボタン
	and #1     ; AND #1
	bne UPKEYdown ; 0でないならば押されてるのでUPKeydownへジャンプ

NOTHINGdown:

	; スクロールクリア
	lda $2002
	lda #$00
	sta $2005
	sta $2005

	rti					; 割り込みから復帰

AKEYdown:
	inc <Value_A		; 値A加算
	jmp NOTHINGdown

BKEYdown:
	inc <Value_B		; 値B加算
	jmp NOTHINGdown

UPKEYdown:
	lda #$21
	sta $2006
	lda #$20
	sta $2006

	lda <Value_A
	cmp <Value_B		; AとValue_Bを比較
	bcc lessThan		; AがValue_B未満ならLessThanへ
	; Greater文字列アドレスセット
	lda #low(S_Greater)
	sta <StrAdr_L
	lda #high(S_Greater)
	sta <StrAdr_H
	jsr putStr
	jmp NOTHINGdown
lessThan:
	; Less文字列アドレスセット
	lda #low(S_Less)
	sta <StrAdr_L
	lda #high(S_Less)
	sta <StrAdr_H
	jsr putStr
	jmp NOTHINGdown

putHEX
	; レジスタAの値を16進数で出力
	and #$F
	cmp #$A			; Aと$Aを比較
	bcs baseA		; Aが$A以上ならbaseAへ
	; 0~9に変換
	clc
	adc #$30		; アスキーコード"0"=$30
	jmp putValue
baseA:
	; A~Fに変換
	clc
	adc #$37		; アスキーコード"A"=$41-$A=$37
	jmp putValue
putValue:
	sta $2007
	rts

putStr:
	; 文字列表示
	ldy #0
.putStrSub
	lda [StrAdr_L],y	; 間接アドレッシング
	cmp #'@'			; '@'か？
	beq .putStrEnd		; '@'ならエンドコードなので終了
	sta $2007			; 1文字出力
	iny
	jmp .putStrSub
.putStrEnd
	rts

IRQ:
	rti

	; 初期データ
tilepal: .incbin "giko5.pal" ; パレットをincludeする

	; '@'はエンドコードなので表示されない
S_Title:
	.db "  VALUE COMPARE@"
S_Value:
	.db "     VALUE A        VALUE B     @"
S_Less:
	.db "   A IS LESS THAN B            @"
S_Greater:
	.db "   A IS EQUAL OR GREATER THAN B@"

	.bank 2       ; バンク２
	.org $0000    ; $0000から開始

	.incbin "giko6.bkg"  ; 背景データのバイナリィファイルをincludeする