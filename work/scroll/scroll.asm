.setcpu "6502"
.autoimport  on

; iNESヘッダ "HEADER"はcfgのSEGMENTSで定義
.segment "HEADER"
    .byte $4E, $45, $53, $1A    ; "NES" Header
    .byte $02                   ; PRG-BANKS
    .byte $01                   ; CHR-BANKS
    .byte $01                   ; Vetrical Mirror
    .byte $00                   ; 
    .byte $00, $00, $00, $00    ; 
    .byte $00, $00, $00, $00    ; 

.segment "STARTUP" ; "STARTUP"はcfgのSEGMENTSで定義
; リセット割り込み
.proc reset
    sei ; 割り込み不可
    cld ; デシマルモードクリア(作法)
    ldx #$ff
    txs ; スタックポインタ初期化

; スクリーンオフ
    lda #$00
    sta $2000 ; 基本設定をクリア
    sta $2001 ; マスク設定をクリア

; パレットテーブルへ転送
; VRAM BG用パレット $3F00～$3F0F へ転送を実施
; VRAM スプライト用パレット $3F10～$3F1F へ転送を実施
    lda #$3f ; VRAMアドレス上位1byte
    sta $2006
    lda #$00 ; VRAMアドレス下位1byte
    sta $2006 ; $2006 へ2回 store を行うことでVRAMのアクセス先番地を設定
    ldx #$00
    ldy #$20
copypal:
    lda palettes, x ; palettes + xの値をaへロード
    sta $2007 ; VRAMへデータ書き込み実行
    inx ; xインクリメント
    dey ; yデクリメント
    bne copypal ; yデクリメントの結果0にならなかったらcopypalに戻る

; マップ情報を表示
    ; mapをネームテーブル0へ
    lda #$00
    sta <z_name_index
    lda #<map
    sta <z_map_low
    lda #>map
    sta <z_map_high
    jsr drawchip

    ; 描画位置の右端座標
    lda #$20
    sta z_current_left_high
    lda #$00
    sta z_current_left_low

; BGのスクリーン表示位置設定左上にぴったり(スクロール設定)
    lda #$00
    sta z_x
    sta $2005
    sta $2005

; スクリーンオン
    lda #%11001000 ; NMI実行あり,BGのキャラクタテーブル番号を1に
    sta $2000
    lda #%00001110 ; スプライト表示,BG表示,左端8x8のスプライト表示,左端8x8のBG表示
    sta $2001

; 初期表示
    lda #$00
    sta z_frame_processed

; ---------------------------------------------------------------------------------
; 無限ループ
infinity_loop:

    ; 処理済のフレームかチェック
    lda z_frame_processed
    bne infinity_loop ; 1なら処理済

    lda #$01
    sta z_auto_move ; 自動移動中かの判定 一旦onに

    ; きりの良いところまで移動するまで待機
    ; ストライプ左上の座標で判断
    lda z_x ; x座標
    ; 0-3bitが0ならキリがよい
    and #%00001111
    bne bgmove ; キー入力判定は行わず、直前の入力を参考にbg移動処理

    lda z_y ; x座標
    ; 0-3bitで0ならキリがよい
    and #%00001111
    bne bgmove ; キー入力判定は行わず、直前の入力を参考にbg移動処理

    lda #$00
    sta z_auto_move ; 自動移動中では無いのでoff


    ;lda $0703 ; x座標
    ; コントローラー1入力取得
    ; パッドI/Oレジスタの初期化($4016に1,0の順で書き込むのが作法)
    lda #$01
    sta $4016
    lda #$00 
    sta $4016

    ; Aボタンから右ボタンまで取得
    ldx #$08
keycheck_loop:
    ; コントローラー1 パッド入力チェック(2コンは$4017)
    lda $4016
    lsr ; 論理右シフト Aの0bit目がCに設定される
    rol z_controller_1 ; Cの値を0bit目に詰めつつ左ローテート
    dex
    bne keycheck_loop ; 8個読み取るまでループ
    
    cmp z_controller_1
    beq infinity_loop ; なにも押されていないならばループに戻る
    
    ; 以降変更なし
    ; bit:キー
    ; 7:A
    ; 6:B
    ; 5:SELECT
    ; 4:START
    ; 3:UP
    ; 2:DOWN
    ; 1:LEFT
    ; 0:RIGHT

bgmove:
;UPKEYdown
    lda #%00001000
    and z_controller_1
    beq keycheck_down ; 結果が0なら押されてない判定

    ; スクロール指示
    lda #%00000010
    sta z_frame_operation
    
    ; y座標を1引く
    lda z_y
    sec
    sbc #$01
    sta z_y
    bcs keycheck_down ; ボローが発生しなければそのまま処理
    
    inc z_debug
    ; ボローしたらname_table切り替え
    lda z_name_index
    eor #$02
    sta z_name_index
    ; y座標を一番下に
    lda #$ef
    sta z_y


keycheck_down:
;DOWNKEYdown:
    lda #%00000100
    and z_controller_1
    beq keycheck_left ; 結果が0なら押されてない判定
    
    ; スクロール指示
    lda #%00000010
    sta z_frame_operation

    ; y座標を1足す
    inc z_y
    lda z_y
    cmp #$f0 ; yの最大を超えているかチェック    
    bcc keycheckend ; 超えていなければOK
    
    ; キャリーしたらname_table切り替え z_xは自動的に$00になるのでリセット不要
    lda z_name_index
    eor #$02
    sta z_name_index

    lda #$00
    sta z_y ; y座標をリセット
    jmp keycheckend

keycheck_left:
;LEFTKEYdown:
    lda #%00000010
    and z_controller_1
    beq keycheck_right

    ; スクロール指示
    lda #%00000010
    sta z_frame_operation

    lda z_auto_move
    bne keycheck_l_scroll ; きりのよいところからの移動でなければスクロールのみ
    
    ; きりのよい座標から左に移動する場合はメモリーに次に表示する内容を展開
    jsr load_left
    
    ; スクロールと描画指示
    lda #%00000011
    sta z_frame_operation

keycheck_l_scroll:
    ; x座標を1引く
    lda z_x
    sec
    sbc #$01
    sta z_x
    bcs keycheckend ; ボローが発生しなければそのまま処理
    
    ; ボローしたらname_table切り替え z_xは自動的に$ffになるのでリセット不要
    lda z_name_index
    eor #$01
    sta z_name_index
    jmp keycheckend
    
keycheck_right:
;RIGHTKEYdown:
    lda #%00000001
    and z_controller_1
    beq keycheckend

    ; スクロール指示
    lda #%00000010
    sta z_frame_operation

    lda z_auto_move
    bne keycheck_r_scroll ; きりのよいところからの移動でなければスクロールのみ
    
    ; きりのよい座標から右に移動する場合はメモリーに次に表示する内容を展開
    jsr load_right
    
    ; スクロールと描画指示
    lda #%00000011
    sta z_frame_operation

keycheck_r_scroll:
    ; x座標を1足す
    lda z_x
    clc
    adc #$01 ; #$08に変更すれば8倍速でスクロール
    sta z_x
    bcc keycheckend ; キャリーしていなければそのまま処理
    
    ; キャリーしたらname_table切り替え z_xは自動的に$00になるのでリセット不要
    lda z_name_index
    eor #$01
    sta z_name_index
    jmp keycheckend

keycheckend:

	; 表示するネームテーブル番号(bit1~0)をセットする
    ; 末尾がネームテーブル 0:$2000,1:$2400
    lda #%11001000 ;bi2:PPUインクリメント+1
    ;lda #%11001100 ;bi2:PPUインクリメント+32 ; これを変更すると表示が崩れる気がする
    ora z_name_index
    sta z_2000
    
    lda #$01
    sta z_frame_processed

    jmp infinity_loop

.endproc


; ---------------------------------------------------------------------------
; 左側方向のマップ情報を取得
.proc load_left

    ; 先にworld座標を1減算し、表示したいインデックスに移動しておく
    lda z_world_x
    bne dec_world_x; 0でなければ引く余地あり
    ; 0まで達していたら2f
    lda #$2f
    sta z_world_x
    jmp world_end
    
dec_world_x:
    dec z_world_x

world_end:
    lda z_world_x
    ; マップ読み込み開始位置を指定し、マップロード
    sta z_load_index
    jsr load_vetrical
    
    ; 書き込み開始位置判定
    ; 先にlowを2引く
    lda z_current_left_low
    bne sub2 ; 0でなければ素直に2引く
    ; 0なら$1eでリセット
    lda #$1e
    sta z_current_left_low
    ; highも変更
    ; 現在のhighを参照 $20なら$24, $24なら$20に書き込む
    lda z_current_left_high
    eor #%00000100
    sta z_current_left_high
    jmp subend

sub2:
    dec z_current_left_low
    dec z_current_left_low

subend:
    ; 描画座標確定
    lda z_current_left_high
    sta z_name_high
    lda z_current_left_low
    sta z_name_low

    rts
.endproc

; ---------------------------------------------------------------------------
; 右側方向のマップ情報を取得
.proc load_right
    ; 読み出したいxインデックス判定
    ; 座標を1加算
    clc
    lda z_world_x
    adc #$10 ; 現在xから16先の情報が必要
    cmp #$30 ; マップ右側に達していなければそのまま処理
    bcc skip_over
    ; マップインデックスオーバーの場合はオーバー分を減じる
    sec
    sbc #$30
skip_over:
    ; ロード位置を指定しメモリにマップロード
    sta z_debug
    sta z_load_index
    jsr load_vetrical
    
    ; 書き込み開始位置判定
    ; 現在のhighを参照 $20なら$24, $24なら$20に書き込む
    lda z_current_left_high
    eor #%00000100
    sta z_name_high
    ; lowはそのまま
    lda z_current_left_low
    sta z_name_low
    
    ; currentの座標を2進める
    clc
    adc #$02
    cmp #$20
    sta z_current_left_low
    bcc skip_left_reest ; $20を超えてなければそのまま

    ; $20を超えたら0リセット
    lda #$00
    sta z_current_left_low
    ; highを切り替え($20->$24, $24->$20)
    lda z_current_left_high
    eor #%00000100
    sta z_current_left_high

skip_left_reest:

    ; 座標を1加算
    inc z_world_x
    lda z_world_x
    cmp #$30 ; マップ右側に達していたらリセット
    bcc skip
    lda #$00
skip:
    sta z_world_x

    rts
.endproc


; ---------------------------------------------------------------------------
; z_load_indexで指定された箇所の垂直地図情報を取得する
.proc load_vetrical
    ; 読み出し座標取得
    lda z_load_index
    and #%00000111
    sta z_tmp ; 下位ビットがビットシフト数
    inc z_tmp
    lda z_load_index
    and #%11111000 ; 上位ビットがmapのインデックス
    lsr ; 3つビットシフト
    lsr
    lsr
    sta z_index ; マップの開始indexを退避

    ; 書き込んだインデックスリセット
    lda #$00
    sta z_map_index

    ; 取得するチップ数
    ldy #$0f
load_chip:
    ldx z_index ; マップ読み込みインデックス復元
    lda map, x
    ldx z_tmp
shift_chip:
    asl ; ビットシフト
    dex
    bne shift_chip
    ; Cにマップの情報が入っている
    bcc floor
    
    ; 壁
    ldx z_map_index
    lda #$04
    sta w_map, x
    inx
    lda #$05
    sta w_map, x
    inx
    lda #$06
    sta w_map, x
    inx
    lda #$07
    sta w_map, x
    inx
    jmp end_chip

floor: ; 全てのチップが$01なので、4回書き込む
    ldx z_map_index
    lda #$01
    sta w_map, x
    inx
    sta w_map, x
    inx
    sta w_map, x
    inx
    sta w_map, x
    inx

end_chip:
    ; 書き込みインデックスを保存
    stx z_map_index
    ; mapのインデックを6進める
    inc z_index
    inc z_index
    inc z_index
    inc z_index
    inc z_index
    inc z_index
    dey
    bne load_chip ;必要数チップを披露
    
    ; メモリへのマップ展開終了
    rts

.endproc


; ---------------------------------------------------------------------------
; ソースを別ファイルに記載し.includeで取り込める
;.include "drawchip.asm"
.proc drawchip
    ; 書き込み開始座標指定
    lda z_name_index
    bne name1
    ; ネームテーブル0描画
    lda #$20
    jmp drawstart

name1:
    lda #$24

drawstart:
    sta $2006
    lda #$00
    sta $2006

    ; ループカウンタ
    ldx #$00
    ldy #$0f
maploop:
    ; サブルーチンでyを書き換えるので、現在のy値をメモリーに退避
    sty z_index

    ; マップ情報を読み込みメモリーに退避(16-y行目左側)
    txa
    tay
    lda (z_map_low), y
    sta z_chip
    ; z_chipを情報を解析して書き込み
    jsr drawChipUp
    inx

    ; マップ情報を読み込みメモリーに退避(16-y行目右側)
    txa
    tay
    lda (z_map_low), y
    sta z_chip
    ; z_chipを情報を解析して書き込み
    jsr drawChipUp
    dex ; 一つ前に戻す
    
    ; マップ情報を読み込みメモリーに退避
    txa
    tay
    lda (z_map_low), y ; (16-y行目左側)
    sta z_chip
    jsr drawChipLow
    inx
    
    txa
    tay
    lda (z_map_low), y ; (16-y行目右側)
    sta z_chip
    jsr drawChipLow
    inx
    
    ; インデックスを飛ばす
    inx
    inx
    inx
    inx

    ; yの値が書き換わっているのでメモリーから復帰
    ldy z_index
    dey
    bne maploop

    rts


; map情報から画面表示(16x16の上半分)
drawChipUp:
    ; 1bit単位で0なら通路、1なら壁)
    ldy #$08
loopup:
    ; map情報の断片をロード
    lda z_chip
    ; bit演算した結果を出力BGデータでで 0は床、1は壁のパネルを設定している
    and #%10000000
    beq floorup ; 0なら床
    jmp wallup

floorup:
    lda #$01
    sta $2007
    lda #$01
    sta $2007
    jmp finup

wallup:
    lda #$04
    sta $2007
    lda #$05
    sta $2007
    
finup:
    ; 左ローテート
    rol z_chip
    dey
    bne loopup
    ;jmp draw8chipr ; ルーチンが近い場合はjmpしてみるテスト
    rts



; map情報から画面表示(16x16の下半分)
drawChipLow:
    ; 1bit単位で0なら通路、1なら壁)
    ldy #$08
looplow:
    ; map情報の断片をロード
    lda z_chip
    ; bit演算した結果を出力BGデータでで 0は床、1は壁のパネルを設定している
    and #%10000000
    beq floorlow ; 0なら床
    jmp walllow

floorlow:
    lda #$01
    sta $2007
    lda #$01
    sta $2007
    jmp finlow

walllow:
    lda #$06
    sta $2007
    lda #$07
    sta $2007
    
finlow:
    ; 左ローテート
    rol z_chip
    dey
    bne looplow
    ;jmp draw8chipr ; ルーチンが近い場合はjmpしてみるテスト
    rts
.endproc


; ---------------------------------------------------------------------------
.proc mainloop
    ; NMIによる割り込み処理に変更したのでチェック不要
    ;lda $2002 ; VBlankが発生すると、$2002の7ビット目が1になります。
    ;bpl mainloop ; bit7が0の間は、mainLoopラベルの位置に飛んでループして待ち続けます。

    ; VBlank中に値を書き換えると、呼び出し元の処理が壊れるので一旦退避
    ; これで様子見
    pha ; Aをスタックに
    txa ; X -> A
    pha ; A(=X)をスタックに
    tya ; Y -> A
    pha ; A(=Y)をスタックに
    php ; ステータスをスタックに


    inc z_frame ; タイマーカウントアップ
    lda z_frame_processed
    ; まだ準備できていなければスキップ
    beq bvlank_end

    ; 描画指示読み取り
    lda z_frame_operation
    beq bvlank_end ; 特に操作がなければ終了

; ---- BG/スクロール共通の処理
	; 表示するネームテーブル番号(bit1~0)をセットする
    ; 末尾がネームテーブル 0:$2000,1:$2400

    lda z_frame_operation
    lsr ; bit0読み取り
    bcc scroll ; BG描画指示がなければスクロール

    ; BG描画
    ldy #$0f
    ldx #$00
write_bg:
    lda z_name_high
    sta $2006
    lda z_name_low
    sta $2006
    lda w_map, x
    sta $2007
    inx
    lda w_map, x
    sta $2007
    inx

    lda z_name_low
    clc
    adc #$20
    sta z_name_low

    lda z_name_high
    sta $2006
    lda z_name_low
    sta $2006

    lda w_map, x
    sta $2007
    inx 
    lda w_map, x
    sta $2007

    ; 次に描画するインデックス準備
    ; ここでキャリーが発生する可能性がある
    lda z_name_low
    clc
    adc #$20
    sta z_name_low
    bcc not_inc_high ; キャリーが発生しなかったらそのままｆ
    ; キャリーしたらhightを1進める
    inc z_name_high
not_inc_high:
    inx
    dey
    bne write_bg
    


scroll:
    lda z_frame_operation
    lsr ; bit1読み取り
    lsr
    bcc bvlank_end ; スクロール指示がなければ終了


    lda z_2000
    sta $2000

    ; スクロール実行
    ; スクロール位置リセット
    lda $2002

    ; スクロール実行
    lda z_x
    sta $2005
    lda z_y
    sta $2005

bvlank_end:
    ; 描画済にフラグを更新
    lda #$00
    sta z_frame_processed
    sta z_frame_operation


    ; 退避した値を復帰
    ; 戻すときはスタックに積んだのと逆順で
    plp ; ステータス
    pla
    tay ; Y
    pla
    tax ; X
    pla ; A
    
    rti ; VBlank割り込みから復帰 ここでは何も行わず、後の流れのrtiで処理しても良さそう
.endproc

; ハード、ソフトウェア割り込み
.proc irq
    rti
.endproc

; パレットテーブル
palettes:
    ; BG
    .byte $0f, $05, $00, $10
    .byte $0f, $16, $16, $26
    .byte $0f, $00, $18, $28
    .byte $0f, $0a, $10, $2a
    ; スプライト
    .byte $0f, $00, $10, $39
    .byte $0f, $16, $16, $26
    .byte $0f, $00, $18, $28
    .byte $0f, $0a, $10, $2a

; マップ情報
map:
    .byte %10000000, %00000001, %10000000, %00000001, %10000000, %00000001
    .byte %00000000, %00000000, %10000000, %00000001, %10000000, %00000001
    .byte %00000000, %00000000, %00000000, %00000000, %10000000, %00000001
    .byte %00000001, %11000000, %00000111, %11000000, %00000111, %11110000
    .byte %00000000, %10000000, %00000010, %10000000, %00000010, %10100000
    .byte %00000000, %10000000, %00000010, %10000000, %00000010, %10100000
    .byte %00000000, %10000000, %00000010, %10000000, %00000010, %10100000
    .byte %00000000, %10000000, %00000010, %10000000, %00000010, %10100000
    .byte %00000000, %10000000, %00000010, %10000000, %00000010, %10100000
    .byte %00000000, %10000000, %00000010, %10000000, %00000010, %10100000
    .byte %00000000, %10000000, %00000010, %10000000, %00000010, %10100000
    .byte %00000001, %11000000, %00000111, %11000000, %00000111, %11110000
    .byte %00000000, %00000000, %00000000, %00000000, %10000000, %00000001
    .byte %00000000, %00000000, %10000000, %00000001, %10000000, %00000001
    .byte %10000000, %00000001, %10000000, %00000001, %10000000, %00000001

; 参照のアドレスを指定できるかテスト
maprow:
    .word map

; 変数定義
.org $0000 ; ゼロページ領域
z_frame: .byte $00 ; VBlank毎にカウントアップ
z_frame_processed: .byte $00 ; 描画準備ができているか0:未処理、1:準備済
z_frame_operation: .byte $00 ; VBlank中にやってほしいこと bit0:スクロール bit1:描画
z_controller_1: .byte $00 ; コントローラー1入力
z_chip: .byte $00   ; 処理中のマップ情報
z_index: .byte $00  ; ループカウンタ値保存用
z_name_index: .byte $00 ; 対象ネームテーブルの番号0/1
z_map_low: .byte $00 ; 読み込みマップのアドレス
z_map_high: .byte $00 
; -- 09 --
z_x: .byte $00 ; スクロールx
z_y: .byte $00 ; スクロールy
z_world_x: .byte $00 ; 絶対座標x
z_auto_move: .byte $00 ; 自動移動中かの判定
z_2000: .byte $00 ; スクロール用
z_name_high: .byte $00
z_name_low: .byte $00
; -- 10 --
z_current_left_high: .byte $00 ; 現在左側の座標情報(high)
z_current_left_low: .byte $00 ; 現在左側の座標情報(low)
z_load_index: .byte $00 ; ロードするマップ座標
z_map_index: .byte $00 ; マップ読み込み時の退避領域
z_tmp: .byte $00
; スタック領域は$0100~$01ff

.org $0050
z_debug: .byte $00

.org $0200 ; ワークエリア
w_map: .byte $00
; $07000以降はスプライトDMAで予約

.segment "VECINFO"
    .word mainloop ; VBlank割り込み時に実行するルーチン
    .word reset ; リセット割り込み
    .word irq ; ハードウェア割り込みとソフトウェア割り込み

; パターンテーブル
.segment "CHARS"
    .incbin "downlad.chr"
