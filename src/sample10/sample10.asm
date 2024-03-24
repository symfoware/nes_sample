; 三角波チャンネルサンプル
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

; 画面描画
	ldx #$00
	ldy #$10
	lda $2002
	lda	#$21
	sta	$2006
	lda	#$c9
	sta	$2006
write_str:
	lda string, x
	sta	$2007
	inx
	dey
	bne write_str

;カーソル
	lda	#$21
	sta	$2006
	lda	#$f8
	sta	$2006
	; x座標保存
	sta z_coursor
	lda #$20
	sta	$2007

; スクロール設定
	lda	#$00
	sta	$2005
	sta	$2005

; ノイズ使用
	lda #%00001000
	sta $4015

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
; 連続で反応するので、ある程度入力を間引く
	inc z_counter
	lda z_counter
	cmp #$0f
	bcc end

; カウンターリセット
	lda #$00
	sta z_counter
	
; 入力受付
; パッドI/Oレジスタ リセット
    lda #$01
    sta $4016
    lda #$00 
    sta $4016

; パッド入力チェック
    lda $4016 ; Aボタン
	and #$01
	bne akey_down
    
	lda $4016 ; Bボタンをスキップ
    lda $4016 ; Selectボタンをスキップ
    lda $4016 ; Startボタンをスキップ
	
    lda $4016 ; 上ボタン
    and #$01     ; AND #1
    bne upkey_down ; 0でないならば押されてるのでupkey_downへジャンプ
    
    lda $4016 ; 下ボタン
    and #$01     ; AND #1
    bne downkey_down ; 0でないならば押されてるのでdownkey_downへジャンプ

    lda $4016 ; 左ボタン
    and #$01     ; AND #1
    bne leftkey_down

    lda $4016 ; 左ボタン
    and #$01     ; AND #1
    bne rightkey_down

	jmp end

; Aキー入力
akey_down:
	; 音を出す
	jsr sound
	jmp end

; 上下キー入力
upkey_down:
downkey_down:
	jsr change_noise_bit
	jmp end

leftkey_down:
	jsr change_coursor_left
	jmp end

rightkey_down:
	jsr change_coursor_right
	jmp end

end:

	rti
.endproc

; ノイズのビット変更
.proc change_noise_bit

	lda z_coursor
	cmp #$ee ; カーソル位置乱数
	beq rand

	cmp #$f5 ; bit3
	beq bit3

	cmp #$f6 ; bit2
	beq bit2

	cmp #$f7 ; bit1
	beq bit1

	cmp #$f8 ; bit0
	beq bit0

	jmp end

; 該当ビットを判定
rand:
	lda z_noise
	eor #%10000000
	sta z_noise
	jmp end

bit3:
	lda z_noise
	eor #%00001000
	sta z_noise
	jmp end

bit2:
	lda z_noise
	eor #%00000100
	sta z_noise
	jmp end

bit1:
	lda z_noise
	eor #%00000010
	sta z_noise
	jmp end

bit0:
	lda z_noise
	eor #%00000001
	sta z_noise
	jmp end

end:
	; 現在の状態を描画
	jsr draw_noise

	rts
.endproc

; カーソル位置移動
.proc change_coursor_left
	lda z_coursor
	cmp #$ee ; 乱数位置ならこれ以上左に行けない
	beq end

	cmp #$f5 ; 波長最上位
	beq move_rand

	; 上記以外はカーソル位置を1引く
	dec z_coursor
	jmp end

move_rand:
	lda #$ee
	sta z_coursor
	jmp end

end:
	jsr draw_coursor
	rts

.endproc

.proc change_coursor_right
	lda z_coursor
	cmp #$f8 ; bit0位置ならこれ以上右に行けない
	beq end

	cmp #$ee ; 乱数位置
	beq move_rand

	; 上記以外はカーソル位置を1足す
	inc z_coursor
	jmp end

move_rand:
	lda #$f5
	sta z_coursor
	jmp end

end:
	jsr draw_coursor
	rts
.endproc

.proc draw_coursor
	; 一度カーソルを非表示
	lda	#$21
	sta	$2006
	lda	#$ee
	sta	$2006

	ldy #$0b
clear:
	lda #$00
	sta	$2007
	dey
	bne clear

	lda	#$21
	sta	$2006
	lda	z_coursor
	sta	$2006
	lda #$20
	sta	$2007

	lda	#$00	; スクロール設定
	sta	$2005
	sta	$2005
	rts

.endproc

; ノイズの設定値描画
.proc draw_noise
; 乱数
	lda	#$21
	sta	$2006
	lda	#$ce
	sta	$2006

	lda z_noise
	and #%10000000
	bne zero1
	lda #$30
	jmp end1

zero1:
	lda #$31
end1:
	sta	$2007

; bit3
	lda	#$21
	sta	$2006
	lda	#$d5
	sta	$2006

	lda z_noise
	and #%000001000
	bne zero2
	lda #$30
	jmp end2

zero2:
	lda #$31
end2:
	sta	$2007

;bit2
	lda z_noise
	and #%000000100
	bne zero3
	lda #$30
	jmp end3

zero3:
	lda #$31
end3:
	sta	$2007

;bit1
	lda z_noise
	and #%000000010
	bne zero4
	lda #$30
	jmp end4

zero4:
	lda #$31
end4:
	sta	$2007

;bit0
	lda z_noise
	and #%000000001
	bne zero5
	lda #$30
	jmp end5

zero5:
	lda #$31
end5:
	sta	$2007

	lda	#$00	; スクロール設定
	sta	$2005
	sta	$2005
	rts



.endproc

; 音を鳴らす
.proc sound
	; bit7-6: 未使用
	; bit5: エンベロープDecayループ/長さカウンタ無効(1:ループ/無効)
	; bit4: エンベロープDecay無効(1:無効,0:有効)
	; bit3-0: ボリューム/Decayレート
	lda #%00001111
	sta $400c

	; bit7: 乱数タイプ選択(0:32Kmode,1:93bitmode)
	; bit6-4: 未使用
	; bit3-0: 波長選択
	lda z_noise
	sta $400c

	; bit7-3: 音の長さ
	; bit2-0: 未使用
	lda #%11000000
	sta $400f

	rts
.endproc


; パレットテーブル
palettes:
	.byte	$0f, $00, $10, $20
	.byte	$0f, $06, $16, $26
	.byte	$0f, $08, $18, $28
	.byte	$0f, $0a, $1a, $2a

; 表示文字列
string: ; らんすう：０　はちょう：０００
	.byte	$a6, $ad, $8c, $82, $5b, $30, $00
	.byte	$99, $90, $b6, $82, $5b, $30, $30, $30, $30

; ゼロページ
.org $0000
z_counter: .byte $00 ; 入力受付カウンター
z_coursor: .byte $00 ; カーソル位置
z_noise: .byte $00 ; ノイズの設定値

.segment "VECINFO"
	.word	mainloop
	.word	reset
	.word	$0000

; パターンテーブル
.segment "CHARS"
	.incbin	"character.chr"