window.addEventListener('load', initOnce, false);
var MOUSEDOWN = null;
var BLOCKSIZE = 10;
var BLOCKS = 32;
var x = 0;
var y = 0;
var ACTIVEFRAME = 0;
var SETTINGS = [];
var CURSORSIZE = 10;
var COLOR = 'black';
var FRAMECOUNTER = 0;
var PLAY = true;
var IMAGES = [];
var FPS = 5;
var FRAMES = [];
/** Selector for document items */
function $$(div) {
    return document.getElementById(div);
};
/** Window init wants to pass a load, so ignore blub */
function init(blub, canvas) {
    CANVAS = canvas ? canvas : $$('canvas');
    CANVAS.style.backgroundColor = '#444';
    CANVAS.height = BLOCKSIZE * BLOCKS;
    CANVAS.width = BLOCKSIZE * BLOCKS;
    CTX = CANVAS.getContext('2d');
    if (!canvas) {
        FRAMES[ACTIVEFRAME] = [];
        for (var y = 0; y < BLOCKS; y += 1) {
            FRAMES[ACTIVEFRAME][y] = [];
            for (var x = 0; x < BLOCKS; x += 1) {
                FRAMES[ACTIVEFRAME][y][x] = 'rgba(0,0,0,0)';
            };
        };
    };
    setTimeout(initFrame, 200);
    clear();
    return null;
};
/** Things that we only want to do once */
function initOnce() {
    init();
    $$('animation').style.height = BLOCKSIZE * BLOCKS + 'px';
    $$('animation').style.width = BLOCKSIZE * BLOCKS + 'px';
    window.addEventListener('mousedown', click, true);
    window.addEventListener('mouseup', unclick, true);
    window.addEventListener('mousemove', moving, true);
    $$('fps').addEventListener('change', updateFps, true);
    $$('hex-color').addEventListener('change', hexToRgb, true);
    $$('colorpicker').addEventListener('mousemove', click, true);
    $$('clear').addEventListener('mousedown', moving, true);
    $$('save').addEventListener('mousedown', moving, true);
    $$('new-frame').addEventListener('mousedown', newFrame, true);
    $$('clone-frame').addEventListener('mousedown', cloneFrame, true);
    $$('play').addEventListener('mousedown', togglePlay, true);
    SETTINGS = [$$('bp-color-R'), $$('bp-color-G'), $$('bp-color-B'), $$('bp-color-A'), $$('bp-cursor-size')];
    var _js4 = SETTINGS.length;
    for (var _js3 = 0; _js3 < _js4; _js3 += 1) {
        var i = SETTINGS[_js3];
        i.addEventListener('change', setSettings, true);
    };
    setTimeout(animationUpdater, 1);
    setTimeout(animation, 1);
    setSettings();
    setInterval(function (α) {
        if (α == α) {
            return setSettings();
        };
    }, 500);
    return setInterval(function (α) {
        if (α == α) {
            return animationUpdater();
        };
    }, 1000);
};
/** Paint canvas based on frame data */
function initFrame() {
    for (var y = 0; y < BLOCKS; y += 1) {
        for (var x = 0; x < BLOCKS; x += 1) {
            var color = FRAMES[ACTIVEFRAME][y][x];
            CTX.fillStyle = color;
            CTX.fillRect(x * BLOCKSIZE, y * BLOCKSIZE, 1 * BLOCKSIZE, 1 * BLOCKSIZE);
        };
    };
};
/** Check if a value is in range */
function inRange(c, min, max) {
    if (isNaN(c.value) || c.value.length < 0 || c.value < min) {
        return c.value = min;
    } else if (c.value > max) {
        return c.value = max;
    } else {
        return c.value;
    };
};
/** Convert hex value to rgb */
function hexToRgb() {
    var hex = $$('hex-color').value;
    for (var i = 0; i <= 2; i += 1) {
        var ss = hex.substr(2 * i + 1, 2);
        SETTINGS[i].value = parseInt(ss, 16);
    };
    return setSettings();
};
/** Grab the FPS */
function updateFps() {
    return FPS = inRange($$('fps'), 1, 30);
};
/** Set the relevant settings/params */
function setSettings() {
    var color = 'rgba(';
    for (var i = 0; i <= 3; i += 1) {
        var v = inRange(SETTINGS[i], 0, i < 3 ? 255 : 100);
        color += i < 3 ? v : parseFloat(v / 100);
        color += i < 3 ? ',' : ')';
    };
    CURSORSIZE = inRange(SETTINGS[4], 1, 10);
    updateFps();
    return COLOR = color;
};
/** Clear the canvas */
function clear() {
    CTX.fillStyle = '#ffffff';
    return CTX.fillRect(0, 0, BLOCKSIZE * BLOCKS, BLOCKSIZE * BLOCKS);
};
/** Draw a single block at cursor point */
function drawBlock(x, y, size) {
    if (!(x > BLOCKSIZE * BLOCKS || y > BLOCKSIZE * BLOCKS)) {
        var bx = x / BLOCKSIZE >> 0;
        var by = y / BLOCKSIZE >> 0;
        var size6 = size || CURSORSIZE;
        CTX.fillStyle = COLOR;
        FRAMES[ACTIVEFRAME][by][bx] = COLOR;
        return CTX.fillRect(bx * BLOCKSIZE, by * BLOCKSIZE, BLOCKSIZE * size6, BLOCKSIZE * size6);
    };
};
function unclick() {
    return MOUSEDOWN = null;
};
function click() {
    MOUSEDOWN = true;
    return MOUSEDOWN ? drawBlock(x, y) : null;
};
function moving(e) {
    x = e.pageX - canvas.offsetLeft;
    y = e.pageY - canvas.offsetTop;
    if (x > BLOCKSIZE * BLOCKS || y > BLOCKSIZE * BLOCKS) {
        MOUSEDOWN = null;
    };
    return MOUSEDOWN ? drawBlock(x, y) : null;
};
function save() {
    return pngSaveData = canvas.toDataUrl('image/png');
};
/** Run the main animation for our drawing */
function animation(animationArray) {
    if (!PLAY || !animationArray || 1 > animationArray.length) {
        return setTimeout(function (α) {
            if (α == α) {
                return animation(IMAGES.slice(0));
            };
        }, 1000 / FPS);
    } else {
        var imageData = animationArray.shift();
        var img = document.createElement('img');
        img.src = imageData;
        $$('animation').appendChild(img);
        return setTimeout(function (α) {
            if (α == α) {
                return animation(animationArray);
            };
        }, 1000 / FPS);
    };
};
function animationUpdater() {
    return IMAGES[ACTIVEFRAME] = CANVAS.toDataURL('image/png');
};
/** Grab active-frame and clone it */
function newFrame() {
    var oldFrame = [];
    for (var y = 0; y < BLOCKS; y += 1) {
        oldFrame[y] = [];
        for (var x = 0; x < BLOCKS; x += 1) {
            oldFrame[y][x] = 'rgba(0,0,0,0)';
        };
    };
    IMAGES[ACTIVEFRAME] = CANVAS.toDataURL('image/png');
    ++FRAMECOUNTER;
    ACTIVEFRAME = FRAMECOUNTER;
    FRAMES[ACTIVEFRAME] = oldFrame.slice(0);
    var newFrame8 = $$('canvas').cloneNode();
    document.body.appendChild(newFrame8);
    return init(null, newFrame8);
};
/** Grab active-frame and clone it */
function cloneFrame() {
    var oldFrame = FRAMES[ACTIVEFRAME];
    IMAGES[ACTIVEFRAME] = CANVAS.toDataURL('image/png');
    ++FRAMECOUNTER;
    ACTIVEFRAME = FRAMECOUNTER;
    FRAMES[ACTIVEFRAME] = oldFrame.slice(0);
    var newFrame = $$('canvas').cloneNode();
    document.body.appendChild(newFrame);
    return init(null, newFrame);
};
/** Toggle playing the animation or not */
function togglePlay() {
    if (PLAY) {
        PLAY = null;
        return $$('play').value = 'play';
    } else {
        PLAY = true;
        return $$('play').value = 'pause';
    };
};