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

    constructor(index) {
        this.rows = [];
        this.index = index;
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
                let value = (1 & upper) | (1 & lower) << 1;
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

                upper += value & 1;
                lower += (value & 2) >> 1;
            }
            view[r] = upper;
            view[r + 8] = lower;
        }
        
        return view;
    }
}

export const Palette = [
    '#808080', '#003DA6', '#0012B0', '#440096', '#A1005E', '#C70028', '#BA0600', '#8C1700', // $00
    '#5C2F00', '#104500', '#054A00', '#00472E', '#004166', '#000000', '#050505', '#050505',
    '#C7C7C7', '#0077FF', '#2155FF', '#8237FA', '#EB2FB5', '#FF2950', '#FF2200', '#D63200', // $10
    '#C46200', '#358000', '#058F00', '#008A55', '#0099CC', '#212121', '#090909', '#090909',
    '#FFFFFF', '#0FD7FF', '#69A2FF', '#D480FF', '#FF45F3', '#FF618B', '#FF8833', '#FF9C12', // $20
    '#FABC20', '#9FE30E', '#2BF035', '#0CF0A4', '#05FBFF', '#5E5E5E', '#0D0D0D', '#0D0D0D',
    '#FFFFFF', '#A6FCFF', '#B3ECFF', '#DAABEB', '#FFA8F9', '#FFABB3', '#FFD2B0', '#FFEFA6', // $30
    '#FFF79C', '#D7E895', '#A6EDAF', '#A2F2DA', '#99FFFC', '#DDDDDD', '#111111', '#111111'
];

// イベント処理
class EventListener {
    constructor(owner) {
        this.owner = owner;
        this.cursorX = 0;
        this.cursorY = 0;
        this.gridX = 0;
        this.gridY = 0;
    }

    clickEditor(event) {
        if (!this.owner.chips.length) {
            return;
        }
        // dot単位で移動させる
        this.cursorX = Math.trunc(event.offsetX / EDITOR_PX);
        this.cursorY = Math.trunc(event.offsetY / EDITOR_PX);
        this.owner.drawCursor(this.cursorX, this.cursorY);

    }

    clickPreview(event) {
        if (!this.owner.chips.length) {
            return;
        }

        // chip単位で移動させる
        this.gridX = Math.trunc(event.offsetX / PREVIEW_GRID);
        this.gridY = Math.trunc(event.offsetY / PREVIEW_GRID);
        // プレビューのグリッド表示位置を更新
        this.owner.drawPreviewGrid(this.gridX, this.gridY);
        
    }

    keydown(event) {
        if (!this.owner.chips.length) {
            return;
        }

        let moveCursor = false;
        let changeDot = -1;
        switch(event.key){
            case 'ArrowLeft':
                console.log('左');
                this.cursorX -= 1;
                moveCursor = true;
            break;
            case 'ArrowRight':
                console.log('右');
                this.cursorX += 1;
                moveCursor = true;
            break;
            case 'ArrowUp':
                console.log('上');
                this.cursorY -= 1;
                moveCursor = true;
            break;
            case 'ArrowDown':
                console.log('下');
                this.cursorY += 1;
                moveCursor = true;
            break;
            case '0':
                //console.log('0');
                changeDot = 0;
            break;
            case '1':
                //console.log('1');
                changeDot = 1;
            break;
            case '2':
                //console.log('2');
                changeDot = 2;
            break;
            case '3':
                //console.log('3');
                changeDot = 3;
            break;
        }
        if(moveCursor) {
            this.cursorX = Math.max(this.cursorX, 0);
            this.cursorX = Math.min(this.cursorX, 15);

            this.cursorY = Math.max(this.cursorY, 0);
            this.cursorY = Math.min(this.cursorY, 15);

            this.owner.drawCursor(this.cursorX, this.cursorY);
            event.preventDefault();
            return;
        }

        if (changeDot !== -1) {
            this.owner.changeDot(this.cursorX, this.cursorY, changeDot);
            event.preventDefault();
            return;
        }
        
    }

}


// Canvas操作
class CHRCanvas {
    constructor(main, layer, cursor) {
        this.main = main;
        this.layer = layer;
        this.cursor = cursor;
        this.mctx = main.getContext('2d');
        this.lctx = layer.getContext('2d');
        if (cursor) {
            this.cctx = cursor.getContext('2d');
        }

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

    drawCursor(x, y) {
        if (!this.cctx) {
            return;
        }
        this.cctx.clearRect(0, 0, this.width, this.height);
        this.cctx.lineWidth = 2;
        this.cctx.strokeStyle = '#f88';
        this.cctx.strokeRect(x * EDITOR_PX, y * EDITOR_PX, EDITOR_PX, EDITOR_PX);
        this.cctx.fillStyle = 'rgba( 255, 0, 0, 0.5)';
        this.cctx.fillRect(x * EDITOR_PX, y * EDITOR_PX, EDITOR_PX, EDITOR_PX);
    }

}


export class CHR {

    constructor(editor, editorLayer, editorCursor, preview, previewLayer) {
        
        this.editor = new CHRCanvas(editor, editorLayer, editorCursor);
        this.preview = new CHRCanvas(preview, previewLayer);
        
        // 8x8を1chipとして保存
        this.chips = []; // length: 8192, 2048chip
        this.viewPage = 0; // 0 ~ 4
        this.maxPage = 0;

        // パレット設定
        this.palette = {
            bg: [ 0x0f, 0x08, 0x18, 0x39],
            sp: [ 0x0f, 0x08, 0x18, 0x39],
        };

        this.listener = new EventListener(this);
        // クリックイベント設定
        editorCursor.addEventListener('click', (event) => { this.listener.clickEditor(event) });
        previewLayer.addEventListener('click', (event) => { this.listener.clickPreview(event) });

        window.addEventListener('keydown', (event) => { this.listener.keydown(event); });

        this.editor.clearMain();
        this.preview.clearMain();

    }

    // chr形式のデータをロード
    load(data) {
        this.chips = [];
        this.viewPage = 0;

        const view = new Int8Array(data);
        let index = 0;

        // 画像情報をデコード
        while (index + 16 <= view.length) {
            const chip = new Chip(this.chips.length);
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
        this.editorChips = [];

        // 配列から取得する位置の補正
        let shift = previewX + (previewY * PREVIEW_WIDTH);
        // add page shift
        shift += PREVIEW_WIDTH * PREVIEW_HEIGHT * this.viewPage;

        for (let y = 0; y < 2; y++) {
            for (let x = 0; x < 2; x++) {
                const chip = this.chips[(x + y * 16) + shift];
                this.drawChip(chip, x, y, EDITOR_PX, this.editor);
                this.editorChips.push(chip);
            }
        }

        // カーソルのあるチップのアドレス表示
        if(this.onChangeViewCallback) {
            this.onChangeViewCallback();
        }
    }

    drawEditorGrid() {
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

        this.drawCursor(0, 0);

    }

    drawCursor(x, y) {
        // 一番上にカーソル表示
        this.editor.drawCursor(x, y);

        // カーソルのあるチップのアドレス表示
        if(this.onChangeViewCallback) {
            this.onChangeViewCallback();
        }
    }

    changeDot(x, y, index) {
        // 対象チップを判定
        let chipNunber = 0;
        if (x < 8) {
            if (y < 8) {
                chipNunber = 0;
            } else {
                chipNunber = 2;
            }
        } else {
            if (y < 8) {
                chipNunber = 1;
            } else {
                chipNunber = 3;
            }
        }
        const col = x % 8;
        const row = y % 8;
        console.log(chipNunber, row, col);
        this.editorChips[chipNunber].rows[row][col] = index;
        
        //this.editorChips
        this.drawPreview();
    }


    // ----------------------------------------------------------------------
    // 右側 プレビュー画面関連処理

    // 1画面分のデータを表示
    drawPreview(withEditor=true) {
        if (!this.chips.length) {
            return;
        }

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

        this.drawPreviewGrid(this.listener.gridX, this.listener.gridY, withEditor);
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
            //return;
        }

        // 同時にエディターも更新
        this.drawEditor(x, y);
    }

    drawChip(chip, x, y, px, chrCanvas) {
        const shiftX = (px * x * 8);
        const shiftY = (px * y * 8);
        let type = 'bg';
        if (this.viewPage !== 0) {
            type = 'sp';
        }
        
        for (let r = 0; r < 8; r++){
            const row = chip.rows[r];
            for (let c = 0; c < 8; c++) {
                const p = row[c];
                if (p === 0) {
                    continue;
                }

                const style = Palette[this.palette[type][p]];
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

    // ----------------------------------------------------------------------
    // パレットデータ操作
    getPallete(type, index) {
        const colorIndex = this.palette[type][index];
        return [colorIndex, Palette[colorIndex]];
    }

    setPallete(type, index, colorIndex) {
        this.palette[type][index] = colorIndex;
        this.drawPreview();
    }


    // ----------------------------------------------------------------------
    // チップ情報取得
    getCurrentInfo() {
        if (!this.chips.length) {
            return '';
        }

        // 対象チップを判定
        const x = this.listener.cursorX;
        const y = this.listener.cursorY;
        let chipNunber = 0;
        if (x < 8) {
            if (y < 8) {
                chipNunber = 0;
            } else {
                chipNunber = 2;
            }
        } else {
            if (y < 8) {
                chipNunber = 1;
            } else {
                chipNunber = 3;
            }
        }

        // カーソルのあるチップのインデックスを16進数表記でリターン
        const index = this.editorChips[chipNunber].index;
        return '$' + ('000' + index.toString(16)).slice(-4);
    }

    // ----------------------------------------------------------------------
    // イベント設定
    onChangeView(callback) {
        this.onChangeViewCallback = callback;
    }

}


/*
> ファイルのドロップで開けるように
>カーソル位置のチップの座標情報を表示(メモリマップ的な)
編集モード変更 通常か横並び4チップを2x2で表示
--ここまで一旦作ってみて構造化

・あったら良いかも
完全新規作成
*/

