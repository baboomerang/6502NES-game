;-------------------------------------------------
; src/asm/apu.s
; APU (Audio Processing Unit) Subroutines
;-------------------------------------------------
.include "../include/nes2header.inc"
.include "../include/global.inc"

.segment "CODE"
music_engine:
    ldy #00
    rts
