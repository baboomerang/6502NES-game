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
  ;       we could reuse the existing graphics

  PPU_ENABLE_RENDERING
::forever:
  nop
  jsr draw_hello_to_oam
  nop
  lda #1
  sta ZP_NMI_STATUS_NEEDS_NMI
  nop
  sta ZP_NMI_STATUS_NEEDS_DMA
  nop
  jsr ppu_wait_for_vblank
  jmp ::forever


; NMI happens once every 29,658 CPU cycles
; VBlank lasts for ~2273 CPU cycles
nmi_handler:
  php    ;3
  pha    ;3
  txa    ;2
  pha    ;3
  tya    ;2
  pha    ;3
  ; Total 18 cycles
  lda ZP_NMI_STATUS_NEEDS_NMI
  beq ::end_nmi
  lda #00
  sta ZP_NMI_STATUS_NEEDS_NMI

::ppu_dma:
  lda ZP_NMI_STATUS_NEEDS_DMA
  beq ::ppu_draw
  PPU_BEGIN_OAM_DMA_TRANSFER $0200
  lda #00
  sta ZP_NMI_STATUS_NEEDS_DMA

::ppu_draw:
  lda ZP_NMI_STATUS_NEEDS_DRAW
  beq ::ppu_reg
  bit PPUSTATUS
  ;jsr draw                    ; Copy bytes from buffer to PPU
  lda #00
  sta ZP_NMI_STATUS_NEEDS_DRAW

::ppu_reg:
  lda ZP_NMI_STATUS_NEEDS_PPU_REG
  beq ::pads
  ;lda soft_PPUCTRL            ; Copy buffered $2000/$2001 writes
  sta PPUCTRL
  ;lda soft_PPUMASK
  sta PPUMASK
  ;setscroll xscroll, yscroll
  lda #00
  sta ZP_NMI_STATUS_NEEDS_PPU_REG

::pads:
  lda ZP_NMI_STATUS_NEEDS_PADS
  beq ::end_nmi
  ;jsr readpad                 ; Update current pad
  lda #00
  sta ZP_NMI_STATUS_NEEDS_PADS

::end_nmi:
  jsr music_engine
  pla    ;4
  tay    ;2
  pla    ;4
  tax    ;2
  pla    ;4
  plp    ;4
  ; Total 22 cycles
  rti    ;6

draw_hello_to_oam:
  ldx #$00
loop:	
  lda hello, x                  ; Load the hello message into accumulator
  sta CPU_SHADOW_OAM_ADDRESS, x ; Store byte into Shadow OAM $0200 (indexed)
  inx
  cpx #$1c
  bne loop
  rts

irq_handler:
  rti

hello:
  .byte $ff, $00, $00, $ff 	; Why do I need these here?
  .byte $ff, $00, $00, $ff
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