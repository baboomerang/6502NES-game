;-------------------------------------------------
; src/asm/ppu.s
; PPU Management Subroutines
;-------------------------------------------------
.include "../include/global.inc"
.include "../include/zeropage.inc"

.segment "CODE"
ppu_wait_for_vblank:
::check_status:
    bit PPUSTATUS       ; Wait until VBLANK NMI flag (bit 7) is set
    bpl ::check_status
    rts

ppu_clear_oam:
    lda #$ff            ; Load the value $FF (off-screen Y position)
    ldx #$00            ; Start index at 0
::clear_loop:
    sta $0200, x        ; Store $FF into the buffer (this sets the Y coord for a sprite)
    inx                 ; Increment X
    cpx #$ff            ; Check if X is 256 (wraps from $FF to $00 and sets Z flag)
    bne ::clear_loop    ; Loop until all 256 bytes of OAM_buffer have $FF
    PPU_BEGIN_OAM_DMA_TRANSFER $0200
    rts

; Example Usage:
;    lda #<(palette_data_2) ; Load low byte
;    sta ZP_SRC_ADDR        ; Store in the first byte
;    lda #>(palette_data_2) ; Load high byte
;    sta ZP_SRC_ADDR + 1    ; Store in the second byte
;    jsr ppu_load_palette_regs
ppu_load_palette:
    lda #>(PPU_PALETTE_RAM_ADDRESS) ; Get the high byte ($3f)
    sta PPUADDR
    lda #<(PPU_PALETTE_RAM_ADDRESS) ; Get the low byte ($00)
    sta PPUADDR
    ldx #$00
::load_pal_loop:
    ldy #$00
    lda (ZP_PALETTE_ADDR), y
    sta PPUDATA
    inc ZP_PALETTE_ADDR             ; Increment low byte (address ZP_SRC_ADDR)
    bne :+
    inc ZP_PALETTE_ADDR + 1         ; Increment high byte (address ZP_SRC_ADDR + 1) if previous increment overflowed FF to 00
:
    inx
    cpx PALETTE_DEFAULT_LENGTH
    bne ::load_pal_loop
    rts

; Copy bytes of data from the drawing buffer to PPUDATA
draw:
    rts

; Load a full uncompressed nametable (1024 bytes) from PRG rom to PPUDATA
; Input: 16-bit pointer
;loadnametable_full:
;    ldx #$00
;    ldy #$00
;@write:
;    lda (pointer), y    ;load byte at address (pointer + y)
;    sta PPUDATA
;    iny
;    cpx #$03
;    bne @check_y
;    cpy #$c0
;    beq @end
;@check_y:
;    cpy #$00
;    bne @write
;    inx
;    inc pointer+1     ;increment the high byte of the pointer ONLY
;    jmp @write
;@end:
;    rts
;