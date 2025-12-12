.ifndef _GLOBAL_INC_
.define _GLOBAL_INC_ = 1

.include "nes.inc" ; Import all NES hardware constants

; -----------------------------------------------------------
; Global Labels
; -----------------------------------------------------------
; register important functions as global labels so the subroutines are visible across files

; register interrupt handlers (found in init.s and main.s)
.global reset_handler
.global main, nmi_handler, irq_handler

; register ppu functions (found in ppu.s)
.global ppu_wait_for_vblank, ppu_load_palette, ppu_clear_oam
.global palette_data

; -----------------------------------------------------------
; Macros
; -----------------------------------------------------------
; register macros here (possibly used everywhere else in the project)
.macro SET_POINTER ptr, addr
    lda #<addr       ;get the low byte first
    sta ptr
    lda #>addr       ;get the high byte second
    sta ptr+1
.endmacro

; register ppu macros here (possibly used everywhere else in the project)
.macro PPU_BEGIN_OAM_DMA_TRANSFER addr
    lda #<addr       ;get the low byte of addr
    sta OAMADDR
    lda #>addr       ;get the high byte of addr
    sta OAMDMA       ;latch and begin transfer to ppu
.endmacro

.macro PPU_SET_SCROLL xsel, ysel
    bit PPUSTATUS    ;reset ppu latch
    lda xsel
    sta PPUSCROLL    ;set x scroll
    lda ysel
    sta PPUSCROLL    ;set y scroll
.endmacro

.macro PPU_SET_ADDR addr
    bit PPUSTATUS    ;reset ppu latch
    lda #>addr       ;get the high byte first
    sta PPUADDR
    lda #<addr       ;get the low byte second
    sta PPUADDR
.endmacro

.macro PPU_ENABLE_RENDERING
    cli              ;clear interrupt-disable bit (enable interrupts)
    lda #%10000000   ;enable nmi and use second set of chr tiles ($1000)
    sta PPUCTRL
    lda #%00011110   ;enable background, sprites, sprites on vblank border, disable grayscale
    sta PPUMASK
.endmacro

.macro PPU_DISABLE_RENDERING
    sei              ;set interrupt-disable bit (disable interrupts)
    lda #%00000000   ;disable nmi, still use second set of chr tiles
    sta PPUCTRL
    lda #00          ;disable all graphics, enable grayscale mode
    sta PPUMASK
.endmacro

.endif