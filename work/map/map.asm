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
    ; 初期mapをネームテーブル0へ
    jsr load_map

    ; 描画位置の右端座標
    lda #$00
    sta z_x
    sta z_y

; BGのスクリーン表示位置設定左上にぴったり(スクロール設定)
    lda #$00
    sta $2005
    sta $2005

; スクリーンオン
    lda #%11001000 ; NMI実行あり,BGのキャラクタテーブル番号を1に
    sta $2000
    lda #%00001110 ; スプライト表示,BG表示,左端8x8のスプライト表示,左端8x8のBG表示
    sta $2001

    lda #$00
    sta z_frame_processed
; ---------------------------------------------------------------------------------
; 無限ループ
infinity_loop:
    jsr main_loop
    jmp infinity_loop

.endproc

; ---------------------------------------------------------------------------
; VBlank外での処理
.proc main_loop

    ; 処理済のフレームかチェック
    lda z_frame_processed
    beq proc1 ; 1なら処理済
    rts

proc1:

    lda #$01
    sta z_auto_move ; 自動移動中かの判定 一旦onに

    ; きりの良いところまで移動するまで待機
    ; ストライプ左上の座標で判断
    lda z_x ; x座標
    ; 0-3bitが0ならキリがよい
    and #%00001111
    bne proc2 ; キー入力判定は行わず、直前の入力を参考にbg移動処理

    lda z_y ; x座標
    ; 0-3bitで0ならキリがよい
    and #%00001111
    bne proc2 ; キー入力判定は行わず、直前の入力を参考にbg移動処理

    lda #$00
    sta z_auto_move ; 自動移動中では無いのでoff

    ; キー入力取得
    jsr collect_input
    cmp z_controller_1
    bne proc2 ; 何か押されていたら判定処理

    rts ; 何も押されてなければ処理終了

proc2:
    ; キー入力のビット
    ; bit:キー
    ; 7:A
    ; 6:B
    ; 5:SELECT
    ; 4:START
    ; 3:UP
    ; 2:DOWN
    ; 1:LEFT
    ; 0:RIGHT


; 上キー入力チェック
    lda #%00001000
    and z_controller_1
    beq keycheck_down ; 押されてなければ下キーチェック

    jsr move_up
    jmp keycheckend


; 下キー入力チェック
keycheck_down:
    lda #%00000100
    and z_controller_1
    beq keycheck_left ; 押されてなければ左キーチェック

    jsr move_down
    jmp keycheckend


; 左キー入力チェック    
keycheck_left:
    lda #%00000010
    and z_controller_1
    beq keycheck_right ; 押されてなければ右キーチェック

    jsr move_left
    jmp keycheckend

; 右キー入力チェック
keycheck_right:
    lda #%00000001
    and z_controller_1
    beq keycheckend ; 押されてなければ処理終了

    jsr move_right

keycheckend:

	; 表示するネームテーブル番号(bit1~0)をセットする
    ; 末尾がネームテーブル 0:$2000,1:$2400
    lda #%11001000 ;bi2:PPUインクリメント+1
    ;lda #%11001100 ;bi2:PPUインクリメント+32 ; これを変更すると表示が崩れる気がする
    ora z_name_index
    sta z_2000

    ; 処理済としてマーク
    lda #$01
    sta z_frame_processed
    rts
.endproc


; ---------------------------------------------------------------------------
; 上方向への移動
.proc move_up
    ; スクロール指示
    lda #%00000100
    sta z_frame_operation

    lda z_auto_move
    bne keycheck_scroll ; きりのよいところからの移動でなければスクロールのみ

    ; きりのよい座標から上に移動する場合はメモリーに次に表示する内容を展開
    ; 現在y座標から1引く
    lda z_world_y
    sta z_arg1
    jsr sub_y1

    ; 減算結果をy座標指定
    lda z_return
    sta z_arg2
    sta z_debug
    
    ; xは現在座標
    lda z_world_x
    sta z_arg1

    ; 水平方向にマップロード
    jsr load_horizontal
    

    ; y座標を1引く
    lda z_world_y
    sta z_arg1
    jsr sub_y1
    lda z_return
    sta z_world_y

    ; 対象ネームテーブルhighを確定
    lda #$01
    bit z_name_index
    beq name0 ; bit0が1ならname1
    jmp name1

name0:
    lda #$20
    sta z_name_high
    jmp name_low

name1:
    lda #$24
    sta z_name_high

name_low:
    ; name_lowを判定
    jsr get_screen_y
    lda z_return
    sec
    sbc #$01
    bcs no_borrow
    lda #$0e ;ボローが起きたときはyリセット

no_borrow:
    tay
    lda #$00
loop:
    clc
    adc #$40
    ; $40足してキャリーしなければ次のループ
    bcc next
    ; キャリーしたらhighを加算
    inc z_name_high
next:
    dey
    bne loop
    
    sta z_name_low

    ; x座標の補正
    jsr ajust_x

    ; スクロールと描画指示(H)
    lda #%00000110
    sta z_frame_operation


keycheck_scroll:
    ; y座標を1引く
    lda z_y
    sec
    sbc #$01
    sta z_y
    bcs keycheckend ; ボローが発生しなければそのまま処理
    
    ; ボローしたらname_table切り替え
    lda z_name_index
    eor #$02
    sta z_name_index
    ; y座標を一番下に
    lda #$ef
    sta z_y

keycheckend:

    rts
.endproc



; ---------------------------------------------------------------------------
; 下方向への移動
.proc move_down
    ; スクロール指示
    lda #%00000100
    sta z_frame_operation

    lda z_auto_move
    bne keycheck_scroll ; きりのよいところからの移動でなければスクロールのみ

    ; きりのよい座標から下に移動する場合はメモリーに次に表示する内容を展開
    ; 現在y座標から15足す
    lda z_world_y
    sta z_arg1
    lda #$0f
    sta z_arg2
    jsr append_y

    ; 減算結果をy座標指定
    lda z_return
    sta z_arg2
    
    ; xは現在座標
    lda z_world_x
    sta z_arg1

    ; 水平方向にマップロード
    jsr load_horizontal
    

    ; y座標を1増加
    lda z_world_y
    sta z_arg1
    lda #$01
    sta z_arg2
    jsr append_y
    lda z_return
    sta z_world_y

    ; 対象ネームテーブルhighを確定
    lda #$01
    bit z_name_index
    beq name0 ; bit0が1ならname1
    jmp name1

name0:
    lda #$20
    sta z_name_high
    jmp name_low

name1:
    lda #$24
    sta z_name_high

name_low:
    ; name_lowを判定
    ; 現在yが書き込み対象(ここからいなくなるので)
    jsr get_screen_y
    ldy z_return
    lda #$00
loop:
    clc
    adc #$40
    ; $40足してキャリーしなければ次のループ
    bcc next
    ; キャリーしたらhighを加算
    inc z_name_high
next:
    dey
    bne loop
    
    sta z_name_low

    ; x座標の補正
    jsr ajust_x

    ; スクロールと描画指示(H)
    lda #%00000110
    sta z_frame_operation


keycheck_scroll:
    ; y座標を1足す
    inc z_y
    lda z_y
    cmp #$f0 ; yの最大を超えているかチェック    
    bcc keycheckend ; 超えていなければOK
    
    ; name_table切り替え
    lda z_name_index
    eor #$02
    sta z_name_index

    lda #$00
    sta z_y ; y座標をリセット

keycheckend:

    rts
.endproc

; x座標分の補正
.proc ajust_x
    jsr get_screen_x
    lda z_return
    clc
    adc z_return
    clc
    adc z_name_low
    ; 書き込みlow確定
    sta z_name_low

    rts
.endproc

; ---------------------------------------------------------------------------
; 左方向への移動
.proc move_left

    ; スクロール指示
    lda #%00000100
    sta z_frame_operation

    lda z_auto_move
    bne keycheck_scroll ; きりのよいところからの移動でなければスクロールのみ
    
    ; きりのよい座標から左に移動する場合はメモリーに次に表示する内容を展開
    ; 現在座標から1つ戻す
    lda z_world_x
    sta z_arg1
    jsr sub_x1
    ; 減算結果をx座標指定
    lda z_return
    sta z_arg1
    
    
    ; yは現在座標
    lda z_world_y
    sta z_arg2
    ; 指定座標から垂直標高のマップをメモリにデータロード
    jsr load_vetrical

    ; データ書き込み位置を判定
    ; 左側への描画は現在値xが0の場合のみ反対側になる
    jsr get_screen_x
    lda z_return
    sec
    sbc #$01
    bcc turn_name ; ボローが発生しなければそのまま処理

    ; 現在と同じネームテーブルに書き込む
    sta z_name_low
    ; bit0でどちらのテーブルか判定
    lda #$01
    bit z_name_index
    beq name0 ; bit0が1ならname1
    jmp name1

turn_name:
    lda #$0f
    sta z_name_low
    ; bit0でどちらのテーブルか判定
    lda #$01
    bit z_name_index
    beq name1
    jmp name0

name0:
    lda #$20
    jmp set_name_high
name1:
    lda #$24
    jmp set_name_high

set_name_high:
    sta z_name_high

    ; 座標は16pxで1と計算している
    ; 書き込みx座標は8pxで1増加するので2倍する
    lda z_name_low
    clc
    adc z_name_low
    ; 書き込みlow確定
    sta z_name_low

    ; y座標分の補正
    jsr ajust_y

    ; 座標を引く
    lda z_world_x
    sta z_arg1
    jsr sub_x1
    ; 加算結果をx座標指定
    lda z_return
    sta z_world_x
    
    ; スクロールと描画指示(V)
    lda #%00000101
    sta z_frame_operation

keycheck_scroll:
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

keycheckend:

    rts
.endproc

; ---------------------------------------------------------------------------
; 右方向への移動
.proc move_right

    ; スクロール指示
    lda #%00000100
    sta z_frame_operation

    lda z_auto_move
    bne keycheck_scroll ; きりのよいところからの移動でなければスクロールのみ
    
    ; きりのよい座標から右に移動する場合はメモリーに次に表示する内容を展開
    ; 現在座標から16先の座標を指定
    lda z_world_x
    sta z_arg1
    lda #$10
    sta z_arg2
    ; xを参照した結果を得る
    jsr append_x
    ; 加算結果をx座標指定
    lda z_return
    sta z_arg1
    ; yは現在座標
    lda z_world_y
    sta z_arg2
    ; 指定座標から垂直標高のマップをメモリにデータロード
    jsr load_vetrical

    ; データ書き込み位置を判定
    ; 右側への描画は常に現在のネームテーブルと反対側
    ; bit0でどちらのテーブルか判定
    lda #$01
    bit z_name_index
    beq name1 ; bit0が0ならname1
    lda #$20 ; bit0が1ならname0
    jmp set_name_high
name1:
    lda #$24
set_name_high:
    sta z_name_high

    ; 座標は16pxで1と計算している
    ; 書き込みx座標は8pxで1増加するので2倍する
    jsr get_screen_x
    lda z_return
    clc
    adc z_return
    ; 書き込みlow確定
    sta z_name_low

    ; y座標分の補正
    jsr ajust_y

    ; 座標を進める
    lda z_world_x
    sta z_arg1
    lda #$01
    sta z_arg2
    ; xを参照した結果を得る
    jsr append_x
    ; 加算結果をx座標指定
    lda z_return
    sta z_world_x
    
    ; スクロールと描画指示(V)
    lda #%00000101
    sta z_frame_operation

keycheck_scroll:
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

keycheckend:

    rts
.endproc

; y座標分の補正
.proc ajust_y
    ; 現在yが書き込み対象
    jsr get_screen_y
    ldy z_return
    lda z_name_low
loop:
    clc
    adc #$40
    ; $40足してキャリーしなければ次のループ
    bcc next
    ; キャリーしたらhighを加算
    inc z_name_high
next:
    dey
    bne loop
    
    sta z_name_low
    rts
.endproc


; ---------------------------------------------------------------------------
; オーバーフローを考慮しx座標に加算
; arg1: 加算対象のx座標, arg2: 加算する数
.proc append_x
    lda z_arg1
    clc
    adc z_arg2
    cmp #$30 ; マップ右側に達していたらリセット
    bcc skip
    sec
    sbc #$30
skip:
    sta z_return
    rts
.endproc

; オーバーフローを考慮しx座標から1減算
; arg1: 減算対象のx座標
.proc sub_x1
    lda z_arg1
    sec
    sbc #$01
    bcs skip ; ボローが発生しなければそのまま処理

    lda #$2f ; マップ左側に達していたらリセット

skip:
    sta z_return
    rts
.endproc


; ---------------------------------------------------------------------------
; オーバーフローを考慮しy座標に加算
; arg1: 加算対象のx座標, arg2: 加算する数
.proc append_y
    lda z_arg1
    clc
    adc z_arg2
    cmp #$1e ; マップ右側に達していたらリセット
    bcc skip
    sec
    sbc #$1e
skip:
    sta z_return
    rts
.endproc

; オーバーフローを考慮しy座標から1減算
; arg1: 減算対象のx座標
.proc sub_y1
    lda z_arg1
    sec
    sbc #$01
    bcs skip ; ボローが発生しなければそのまま処理

    lda #$1d ; マップ左側に達していたらリセット

skip:
    sta z_return
    rts
.endproc


; ---------------------------------------------------------------------------
.proc get_screen_x
    lda z_x
    lsr
    lsr
    lsr
    lsr
    sta z_return
    rts
.endproc

; ---------------------------------------------------------------------------
.proc get_screen_y
    lda z_y
    lsr
    lsr
    lsr
    lsr
    sta z_return
    rts
.endproc

; ---------------------------------------------------------------------------
; キー入力の取得
.proc collect_input
    
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

    rts
.endproc


; ---------------------------------------------------------------------------
; 初期マップの表示
.proc load_map
    ;描画の開始座標設定
    lda #$20
    sta z_name_high
    lda #$00
    sta z_name_low

    ; 読み込み開始y設定
    lda #$00
    sta z_arg2

vetrical:
    ; 読み込み開始x設定
    lda #$00
    sta z_arg1
    jsr load_horizontal
    ; メモリに展開した内容描画
    jsr bg_write_horizontal

    lda z_name_low
    clc
    adc #$40
    sta z_name_low
    bcs inc_high
    jmp end

inc_high:
    ; キャリーしたらhight1進める
    inc z_name_high

end:

    ; y座標を1進める
    inc z_arg2
    lda z_arg2
    cmp #$0f
    bcc vetrical

    rts
.endproc



; ---------------------------------------------------------------------------
; 指定座標から横16の情報を読み取り、w_mapに設定
; arg1: x座標, arg2:y座標
.proc load_horizontal
    lda #$00
    sta z_counter1

    lda #$10
    sta z_counter2
load:
    ; 対象座標のデータ取得
    jsr get_chip
    lda z_return
    beq floor; 0なら床
    ; 1なら壁
    ; 1列目
    ldx z_counter1
    lda #$04
    sta w_map, x
    inx

    lda #$05
    sta w_map, x
    inx
    
    ; 2列目
    lda #$06
    sta w_map, x
    inx

    lda #$07
    sta w_map, x
    inx
    stx z_counter1
    jmp end

floor:
    ; 0なら床 データは全て$01
    ; 1列目
    lda #$01
    ldx z_counter1
    sta w_map, x
    inx

    sta w_map, x
    inx

    ; 2列目
    sta w_map, x
    inx

    sta w_map, x
    inx
    stx z_counter1
    jmp end

end:
    ; x座標を1進める
    inc z_arg1
    ; @todo 右端をオーバーしたら0リセット
    dec z_counter2
    lda z_counter2
    bne load
    
    rts
.endproc


; ---------------------------------------------------------------------------
; 指定座標から縦15の情報を読み取り、w_mapに設定
; arg1: x座標, arg2:y座標
.proc load_vetrical
    lda #$00
    sta z_counter1

    lda #$0f
    sta z_counter3
load:
    ; 対象座標のデータ取得
    jsr get_chip
    lda z_return
    beq floor; 0なら床
    ; 1なら壁
    ; 1列目
    ldx z_counter1
    lda #$04
    sta w_map, x
    inx
    lda #$05
    sta w_map, x
    inx

    ; 2列目
    lda #$06
    sta w_map, x
    inx
    lda #$07
    sta w_map, x
    inx
    stx z_counter1
    jmp end

floor:
    ; 0なら床 データは全て$01
    ; 1列目
    lda #$01
    ldx z_counter1
    sta w_map, x
    inx
    sta w_map, x
    inx

    ; 2列目
    sta w_map, x
    inx
    sta w_map, x
    inx
    stx z_counter1
    jmp end

end:
    ; y座標を1進める
    inc z_arg2
    ; @todo 右端をオーバーしたら0リセット
    dec z_counter3
    lda z_counter3
    bne load

    rts
.endproc

; ---------------------------------------------------------------------------
; 指定座標の情報を読み取り、z_returnに設定
; arg1: x座標, arg2:y座標
.proc get_chip
    ; y座標を読み込み
    ldy #$06
    lda #$00
mul: ;y * 6 = yを6回足せば良い
    clc
    adc z_arg2
    dey
    bne mul
    ; 読み出し開始位置y
    sta z_tmp1

    ; 読み出しx座標取得
    lda z_arg1
    and #%00000111
    sta z_tmp2 ; 下位ビットが初期ビットシフト数
    lda z_arg1
    and #%11111000 ; 上位ビットがmapのインデックス
    lsr ; 3つビットシフト
    lsr
    lsr
    ; 退避しておいたy開始にxを加算
    clc
    adc z_tmp1
    sta z_tmp1 ; 最終的なマップの開始indexを退避
    
    ; 対象のマップ情報があるデータをロード
    ldy z_tmp1
    lda map, y

    ; ビットシフト実行
    ldx #$00
seek:
    cpx z_tmp2
    beq found ; 該当ビット発見
    inx
    asl
    jmp seek

found:
    asl
    bcc floor ; 0の場合は床

    ; 1の場合は壁
    lda #$01
    jmp end

floor:
    lda #$00

end:
    ; 指定座標のマップIDを戻り値として設定
    sta z_return

    rts
.endproc




; ---------------------------------------------------------------------------
; VBlank中に行う処理
; ---------------------------------------------------------------------------
; ---------------------------------------------------------------------------
.proc vblank_loop

    ; VBlank中に値を書き換えると、呼び出し元の処理が壊れるので一旦退避
    ; これで様子見
    pha ; Aをスタックに
    txa ; X -> A
    pha ; A(=X)をスタックに
    tya ; Y -> A
    pha ; A(=Y)をスタックに
    php ; ステータスをスタックに

    inc z_frame ; フレームカウンター
    lda z_frame_processed
    ; まだ準備できていなければスキップ
    beq vblank_end
    
; ---- BG/スクロール共通の処理
	; 表示するネームテーブル番号(bit1~0)をセットする
    ; 末尾がネームテーブル 0:$2000,1:$2400

    lda z_frame_operation
    lsr ; bit0読み取り
    sta z_frame_operation
    bcc check_horizontal ; BG描画(V)指示がなければスクロール

    ; 垂直書き込み
    jsr bg_write_vetrical
    
; 水平書き込み指示チェック
check_horizontal:
    lda z_frame_operation
    lsr ; bit0読み取り
    sta z_frame_operation
    bcc check_scroll ; BG描画(H)指示がなければスクロール

    ; 水平書き込み
    jsr bg_write_horizontal


check_scroll:
    lda z_frame_operation
    lsr ; bit1読み取り
    bcc vblank_end ; スクロール指示がなければ終了

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

vblank_end:
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

; ---------------------------------------------------------------------------
; 水平方向への書き込み
.proc bg_write_horizontal
    ; BG描画
    lda z_name_low
    sta z_tmp1
    sta z_tmp2

    lda #$10
    sta z_counter1

    ldx #$00

write:
    lda z_name_high
    sta $2006
    lda z_tmp1
    sta $2006
    
    ldy #$02
write_bg_up:
    lda w_map, x
    sta $2007
    inx
    dey
    bne write_bg_up


    lda z_name_high
    sta $2006
    lda z_tmp1
    clc
    adc #$20
    sta $2006
    sta z_tmp1

    ldy #$02
write_bg_down:
    lda w_map, x
    sta $2007
    inx
    dey
    bne write_bg_down

    lda z_tmp2
    clc
    adc #$02
    sta z_tmp1
    sta z_tmp2

    ; これでVBlankをオーバーする模様
    ; サブルーチンの中を空にしても画面が崩れた
    ;jsr check_h_over

    dec z_counter1
    lda z_counter1
    bne write

    rts
.endproc

.proc check_h_over
    lda z_tmp2
    and #%00111111
    bne end

    ;超えたら別ネームテーブルに切り替え
    lda z_name_high
    cmp #$24
    bcc turn_name1
    jmp turn_name0

turn_name1:
    lda z_name_high
    clc
    adc #$04
    sta z_name_high
    lda #$00
    sta z_tmp1
    sta z_tmp2
    jmp end

turn_name0:
    lda z_name_high
    sec
    sbc #$04
    sta z_name_high
    lda #$00
    sta z_tmp1
    sta z_tmp2
    jmp end

end:

    rts
.endproc

; ---------------------------------------------------------------------------
; 垂直方向への書き込み
.proc bg_write_vetrical
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

    jsr check_v_over

    inx
    dey
    bne write_bg

    rts
.endproc

.proc check_v_over
    ; 次に描画するインデックス準備
    ; ここでキャリーが発生する可能性がある
    lda z_name_low
    clc
    adc #$20
    sta z_name_low
    bcs inc_high

    lda z_name_low
    cmp #$c0
    bcc end

    lda z_name_high
    cmp #$23
    beq reset_name0
    cmp #$27
    beq reset_name1
    jmp end

reset_name0:
    lda #$20
    sta z_name_high

    lda z_name_low
    sec
    sbc #$c0
    sta z_name_low
    jmp end

reset_name1:
    lda #$24
    sta z_name_high

    lda z_name_low
    sec
    sbc #$c0
    sta z_name_low
    jmp end

inc_high:
    ; キャリーしたらhight1進める
    inc z_name_high

end:
    rts
.endproc

; ハード、ソフトウェア割り込み
.proc irq
    rti
.endproc


; ---------------------------------------------------------------------------
; データ定義
; ---------------------------------------------------------------------------
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

    .byte %10000001, %10000001, %10000000, %00000001, %10000000, %00000001
    .byte %00000000, %00000001, %10000000, %00000001, %10000000, %00000001
    .byte %00000000, %00000000, %00000000, %00000000, %10000000, %00000001
    .byte %00011111, %11111000, %00001111, %11110000, %00011111, %11111000
    .byte %00001010, %00010000, %00000100, %00100000, %00001000, %01010000
    .byte %00001010, %00010000, %00000100, %00100000, %00001000, %01010000
    .byte %00001001, %00100000, %00000100, %00100000, %00000100, %10010000
    .byte %00001001, %00100000, %00000010, %01000000, %00000100, %10010000
    .byte %00001001, %00100000, %00000010, %01000000, %00000100, %10010000
    .byte %00001000, %11000000, %00000001, %10000000, %00000011, %00010000
    .byte %00001000, %11000000, %00000001, %10000000, %00000011, %00010000
    .byte %00011111, %11111000, %00000001, %10000000, %00011111, %11111000
    .byte %10000000, %00000001, %00000000, %00000000, %10000000, %00000001
    .byte %10000000, %00000001, %10000000, %00000001, %10000000, %00000001
    .byte %11110000, %00000111, %10000000, %00000001, %10000000, %00000001

; 参照のアドレスを指定できるかテスト
maprow:
    .word map

; 変数定義
.org $0000 ; ゼロページ領域
z_arg1: .byte $00 ; サブルーチン汎用引数1
z_arg2: .byte $00 ; サブルーチン汎用引数2
z_return: .byte $00 ; サブルーチン戻り値
z_tmp1: .byte $00 ; 計算時のテンポラリ1
z_tmp2: .byte $00 ; 計算時のテンポラリ2
z_counter1: .byte $00 ; 計算時のカウンター1
z_counter2: .byte $00 ; 計算時のカウンター2
z_counter3: .byte $00 ; 計算時のカウンター3

.org $0010
z_frame: .byte $00 ; VBlank毎にカウントアップ
z_frame_processed: .byte $00 ; 描画準備ができているか0:未処理、1:準備済
z_frame_operation: .byte $00 ; VBlank中にやってほしいこと bit0:スクロール bit1:描画
z_controller_1: .byte $00 ; コントローラー1入力
z_x: .byte $00 ; スクロールx
z_y: .byte $00 ; スクロールy
z_world_x: .byte $00 ; 絶対座標x
z_world_y: .byte $00 ; 絶対座標y
z_2000: .byte $00 ; スクロール用
z_auto_move: .byte $00 ; 自動移動中かの判定
z_name_index: .byte $00 ; 現在カーソルのあるネームテーブルの番号0-3
z_name_high: .byte $00 ; 書き込み開始位置high
z_name_low: .byte $00 ; 書き込み開始位置low

.org $0050
z_debug: .byte $00

; スタック領域は$0100~$01ff


.org $0200 ; ワークエリア
w_map: .byte $00
; $07000以降はスプライトDMAで予約

.segment "VECINFO"
    .word vblank_loop ; VBlank割り込み時に実行するルーチン
    .word reset ; リセット割り込み
    .word irq ; ハードウェア割り込みとソフトウェア割り込み

; パターンテーブル
.segment "CHARS"
    .incbin "downlad.chr"
