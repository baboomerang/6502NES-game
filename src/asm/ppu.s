;-------------------------------------------------
; src/asm/ppu.s
; PPU Management Subroutines
;-------------------------------------------------
.include "../include/global.inc"
.import palette_data

.segment "ZEROPAGE"
pointer: .res 1

.segment "CODE"
ppu_wait_for_vblank:
::check_status:
    bit PPUSTATUS       ; Wait until VBLANK NMI flag (bit 7) is set
    bpl ::check_status
    rts

ppu_load_palette:
    ; (Code that writes 32 bytes from a palette table to PPUDATA)
    lda #>($3F00)
    sta PPUADDR
    lda #<($3F00)
    sta PPUADDR
    ldx #$00
::load_pal_loop:
    lda palette_data, x
    sta PPUDATA
    inx
    cpx #$20
    bne ::load_pal_loop
    rts

; Copy bytes of data from the drawing buffer to PPUDATA
draw:
    rts

; Load a full uncompressed nametable (1024 bytes) from PRG rom to PPUDATA
; Input: 16-bit pointer
loadnametable_full:
    ldx #$00
    ldy #$00
@write:
    lda (pointer), y    ;load byte at address (pointer + y)
    sta PPUDATA
    iny
    cpx #$03
    bne @check_y
    cpy #$c0
    beq @end
@check_y:
    cpy #$00
    bne @write
    inx
    inc pointer+1     ;increment the high byte of the pointer ONLY
    jmp @write
@end:
    rts
