; 矩形波チャンネルサンプル
; 上下キーで周波数変更
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
	sei
	ldx	#$ff
	txs

; スクリーンオフ
	lda	#$00
	sta	$2000
waitVSync:
    lda $2002            ; VBlankが発生すると、$2002の7ビット目が1になる
    bpl waitVSync ; bit7が0の間は、waitVSyncラベルの位置に飛んでループして待ち続ける
    
	lda	#$00
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

; 初期値C(ascii $43)を指定
    lda #$43
    sta $0000 ;初期値を$0000に保存
    sta $0001 ;初期値を$0001に保存(比較用)

	lda #%11010101	;鳴らしている周波数を0002に設定
	sta $0002

	ldy #$00		;カウンターリセット

; 矩形波チャンネル1有効化
	lda #%00000001	; bit 0を1にし矩形波チャンネル1有効
	sta $4015		; データ書き込み

; 矩形波チャンネル1設定
	lda #%00000001	; 矩形波チャンネル１を有効にする
	sta $4015

	lda #%10111111	; 波形比率8/8, ループ, Decay無効, 音量最大
	sta $4000

	lda #%00000000	; スイープ類無効
	sta $4001

	lda $0002
	sta $4002

	lda #%00000000	; スイープ設定時パラメーター 全て未指定
	sta $4003

; スクロール設定
	lda	#$00
	sta	$2005
	sta	$2005

; スクリーンオン
    lda    #%10001000    ; 最初のビットを1にして、VBlank時にNMIを実行する
    sta    $2000 ;PPUコントロールレジスタ１
    lda    #%00011110
    sta    $2001 ;PPUコントロールレジスタ２

; VBlank割り込み発生を待つだけの無限ループ
infinityLoop:
    jmp infinityLoop
.endproc

.proc mainloop

	iny				; yをインクリメント
	cpy #$f			; yと#$f(適当な数値)と比較
	bcc end		; yが#$f以下なら入力キャンセル

	ldy #$00		;カウンターリセット
	

; パッドI/Oレジスタ リセット
    lda #$01
    sta $4016
    lda #$00 
    sta $4016

; パッド入力チェック
    lda $4016 ; Aボタンをスキップ
    lda $4016 ; Bボタンをスキップ
    lda $4016 ; Selectボタンをスキップ
    lda $4016 ; Startボタンをスキップ
	
    lda $4016 ; 上ボタン
    and #1     ; AND #1
    bne upkey_down ; 0でないならば押されてるのでupkey_downへジャンプ
    
    lda $4016 ; 下ボタン
    and #1     ; AND #1
    bne downkey_down ; 0でないならば押されてるのでdownkey_downへジャンプ

	jmp end

; 上キー入力
upkey_down:
	inc $0000	; 1加算
	lda $0000
	cmp #$48	; $48(文字H以上)ならAに戻す
	bcs reset_a

	jmp end
    
downkey_down:
	dec $0000	; 1減算
	lda $0000
	cmp #$41	; $48(文字H以上)ならAに戻す
	bcc reset_g

	jmp end

reset_a:
    lda #$41
    sta $0000
	jmp end

reset_g:
    lda #$47
    sta $0000
	jmp end

end:
	jsr draw_and_sound
	rti
.endproc

; 再描画と音階変更
.proc draw_and_sound

	lda $2002	; PPUステータスレジスタをリードしてリセット
	lda	#$21
	sta	$2006
	lda	#$cf
	sta	$2006

	lda $0000
	sta	$2007

	lda	#$00	; スクロール設定
	sta	$2005
	sta	$2005

	; 直前鳴らしていた音と比較
	lda $0000
	cmp $0001
	beq end		;同じだったら処理終了

	sta $0001	;変更後の値を保存

	jsr set_frequency	; 該当周波数を$0002に設定

	; 周波数設定
	lda $0002
	sta $4002


end:
	rts
.endproc

.proc set_frequency
	lda $0000
	cmp #$41	; A
	beq seta

	cmp #$42	; B
	beq setb

	cmp #$43	; C
	beq setc

	cmp #$44	; D
	beq setd

	cmp #$45	; E
	beq sete

	cmp #$46	; F
	beq setf

	cmp #$47	; G
	beq setg

seta:
	lda #%01111110
	jmp end
setb:
	lda #%01110000
	jmp end
setc:
	lda #%11010101
	jmp end
setd:
	lda #%10111101
	jmp end
sete:
	lda #%10101001
	jmp end
setf:
	lda #%10011111
	jmp end
setg:
	lda #%10001110
	jmp end

end:
	sta $0002
	rts
.endproc


; パレットテーブル
palettes:
	.byte	$0f, $00, $10, $20
	.byte	$0f, $06, $16, $26
	.byte	$0f, $08, $18, $28
	.byte	$0f, $0a, $1a, $2a

; 表示文字列
string:
	.byte	"ABCDEFGHIJKLM"

.segment "VECINFO"
	.word	mainloop
	.word	reset
	.word	$0000

; パターンテーブル
.segment "CHARS"
	.incbin	"character.chr"