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
.macro LOAD_PTR dest_ptr, source_addr
    lda #<(source_addr)  ; Load Low Byte
    sta dest_ptr         ; Store at ZP_DEST_PTR (Low Byte)
    lda #>(source_addr)  ; Load High Byte
    sta dest_ptr + 1     ; Store at ZP_DEST_PTR + 1 (High Byte)
.endmacro

; register ppu macros here (possibly used everywhere else in the project)
; --------------------------------------------------------------------
; PPU_BEGIN_OAM_DMA_TRANSFER macro
; Initiates a 256-byte DMA transfer from CPU memory to PPU OAM memory.
; The transfer source address must be a page-aligned address ($XX00).
; --------------------------------------------------------------------
.macro PPU_BEGIN_OAM_DMA_TRANSFER addr
    ; The low byte of the source address is implicitly $00.
    lda #0
    sta OAMADDR         ; Redundant and optional to store 0 here to $2003.
    lda #>(addr)        ; Load the high byte (page address) of the source data.
    sta OAMDMA          ; Write the high byte to $4014 to immediately begin the 513/514 cycle transfer.
.endmacro

; --------------------------------------------------------------------
; PPU_SET_SCROLL macro
; Sets the PPU scrolling offsets (X and Y) using the $2005 register.
; --------------------------------------------------------------------
.macro PPU_SET_SCROLL xsel, ysel
    bit PPUSTATUS       ; Reset the PPU address latch (guarantees next write is X scroll).
    
    lda xsel            ; Load the horizontal (X) scroll value.
    sta PPUSCROLL       ; Write X scroll to $2005. This is the first write and flips the latch.
    
    lda ysel            ; Load the vertical (Y) scroll value.
    sta PPUSCROLL       ; Write Y scroll to $2005, completing the scroll setup.
.endmacro

; --------------------------------------------------------------------
; PPU_SET_ADDR macro
; Sets the 16-bit VRAM address pointer within the PPU (via $2006).
; --------------------------------------------------------------------
.macro PPU_SET_ADDR addr
    bit PPUSTATUS       ; Reset the PPU's internal 1-byte address latch by reading $2002.
    
    lda #>(addr)        ; Load the high byte of the address.
    sta PPUADDR         ; Write high byte to $2006 (PPUADDR).
    
    lda #<(addr)        ; Load the low byte of the address.
    sta PPUADDR         ; Write low byte to $2006, completing the 16-bit address set.
.endmacro

.macro PPU_ENABLE_RENDERING
    cli                 ; Clear interrupt-disable bit (enable interrupts)
    lda #%10000000      ; Enable nmi and use second set of chr tiles ($1000)
    sta PPUCTRL
    lda #%00011110      ; Enable background, sprites, sprites on vblank border, disable grayscale
    sta PPUMASK
.endmacro

.macro PPU_DISABLE_RENDERING
    sei                 ; Set interrupt-disable bit (disable interrupts)
    lda #%00000000      ; Disable nmi, still use second set of chr tiles
    sta PPUCTRL
    lda #00             ; Disable all graphics, enable grayscale mode
    sta PPUMASK
.endmacro

.endif