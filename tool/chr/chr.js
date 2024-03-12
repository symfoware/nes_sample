// https://bugzmanov.github.io/nes_ebook/chapter_6_3.html
const SCREEN_WIDTH = 16;
const SCREEN_HEIGHT = 16;

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

export class CHR {

    constructor(canvas) {
        this.canvas = canvas;
        this.ctx = canvas.getContext('2d');
        
        // 8x8を1chipとして保存
        this.chips = []; // length: 8192, 2048chip
        this.viewPage = 0; // 0 ~ 4
        this.maxPage = 0;
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

        this.draw(0);
        
    }

    // 1画面分のデータを表示
    draw(pageIndex) {
        // 背景を黒でクリア
        this.ctx.fillStyle = 'rgb( 0, 0, 0)';
        this.ctx.fillRect(0, 0, this.canvas.width, this.canvas.height);

        // 16chipが横に並ぶ
        const pageShift = SCREEN_WIDTH * SCREEN_HEIGHT * pageIndex;
        for (let y = 0; y < SCREEN_HEIGHT; y++) {
            for (let x = 0; x < SCREEN_WIDTH; x++) {
                const chip = this.chips[(x + y * 16) + pageShift];
                this.drawChip(chip, x, y, pageShift);
            }
        }
    }

    drawChip(chip, x, y) {
        const px = 8;
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

                this.ctx.fillStyle = style;
                this.ctx.fillRect(px * c + shiftX, px * r + shiftY, px, px);
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
            //this.viewPage = 0;
            return;
        }
        this.viewPage -= 1;
        this.draw(this.viewPage);
    }

    // 1ページ進む
    next() {
        if (!this.hasNext()) {
            //this.viewPage = this.maxPage ;
            return;
        }
        this.viewPage += 1;
        this.draw(this.viewPage);
    }

    hasPrev() {
        return !(this.viewPage <= 0);
    }

    hasNext() {
        return !(this.maxPage <= this.viewPage);
    }
}


/*
レイヤーをかぶせてグリッド表示
レイアウト微調整
左側に編集画面表示
カーソルで対象ドットを移動
ドットが打てるように
パレット指定機能追加
パレットの保存機能
表示モード変更 通常か横並び4チップを2x2で表示
*/

