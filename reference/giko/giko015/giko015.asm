	; ラスタースクロールサンプル

	; INESヘッダー
	.inesprg 1 ;   - プログラムにいくつのバンクを使うか。今は１つ。
	.ineschr 1 ;   - グラフィックデータにいくつのバンクを使うか。今は１つ。
	.inesmir 0 ;   - 水平ミラーリング
	.inesmap 0 ;   - マッパー。０番にする。

	; ゼロページ変数
Scroll_X1 = $00	; 上段スクロール値
Scroll_X2 = $01	; 中段スクロール値
Scroll_X3 = $02	; 下段スクロール値

	.bank 1      ; バンク１
	.org $FFFA   ; $FFFAから開始

	.dw mainLoop ; VBlank割り込みハンドラ(1/60秒毎にmainLoopがコールされる)
	.dw Start    ; リセット割り込み。起動時とリセットでStartに飛ぶ
	.dw IRQ      ; ハードウェア割り込みとソフトウェア割り込みによって発生

	.bank 0		; バンク０

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
	bpl waitVSync	; bit7が0の間は、waitVSyncラベルの位置に飛んでループして待ち続ける

	; PPUコントロールレジスタ2初期化
	lda #%00000110	; 初期化中はスプライトとBGを表示OFFにする
	sta $2001

	; パレットをロード
	ldx #$00		; Xレジスタクリア

	; VRAMアドレスレジスタの$2006に、パレットのロード先のアドレス$3F00を指定する。
	lda #$3F
	sta $2006
	lda #$00
	sta $2006

loadPal:			; ラベルは、「ラベル名＋:」の形式で記述
	lda tilepal, x	; Aに(ourpal + x)番地のパレットをロードする

	sta $2007		; $2007にパレットの値を読み込む

	inx				; Xレジスタに値を1加算している

	cpx #32			; Xを32(10進数。BGとスプライトのパレットの総数)と比較して同じかどうか比較している	
	bne loadPal		;	上が等しくない場合は、loadpalラベルの位置にジャンプする
	; Xが32ならパレットロード終了

	; 属性(BGのパレット指定データ)をロード

	; $23C0の属性テーブルにロードする
	lda #$23
	sta $2006
	lda #$C0
	sta $2006

	ldx #$00		; Xレジスタクリア
	lda #%00000000	; ４つともパレット0番
	; 全て0番にする
loadAttrib
	sta $2007		; $2007に属性の値($0)を読み込む
	; 64回(全キャラクター分)ループする
	inx
	cpx #64
	bne loadAttrib

	; ネームテーブル生成(250+230=480回を0番、1番の順で合計960回書き込む)

	; ネームテーブルの$2000から生成する
	lda #$20
	sta $2006
	lda #$00
	sta $2006

	lda #$00        ; 0番(透明)
	ldx #$00		; Xレジスタ初期化
	jmp loadNametable2
loadNametable1:
	lda #$01        ; 1番(地面)
	ldx #$00		; Xレジスタ初期化
loadNametable2:
	sta $2007		; $2007に書き込む
	inx
	cpx #250		; 250回繰り返す
	bne loadNametable2
	ldx $00
loadNametable3:
	sta $2007		; $2007に書き込む
	inx
	cpx #230		; 230回繰り返す
	bne loadNametable3
	cmp #$01
	bne loadNametable1	; まだ半分なので戻る

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

	; PPUコントロールレジスタ1の割り込み許可フラグを立てる
	lda #%10001000
	sta $2000

	; ラスタースクロール開始点に0番スプライト配置
	lda #$00   ; $00(スプライトRAMのアドレスは8ビット長)をAにロード
	sta $2003  ; AのスプライトRAMのアドレスをストア

	lda #119	; スキャンラインの真ん中(ラスタースクロール開始点)
	sta $2004   ; Y座標をレジスタにストアする
	lda #00
	sta $2004   ; 0をストアして0番のスプライトを指定する
	sta $2004   ; 反転や優先順位は操作しないので、再度$00をストアする
	lda #0
	sta $2004   ; X座標をレジスタにストアする

infinityLoop:					; VBlank割り込み発生を待つだけの無限ループ

waitZeroSpriteClear:			; 0番スプライト描画前まで待つ
	bit $2002
	bvs waitZeroSpriteClear		; $2002の6ビット目が0になるまで待つ
waitZeroSpriteHit:				; 0番スプライト描画まで待つ
	bit $2002
	bvc waitZeroSpriteHit		; $2002の6ビット目が1になるまで待つ

	; BGスクロール(上段)
	lda $2002		; スクロール値クリア
	lda <Scroll_X1	; 上段スクロール値をロード
	lsr a			; Aレジスタ右シフト(半分にする)
	jsr doScrollX
	inc <Scroll_X1	; スクロール値を加算

	jsr waitScan
	jsr waitScan
	jsr waitScan

	; BGスクロール(中段)
	lda $2002		; スクロール値クリア
	lda <Scroll_X2	; 中段スクロール値をロード
	jsr doScrollX
	inc <Scroll_X2	; スクロール値を加算

	jsr waitScan
	jsr waitScan
	jsr waitScan

	; BGスクロール(下段)
	lda $2002		; スクロール値クリア
	lda <Scroll_X3	; 下段スクロール値をロード
	lsr a			; Aレジスタ右シフト(半分にする)
	jsr doScrollX
	inc <Scroll_X3	; スクロール値を加算
	inc <Scroll_X3	; スクロール値を加算
	inc <Scroll_X3	; スクロール値を加算

	jmp infinityLoop

mainLoop:			; メインループ
	; スクロール固定(VBlank割り込み直後に実行するので、次の画面描画の最初から固定することになる)
	lda $2002		; スクロール値クリア
	lda #$00
	jsr doScrollX

	rti				; 割り込みから復帰

doScrollX			; X方向スクロール(Aレジスタに値セット済)
	sta $2005		; X方向スクロール
	lda #$00		; Y方向固定
	sta $2005
	rts

waitScan			; 何もせず待つ
	ldx #255
.waitScanSub
	dex
	bne .waitScanSub
	rts

IRQ:
	rti

tilepal: .incbin "giko3.pal" ; パレットをincludeする

	.bank 2       ; バンク２
	.org $0000    ; $0000から開始

	.incbin "giko3.bkg"  ; 背景データのバイナリィファイルをincludeする
	.incbin "giko2.spr"  ; スプライトデータのバイナリィファイルをincludeする