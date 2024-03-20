; 関数定義テスト
.proc drawchip
    ; 書き込み開始座標指定
    lda #$20
    sta $2006
    lda #$00
    sta $2006
    
    ; ループカウンタ
    ldx #$00
    ldy #$78
maploop:
    ; マップ情報を読み込みメモリーに退避
    lda map, x
    sta z_chip
    ; サブルーチンでyを書き換えるので、現在のy値をメモリーに退避
    sty z_index
    ; z_chipを情報を解析して書き込み
    jmp draw8chip
draw8chipr:
    ; yの値が書き換わっているのでメモリーから復帰
    ldy z_index
    inx
    dey
    bne maploop

    rts

; map情報から画面表示
draw8chip:
    ; 1bit単位で0なら通路、1なら壁)
    ldy #$08
loop:
    ; map情報の断片をロード
    lda z_chip
    ; bit演算した結果を出力BGデータでで 0は空白、1は塗りつぶしのパネルを設定している
    and #$01
    sta $2007
    ; 右にビットシフト
    lsr z_chip
    dey
    bne loop
    jmp draw8chipr ; ルーチンが近い場合はjmpしてみるテスト
.endproc
