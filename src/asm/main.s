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

  PPU_SET_ADDR $2000
  LOAD_PTR ZP_RLE_POINTER, titlescreen
  jsr ppu_decode_rle

  PPU_ENABLE_RENDERING
::forever:
  inc ZP_NMI_STATUS_NEEDS_NMI
  lda #>(::end-1)
  pha
  lda #<(::end-1)
  pha                ; Set return point for the gamestate subroutine that will be called below
::state_machine:
  lda ZP_GAMESTATE   ; Current game state
  asl                ; Multiply by 2 (0 = 0, 1 = 2, 2 = 4)
  tax
  lda state_jump_table+1, x
  pha
  lda state_jump_table, x
  pha
  rts                ; Clever return "to" subroutine/Jump to a subroutine based on the gamestate
::end:
  inc ZP_NMI_STATUS_NEEDS_PADS
  jsr ppu_wait_for_vblank
  jmp ::forever

state_jump_table:
  .word (title_screen_tick-1)
  .word (in_game_tick-1)
  .word (game_over_tick-1)

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
  PPU_BEGIN_OAM_DMA_TRANSFER CPU_SHADOW_OAM_ADDRESS
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
  .incbin "../data/title.pal"

sprite_palette:
    .byte $0f,$24,$36,$08,$0f,$02,$38,$26
    .byte $0f,$29,$15,$14,$0f,$02,$38,$26

titlescreen:
  .incbin "../data/title.rle"

; Character memory
.segment "CHR"
  ;.byte %11000011	; H (00)
  ;.byte %11000011
  ;.byte %11000011
  ;.byte %11111111
  ;.byte %11111111
  ;.byte %11000011
  ;.byte %11000011
  ;.byte %11000011
  ;.byte $00, $00, $00, $00, $00, $00, $00, $00

  ;.byte %11111111	; E (01)
  ;.byte %11111111
  ;.byte %11000000
  ;.byte %11111100
  ;.byte %11111100
  ;.byte %11000000
  ;.byte %11111111
  ;.byte %11111111
  ;.byte $00, $00, $00, $00, $00, $00, $00, $00

  ;.byte %11000000	; L (02)
  ;.byte %11000000
  ;.byte %11000000
  ;.byte %11000000
  ;.byte %11000000
  ;.byte %11000000
  ;.byte %11111111
  ;.byte %11111111
  ;.byte $00, $00, $00, $00, $00, $00, $00, $00

  ;.byte %01111110	; O (03)
  ;.byte %11100111
  ;.byte %11000011
  ;.byte %11000011
  ;.byte %11000011
  ;.byte %11000011
  ;.byte %11100111
  ;.byte %01111110
  ;.byte $00, $00, $00, $00, $00, $00, $00, $00

  .incbin "../data/title.chr"