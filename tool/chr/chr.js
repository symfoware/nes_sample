// https://bugzmanov.github.io/nes_ebook/chapter_6_3.html
// プレビュー表示のチップ
const PREVIEW_WIDTH = 16;
const PREVIEW_HEIGHT = 16;
// プレビュー表示 1ドットの表示ピクセル
const PREVIEW_PX = 8;
const PREVIEW_GRID = PREVIEW_PX * 8;

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

class EventListener {
    constructor(owner) {
        this.owner = owner;
    }

    previewClick(event) {
        // chip単位で移動させる
        const x = Math.trunc(event.offsetX / PREVIEW_GRID);
        const y = Math.trunc(event.offsetY / PREVIEW_GRID);

        this.owner.drawPreviewGrid(x, y);
        
    }
}



export class CHR {

    constructor(preview, previewCover) {
        this.preview = preview;
        this.previewCover = previewCover;
        this.pctx = preview.getContext('2d');
        this.pcctx = previewCover.getContext('2d');
        
        // 8x8を1chipとして保存
        this.chips = []; // length: 8192, 2048chip
        this.viewPage = 0; // 0 ~ 4
        this.maxPage = 0;

        const listener = new EventListener(this);
        // プレビュークリック
        this.previewCover.addEventListener('click', (event) => { listener.previewClick(event) });
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

        this.drawPreview(0);
        
    }

    // 1画面分のデータを表示
    drawPreview(pageIndex) {
        // 背景を黒でクリア
        this.pctx.fillStyle = 'rgb( 0, 0, 0)';
        this.pctx.fillRect(0, 0, this.preview.width, this.preview.height);

        // 16chipが横に並ぶ
        const pageShift = PREVIEW_WIDTH * PREVIEW_HEIGHT * pageIndex;
        for (let y = 0; y < PREVIEW_HEIGHT; y++) {
            for (let x = 0; x < PREVIEW_WIDTH; x++) {
                const chip = this.chips[(x + y * 16) + pageShift];
                this.drawPreviewChip(chip, x, y, pageShift);
            }
        }

        this.drawPreviewGrid(0, 0);
    }

    drawPreviewGrid(x, y) {
        if ((PREVIEW_WIDTH - 1) <= x) {
            x -= 1;
        }
        if ((PREVIEW_HEIGHT - 1) <= y) {
            y -= 1;
        }

        // 背景をクリア
        this.pcctx.clearRect(0, 0, this.previewCover.width, this.previewCover.height);
        // 詳細表示している範囲を囲む
        this.pcctx.lineWidth = 3;
        this.pcctx.strokeStyle = "#38f";
        this.pcctx.strokeRect(PREVIEW_GRID * x, PREVIEW_GRID * y, PREVIEW_PX * 8 * 2, PREVIEW_PX * 8 * 2);
    }

    drawPreviewChip(chip, x, y) {
        const px = PREVIEW_PX;
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

                this.pctx.fillStyle = style;
                this.pctx.fillRect(px * c + shiftX, px * r + shiftY, px, px);
            }
        }
    }

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
        this.drawPreview(this.viewPage);
    }

    // 1ページ進む
    next() {
        if (!this.hasNext()) {
            return;
        }
        this.viewPage += 1;
        this.drawPreview(this.viewPage);
    }

    hasPrev() {
        return !(this.viewPage <= 0);
    }

    hasNext() {
        return !(this.maxPage <= this.viewPage);
    }
}


/*
>レイヤーをかぶせてグリッド表示
>マウスクリックでグリッド位置変更
レイアウト微調整
左側に編集画面表示
カーソルで対象ドットを移動
ドットが打てるように
パレット指定機能追加
パレットの保存機能
表示モード変更 通常か横並び4チップを2x2で表示
*/

