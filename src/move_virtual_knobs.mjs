import {clamp} from "./math_helpers.mjs"
let knobs = [0,0,0,0,0,0,0,0,0];


/*
================================================================================
RGB COLOR PALETTE (INDEXED 0–127)
================================================================================

--- NEUTRALS / GREYS -----------------------------------------------------------
  0 : #000000  Black
117 : #000000  Black (dup)
124 : #1A1A1A  Dark Grey
119 : #1A1A1A  Dark Grey (dup)
118 : #595959  Light Grey
121 : #595959  Light Grey (dup)
123 : #595959  Light Grey (dup)
120 : #FFFFFF  White
122 : #FFFFFF  White (dup)

--- REDS / PINKS / MAGENTAS ----------------------------------------------------
  1 : #FF2424  Bright Red
 27 : #A63421  Rust Red
 65 : #4D0B0B  Deep Red
 66 : #1A0404  Very Dark Red
 67 : #4D1204  Brick
 20 : #8700FF  Electric Violet
 21 : #E657E3  Hot Magenta
 23 : #FF0099  Neon Pink
 24 : #A14C5F  Rose
 25 : #FF4DC4  Bright Pink
 26 : #EB8BE1  Light Magenta
104 : #0D001A  Deep Violet
105 : #4D1D4C  Muted Violet
107 : #33004D  Dark Purple
109 : #4D002E  Deep Magenta
111 : #4D242D  Dusty Rose
113 : #4D173B  Mauve
114 : #1A0814  Deep Wine
115 : #4D2D49  Dusky Mauve
116 : #1A0F18  Shadow Mauve

--- ORANGES / AMBERS / YELLOWS -------------------------------------------------
  2 : #F23A0C  Orange Red
  3 : #FF9900  Bright Orange
  4 : #A68956  Tan / Muted Orange
  5 : #EDF95A  Light Yellow
  6 : #C19D08  Ochre
  7 : #FFFF00  Vivid Yellow
 28 : #995628  Burnt Orange
 29 : #876700  Mustard
 30 : #90821F  Yellow-Green
 73 : #4D491F  Dull Yellow
 74 : #1A180A  Very Dark Yellow
 75 : #403302  Brown-Yellow
 76 : #1A1501  Deep Brown-Yellow
 77 : #4D4D00  Olive
 78 : #1A1A00  Dark Olive

--- GREENS / TEALS -------------------------------------------------------------
  8 : #56BF13  Bright Green
  9 : #2C8403  Forest Green
 10 : #246B24  Dull Green
 11 : #19FF30  Neon Green
 12 : #159573  Teal Green
 13 : #176B50  Muted Teal
 14 : #00FFFF  Cyan
 31 : #4A8700  Lime
 32 : #007F12  Deep Green
 43 : #AEFF99  Pale Green
 44 : #7CDD9F  Mint Green
 45 : #89B47D  Olive Green
 79 : #1C4007  Dull Green
 80 : #0B1A03  Very Dark Green
 81 : #113301  Dull Olive
 83 : #113311  Dark Olive Green
 85 : #0A4D0A  Dark Grass Green
 87 : #073327  Dark Teal
 89 : #104D39  Muted Sea Green
 90 : #030D0A  Deep Teal

--- CYANS / AQUAS / BLUES ------------------------------------------------------
 15 : #0074FC  Azure Blue
 16 : #274FCC  Royal Blue
 17 : #00448C  Navy
 33 : #1853B2  Blue
 46 : #80F3FF  Pale Cyan
 47 : #7ACEFC  Sky Blue
 48 : #68A1D3  Light Blue
 49 : #858FC2  Muted Blue
 50 : #BBAAF2  Lavender Blue
 93 : #00234D  Deep Blue
 95 : #0C1940  Dark Blue
 97 : #00254D  Cool Blue
 99 : #231A4D  Indigo
100 : #0C091A  Deep Indigo
101 : #251E4D  Purple-Blue
102 : #0C0A1A  Dark Indigo
125 : #0000FF  Pure Blue

--- PURPLES / VIOLETS ---------------------------------------------------------
 18 : #644AD9  Blue-Violet
 19 : #4D3FA0  Violet
 22 : #660099  Purple
 34 : #624BAD  Lilac
 35 : #733A67  Mauve
106 : #1A0A19  Deep Plum
108 : #11001A  Dark Violet
110 : #1A000F  Wine Purple
112 : #1A0C0F  Dark Rose
115 : #4D2D49  Muted Violet (duplicate family)
 20–26 : also span violet–pink boundary (see REDS)


--- PRIMARY COLORS -------------------------------------------------------------
125 : #0000FF  Blue
126 : #00FF00  Green
127 : #FF0000  Red
================================================================================
*/

const synthwaveColorSweep = [0, 104, 105, 20, 21, 23, 26, 25];
const roseColorSweep = [0, 124, 35, 23, 26, 25];
const neutralColorSweep = [0, 124, 123, 120];
const rainbowColorSweep = [33, 16, 15, 14, 11, 8, 3, 2];

function getColorForKnobValue(value = 0) {
    const colorSweep = synthwaveColorSweep;

    const level = clamp(value, 0, 127) / 127;
    const index = Math.round(level * (colorSweep.length - 1));

    return colorSweep[index];
}


export function handleMoveKnobs(data, channel = 3) {

    if (!(data[0] === 0xb0)) {
        return false;
    }

    let knob = -1;

    let moveControlNumber = data[1];
    let value = data[2];

    console.log(moveControlNumber, value);

    // If this is a Move knob, turn it into a 0-127 value vs +/- 1 values so we can map to external devices easily.
    if (moveControlNumber >= 71 && moveControlNumber <= 80) {
        knob = moveControlNumber - 71;
    }

    if (knob != -1) {

        if (value === 127) {
            knobs[knob] -= 1;
        }

        if (value === 1) {
            knobs[knob] += 1;
        }

        knobs[knob] = clamp(knobs[knob], 0, 127);

        console.log(`Sending CC ${moveControlNumber} value: ${knobs[knob]}`);
        move_midi_external_send([2 << 4 | 0xb, 0xb0 | channel, moveControlNumber, knobs[knob]]);
        
        move_midi_internal_send([0 << 4 | 0xb, 0xb0 | 0, moveControlNumber, getColorForKnobValue(knobs[knob])]);
        return true;
    }

    return false;
}