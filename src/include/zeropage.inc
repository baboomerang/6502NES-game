.ifndef _ZEROPAGE_INC_
.define _ZEROPAGE_INC_ = 1

; -----------------------------------------------------------
; Global ZeroPage Labels
; -----------------------------------------------------------
.segment "ZEROPAGE"                ; Optional, but good to reiterate this section's purpose
; could also use .zeropage

; --- IMPORT the symbols from the linker's pool ---
.importzp ZP_PALETTE_ADDR
.importzp ZP_NAMETABLE_ADDR
.importzp ZP_NMI_STATUS_NEEDS_NMI
.importzp ZP_NMI_STATUS_NEEDS_DMA
.importzp ZP_NMI_STATUS_NEEDS_DRAW
.importzp ZP_NMI_STATUS_NEEDS_PPU_REG
.importzp ZP_NMI_STATUS_NEEDS_PADS
.importzp ZP_RLE_POINTER
.importzp ZP_RLE_TAG
.importzp ZP_RLE_SELECTED_BYTE
.importzp ZP_GENERIC_PURPOSE_GLOBAL_POINTER

PALETTE_DEFAULT_LENGTH = $20  ; 32 bytes

.endif