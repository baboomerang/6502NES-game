;-------------------------------------------------
; src/asm/game.s
; Subroutines that handle the game state
;-------------------------------------------------
.include "../include/global.inc"
.include "../include/zeropage.inc"


; Game should jump to one of these functions after every vblank
.segment "CODE"
title_screen_tick:
    LOAD_PTR ZP_GENERIC_PURPOSE_GLOBAL_POINTER, $0300
    lda #$05
    jsr fill_ram_value
    inc ZP_NMI_STATUS_NEEDS_NMI
    inc ZP_NMI_STATUS_NEEDS_DRAW
    rts

in_game_tick:
    tax
    nop
    nop
    txa
    rts

game_over_tick:
    nop
    nop
    rts