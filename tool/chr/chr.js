// https://bugzmanov.github.io/nes_ebook/chapter_6_3.html
// プレビュー表示のチップ
const PREVIEW_WIDTH = 16;
const PREVIEW_HEIGHT = 16;
// プレビュー表示 1ドットの表示ピクセル
const PREVIEW_PX = 8;
const PREVIEW_GRID = PREVIEW_PX * 8;

// 編集画面の表示ピクセル
const EDITOR_PX = 32;

// チップ単位でのエンコード、デコード
class Chip {

    constructor() {
        this.rows = [];
    }

    load(view, index) {
        this.rows = [];
        for (let r = index; r < index + 8; r++) {
            const row = [];
            // 8バイト間隔でデータを取得
            let upper = view[r];
            let lower = view[r + 8];

            // ビットを足す
            for (let i = 0; i < 8; i++) {
                let value = (1 & upper) << 1 | (1 & lower);
                upper = upper >> 1;
                lower = lower >> 1;
                // 計算結果を先頭に追加
                row.unshift(value);
            }
            // 1チップの1行分のデータとして追加
            this.rows.push(row);
        }
        return this;
    }

    toArray() {
        const view = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
        if (this.rows.length === 0) {
            return view;
        }
        
        // 現在のrowsを参照してバイナリデータに変換する
        for (let r = 0; r < 8; r++) {
            const row = this.rows[r];
            let upper = 0;
            let lower = 0;
            for (let i = 0; i < 8; i++) {
                let value = row[i]; // 0-3
                upper = upper << 1;
                lower = lower << 1;

                upper += (value & 2) >> 1;
                lower += value & 1;
            }
            view[r] = upper;
            view[r + 8] = lower;
        }
        
        return view;
    }
}

// イベント処理
class EventListener {
    constructor(owner) {
        this.owner = owner;
    }

    previewClick(event) {
        // chip単位で移動させる
        const x = Math.trunc(event.offsetX / PREVIEW_GRID);
        const y = Math.trunc(event.offsetY / PREVIEW_GRID);

        // プレビューのグリッド表示位置を更新
        this.owner.drawPreviewGrid(x, y);        
        
    }
}


// Canvas操作
class CHRCanvas {
    constructor(main, layer) {
        this.main = main;
        this.layer = layer;
        this.mctx = main.getContext('2d');
        this.lctx = layer.getContext('2d');

        this.width = this.main.width;
        this.height = this.main.height;
    }

    clearMain() {
        this.mctx.fillStyle = 'rgb( 0, 0, 0)';
        this.mctx.fillRect(0, 0, this.width, this.height);
    }

    drawPixel(x, y, unit, style) {
        this.mctx.fillStyle = style;
        this.mctx.fillRect(x, y, unit, unit);
    }

    clearLayer() {
        this.lctx.clearRect(0, 0, this.width, this.height);
    }

    setLayerStrokeStyle(lineWidth, strokeStyle) {
        this.lctx.lineWidth = lineWidth;
        this.lctx.strokeStyle = strokeStyle;
    }
    
    strokeLayerRect(x, y, width, height) {
        this.lctx.strokeRect(x, y, width, height);
    }

    fillLayerRect(x, y, width, height, style) {
        this.lctx.fillStyle = style;
        this.lctx.fillRect(x, y, width, height);
    }

}


export class CHR {

    constructor(editor, editorLayer, preview, previewLayer) {
        
        this.editor = new CHRCanvas(editor, editorLayer);
        this.preview = new CHRCanvas(preview, previewLayer);
        
        // 8x8を1chipとして保存
        this.chips = []; // length: 8192, 2048chip
        this.viewPage = 0; // 0 ~ 4
        this.maxPage = 0;

        const listener = new EventListener(this);
        // プレビュークリック
        previewLayer.addEventListener('click', (event) => { listener.previewClick(event) });

        window.addEventListener('keydown', (event) => { console.log(event); });
    }

    // chr形式のデータをロード
    load(data) {
        this.chips = [];
        this.viewPage = 0;

        const view = new Int8Array(data);
        let index = 0;

        // 画像情報をデコード
        while (index + 16 <= view.length) {
            const chip = new Chip();
            this.chips.push(chip.load(view, index));
            // 16バイト分インデックスを進める
            index += 16;
        }

        //console.log(this.chips.length);
        this.maxPage = Number(this.chips.length / 256) - 1;
        //console.log(this.chips.length / 16 * 8 * 8);

        this.drawPreview();

        this.drawEditorGrid()
    }


    // ----------------------------------------------------------------------
    // 左側 編集画面関連処理
    drawEditor(previewX, previewY) {
        // 背景を黒でクリア
        this.editor.clearMain();

        // 配列から取得する位置の補正
        let shift = previewX + (previewY * PREVIEW_WIDTH);
        // add page shift
        shift += PREVIEW_WIDTH * PREVIEW_HEIGHT * this.viewPage;

        for (let y = 0; y < 2; y++) {
            for (let x = 0; x < 2; x++) {
                const chip = this.chips[(x + y * 16) + shift];
                this.drawChip(chip, x, y, EDITOR_PX, this.editor);
            }
        }
    }

    drawEditorGrid(x, y) {
        // 背景をクリア
        this.editor.clearLayer();
        // 詳細表示している範囲を囲む
        this.editor.setLayerStrokeStyle(1, '#38f');

        // 小グリッド表示
        for (let x = 0; x < (EDITOR_PX * 16); x += EDITOR_PX) {
            for (let y = 0; y < (EDITOR_PX * 16); y += EDITOR_PX) {
                this.editor.strokeLayerRect(x, y, EDITOR_PX, EDITOR_PX);
            }
        }

        // 8x8毎の大グリッド表示
        this.editor.setLayerStrokeStyle(2, '#f88');
        for (let x = 0; x < 2; x++) {
            for (let y = 0; y < 2; y++) {
                this.editor.strokeLayerRect(x * EDITOR_PX * 8, y * EDITOR_PX * 8, EDITOR_PX * 8, EDITOR_PX * 8);
            }
        }

        // 一番上にカーソル表示
        this.editor.strokeLayerRect(0, 0, EDITOR_PX, EDITOR_PX);
        this.editor.fillLayerRect(0, 0, EDITOR_PX, EDITOR_PX, 'rgba( 255, 0, 0, 0.5)');
    }


    // ----------------------------------------------------------------------
    // 右側 プレビュー画面関連処理

    // 1画面分のデータを表示
    drawPreview(withEditor=true) {
        // 背景を黒でクリア
        this.preview.clearMain();

        // 16chipが横に並ぶ
        const pageShift = PREVIEW_WIDTH * PREVIEW_HEIGHT * this.viewPage;
        for (let y = 0; y < PREVIEW_HEIGHT; y++) {
            for (let x = 0; x < PREVIEW_WIDTH; x++) {
                const chip = this.chips[(x + y * 16) + pageShift];
                this.drawChip(chip, x, y, PREVIEW_PX, this.preview);
            }
        }

        this.drawPreviewGrid(0, 0, withEditor);
    }

    drawPreviewGrid(x, y, withEditor=true) {
        if ((PREVIEW_WIDTH - 1) <= x) {
            x -= 1;
        }
        if ((PREVIEW_HEIGHT - 1) <= y) {
            y -= 1;
        }

        // 背景をクリア
        this.preview.clearLayer();
        // 詳細表示している範囲を囲む
        this.preview.setLayerStrokeStyle(3, '#38f');
        this.preview.strokeLayerRect(PREVIEW_GRID * x, PREVIEW_GRID * y, PREVIEW_PX * 8 * 2, PREVIEW_PX * 8 * 2);

        if (!withEditor) {
            return;
        }

        // 同時にエディターも更新
        this.drawEditor(x, y);
    }

    drawChip(chip, x, y, px, chrCanvas) {
        const shiftX = (px * x * 8);
        const shiftY = (px * y * 8);
        
        for (let r = 0; r < 8; r++){
            const row = chip.rows[r];
            for (let c = 0; c < 8; c++) {
                const p = row[c];
                let style = null;
                // 色はchipのカラーパレットから取るように
                switch(p) {
                    case 1:
                        style = 'rgb( 255, 0, 0)';
                    break;
                    case 2:
                        style = 'rgb( 0, 255, 0)';
                    break;
                    case 3:
                        style = 'rgb( 0, 0, 255)';
                    break;
                }

                if (!style) {
                    continue;
                }

                chrCanvas.drawPixel(px * c + shiftX, px * r + shiftY, px, style);
            }
        }
    }

    // ----------------------------------------------------------------------
    // 画面操作
    
    // UInt8Arrayへ変換
    toArray() {
        const data = [];
        for (const chip of this.chips) {
            data.push(...chip.toArray());
        }
        return new Uint8Array(data);
    }

    // 1ページ戻る
    prev() {
        if (!this.hasPrev()) {
            return;
        }
        this.viewPage -= 1;
        this.drawPreview();
    }

    // 1ページ進む
    next() {
        if (!this.hasNext()) {
            return;
        }
        this.viewPage += 1;
        this.drawPreview();
    }

    hasPrev() {
        return !(this.viewPage <= 0);
    }

    hasNext() {
        return !(this.maxPage <= this.viewPage);
    }
}


/*
エディターのカーソルで対象ドットを移動
ドットが打てるように
ドットの座標情報を表示(メモリマップ的な)
パレット指定機能追加
パレットの保存機能

表示モード変更 通常か横並び4チップを2x2で表示
*/

