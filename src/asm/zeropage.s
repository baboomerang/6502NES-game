;-------------------------------------------------
; src/asm/zeropage.s
; Defines and EXPORTS all global Zero Page variables
;-------------------------------------------------
.segment "ZEROPAGE"

; Define the two-byte variable for the palette source address
ZP_PALETTE_ADDR:                   .res 2 ; Full 16-bit source address (used for ppu purposes)
ZP_NAMETABLE_ADDR:                 .res 2 ; Full 16-bit source address (used for ppu purposes)
ZP_NMI_STATUS_NEEDS_NMI:           .res 1
ZP_NMI_STATUS_NEEDS_DMA:           .res 1
ZP_NMI_STATUS_NEEDS_DRAW:          .res 1
ZP_NMI_STATUS_NEEDS_PPU_REG:       .res 1
ZP_NMI_STATUS_NEEDS_PADS:          .res 1
ZP_RLE_POINTER:                    .res 2 ; Full 16-bit source address (used for ppu purposes, RLE decoding)
ZP_RLE_TAG:                        .res 1
ZP_RLE_SELECTED_BYTE:              .res 1
ZP_JOY_1_BUTTONS:                  .res 1
ZP_GAMESTATE:                      .res 1
ZP_PPU_DRAW_ADDR:                  .res 2 ; Full 16-bit source address ()
ZP_PPU_DRAW_LENGTH:                .res 1
ZP_GENERIC_PURPOSE_GLOBAL_POINTER: .res 2 ; Full 16-bit source address (used for anything OUTSIDE OF NMI)
ZP_GENERIC_PURPOSE_NMI_POINTER:    .res 2 ; Full 16-bit source address (used for anything IN THE NMI ONLY)

; Export the symbols so other files can see them
.exportzp ZP_PALETTE_ADDR
.exportzp ZP_NAMETABLE_ADDR
.exportzp ZP_NMI_STATUS_NEEDS_NMI
.exportzp ZP_NMI_STATUS_NEEDS_DMA
.exportzp ZP_NMI_STATUS_NEEDS_DRAW
.exportzp ZP_NMI_STATUS_NEEDS_PPU_REG
.exportzp ZP_NMI_STATUS_NEEDS_PADS
.exportzp ZP_RLE_POINTER
.exportzp ZP_RLE_TAG
.exportzp ZP_RLE_SELECTED_BYTE
.exportzp ZP_JOY_1_BUTTONS
.exportzp ZP_GAMESTATE
.exportzp ZP_PPU_DRAW_ADDR
.exportzp ZP_PPU_DRAW_LENGTH
.exportzp ZP_GENERIC_PURPOSE_GLOBAL_POINTER
.exportzp ZP_GENERIC_PURPOSE_NMI_POINTER