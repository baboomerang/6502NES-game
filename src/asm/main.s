;-------------------------------------------------
; src/asm/main.s
; Main Entrypoint for NES
;-------------------------------------------------
.include "../include/nes2header.inc"
.include "../include/global.inc"
.include "../include/zeropage.inc"

;-------------------------------------------------
; iNES header using nes2header.inc macros
;-------------------------------------------------
; These macros set internal variables within the nes2header.inc
nes2mapper 0          ; Mapper 0 (NROM)
nes2prg 32768         ; 2x16KB PRG ROM
nes2chr 8192          ; 1x8KB CHR ROM
nes2arrange 'V'       ; Vertical mirroring
nes2tv 'N'            ; NTSC TV system
nes2end

.segment "VECTORS"
.addr nmi_handler     ; When an NMI happens (once per frame if enabled) the label nmi:
.addr reset_handler   ; When the processor first turns on or is reset, it will jump to the label reset_handler:
.addr irq_handler     ; External interrupt IRQ (unused) this could also be set to $0

; Main code segment for the whole project
.segment "CODE"
main:
  LOAD_PTR ZP_PALETTE_ADDR, title_palette
  jsr ppu_load_palette

  ; TODO: load nametable
  ;       simple name table - not compressed for now
  ;       find a program to create a name table
  ;       you might have to create your own graphics in your own CHR first
  ;       then create the name table based on it

  PPU_ENABLE_RENDERING
::forever:
  nop
  jmp ::forever

nmi_handler:
  ldx #$00 	         ; Set SPR-RAM address to 0
  stx $2003
loop:	
  lda hello, x ; Load the hello message into SPR-RAM
  sta $2004
  inx
  cpx #$1c
  bne loop
  rti

irq_handler:
    rti

hello:
  .byte $00, $00, $00, $00 	; Why do I need these here?
  .byte $00, $00, $00, $00
  .byte $6c, $00, $00, $6c
  .byte $6c, $01, $00, $76
  .byte $6c, $02, $00, $80
  .byte $6c, $02, $00, $8A
  .byte $6c, $03, $00, $94

title_palette:
  ; Background Palette
  .byte $0f, $00, $00, $00
  .byte $0f, $00, $00, $00
  .byte $0f, $00, $00, $00
  .byte $0f, $00, $00, $00

  ; Sprite Palette
  .byte $0f, $20, $00, $00
  .byte $0f, $00, $00, $00
  .byte $0f, $00, $00, $00
  .byte $0f, $00, $00, $00

; Character memory
.segment "CHR"
  .byte %11000011	; H (00)
  .byte %11000011
  .byte %11000011
  .byte %11111111
  .byte %11111111
  .byte %11000011
  .byte %11000011
  .byte %11000011
  .byte $00, $00, $00, $00, $00, $00, $00, $00

  .byte %11111111	; E (01)
  .byte %11111111
  .byte %11000000
  .byte %11111100
  .byte %11111100
  .byte %11000000
  .byte %11111111
  .byte %11111111
  .byte $00, $00, $00, $00, $00, $00, $00, $00

  .byte %11000000	; L (02)
  .byte %11000000
  .byte %11000000
  .byte %11000000
  .byte %11000000
  .byte %11000000
  .byte %11111111
  .byte %11111111
  .byte $00, $00, $00, $00, $00, $00, $00, $00

  .byte %01111110	; O (03)
  .byte %11100111
  .byte %11000011
  .byte %11000011
  .byte %11000011
  .byte %11000011
  .byte %11100111
  .byte %01111110
  .byte $00, $00, $00, $00, $00, $00, $00, $00