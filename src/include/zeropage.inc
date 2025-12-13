.ifndef _ZEROPAGE_INC_
.define _ZEROPAGE_INC_ = 1

; -----------------------------------------------------------
; Global ZeroPage Labels
; -----------------------------------------------------------
.segment "ZEROPAGE"                ; Optional, but good to reiterate this section's purpose
 ; could also use .zeropage

; --- IMPORT the symbols from the linker's pool ---
.importzp ZP_PALETTE_ADDR_L
.importzp ZP_PALETTE_ADDR_H
.importzp ZP_PALETTE_ADDR

PALETTE_DEFAULT_LENGTH = $20  ; 32 bytes

.endif