;-------------------------------------------------
; src/asm/zeropage.s
; Defines and EXPORTS all global Zero Page variables
;-------------------------------------------------
.segment "ZEROPAGE"

; Define the two-byte variable for the palette source address
ZP_PALETTE_ADDR_L: .res 1 ; Low byte of 16-bit source address
ZP_PALETTE_ADDR_H: .res 1 ; High byte of 16-bit source address
ZP_PALETTE_ADDR:   .res 2 ; Full 16-bit source address (used for ppu purposes)

; --- EXPORT the symbols so other files can see them ---
.exportzp ZP_PALETTE_ADDR_L
.exportzp ZP_PALETTE_ADDR_H
.exportzp ZP_PALETTE_ADDR