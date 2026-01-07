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
    lda #$09
    jsr ppu_fill_ram_value

    lda ZP_JOY_1_BUTTONS
    and #PAD_START
    beq ::skip_title_action

    lda #1
    sta ZP_GAMESTATE

::skip_title_action:
    rts

in_game_tick:
    LOAD_PTR ZP_PPU_DRAW_ADDR, $0300
    lda #$ff
    sta ZP_PPU_DRAW_LENGTH

    inc ZP_NMI_STATUS_NEEDS_NMI
    inc ZP_NMI_STATUS_NEEDS_DRAW

    tax
    nop
    nop
    txa
    rts

game_over_tick:
    nop
    nop
    rts