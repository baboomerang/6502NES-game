    .inesprg 1  ;1x16kb PRG code
    .ineschr 1  ;1x8kb CHR DATA
    .inesmap 0  ;mapper 0 = NROM, no bank switching
    .inesmir 1  ;backgorund/vertical mirroring

PPUCTRL		 = $2000
PPUMASK 	 = $2001
PPUSTATUS	 = $2002
PPU_SPR_ADDR = $2003 ;OAMADDR
OAMADDR		 = $2003

PPU_SPR_DATA = $2004 ;OAMDATA
OAMDATA		 = $2004

PPU_SCROLL_REG = $2005 ;PPUSCROLL
PPUSCROLL	 = $2005

PPUADDR		 = $2006
PPUDATA		 = $2007

SND_DELTA_REG = $4010 ;DMC_FREQ
DMC_FREQ	 = $4010

SPR_DMA		 = $4014 ;OAMDMA
OAMDMA		 = $4014

JOY1		 = $4016
JOY2		 = $4017
APU_IO		 = $4018 ;goes from ($4018-$401F) CPU test functions/testmode

    .rsset $0000
controller  .rs 1
controller2 .rs 1
worldptr    .rs 2

    .bank 0
    .org $C000
RESET:
    SEI        ;disable interrupts
    CLD        ;disable decimal mode
    LDX #$40
    STX $4017  ;disable sound
    LDX #$FF
    TXS        ;init stack
    INX
    STX PPUCTRL ;turn off ppu
    STX PPUMASK ;turn off ppu mask
    STX SND_DELTA_REG ;disable PCM channel
    JSR ppuwait

CLEARMEM:
    STA $0000, X ;$0000 --> $00FF
    STA $0100, X ;$0000 --> $01FF
    STA $0300, X ;$0000 --> $03FF
    STA $0400, X
    STA $0500, X
    STA $0600, X
    STA $0700, X ;$0700 --> $07FF
    LDA #$FF
    STA $0200, X ;storing a value other than 0 so sprites dont appear on-screen
    LDA #$00
    INX
    BNE CLEARMEM
    JSR ppuwait

;tell the ppu that .... (check the comment below this line)
    LDA #$02
    STA OAMDMA   ;tell ppu that the sprite data starts in cpu ram $02XX (high byte) 
; So we can write and change sprite data at any point from now on, 
; and sprites will show in the next vblank.


;----------------------------------------------------------------------------------


;tell the ppu where to store palette data and load it into 3F00
    NOP          ;give an extra cycle for the ppu
PPUPALETTEINIT:
    LDA PPUSTATUS
    LDA #$3F
    STA PPUADDR
    LDA #$00
    STA PPUADDR

    LDX #$00
LOADPALETTE:
    LDA PALETTEDATA, X
    STA PPUDATA
    INX
    CPX #$20      ;decimal 32, hex 20
    BNE LOADPALETTE


;load sprite data into CPU ram $0200 so it can be displayed at next vblank
    LDX #$00
LOADSPRITE:
    LDA SPRITEDATA, X
    STA $0200, X
    INX
    CPX #$20
    BNE LOADSPRITE



;tell ppu to write to nametable
    BIT PPUSTATUS
    LDA #$20
    STA PPUADDR
    LDA #$00
    STA PPUADDR

    ;;background updates must be done before an NMI, disable nmi if you have to.
    ;;indirect indexing assumes a 16 bit (double byte) pointer not an 8 byte one
    ;;so low byte and high byte pointers are next to each other in zeropage
    ;;so the low byte is combined with the high byte by default
    LDA #LOW(WORLDBIN)
    STA worldptr
    LDA #HIGH(WORLDBIN)
    STA worldptr+1

;pointers have been set, write to nametable now
    LDX #$00
    LDY #$00
WRITEBG:
    LDA [worldptr], Y
    STA PPUDATA
    INY
    CPY #$00
    BNE WRITEBG

    CPX #$03
    BEQ ENABLEPPU
    INX
    INC (worldptr+1)
    JMP WRITEBG


ENABLEPPU:         
    CLI            ;enable interrupts
    LDA #%10010000 ;enable nmi and use second chr set of tiles ($1000)
    STA PPUCTRL
    LDA #%00011110 ;enable background, sprites, sprite on vblank border, greyscale=0
    STA PPUMASK

forever:
    JMP forever

;;do not put game logic code in NMI
;;nmi has very little time to update graphics + game logic. Please be smart
NMI:
    LDA #$02
    STA OAMDMA      ;tell ppu to load sprite data from cpu ram $0200
    RTI



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; SUB ROUTINES
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ppuwait:
    BIT PPUSTATUS
    BPL ppuwait    ;loop until negative scanline index (negative = vblank/NMI time)
    TXA
    RTS

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;;;;;;;;;;;;;;;;;;;;;;;;
;;;; DATA BANKS
;;;;;;;;;;;;;;;;;;;;;;;;

    .bank 1
    .org $E000
PALETTEDATA:
    .db $15,$11,$28,$15,  $15,$35,$36,$37,  $15,$39,$3A,$3B,  $15,$21,$23,$01  ;background palette
    .db $0F,$24,$36,$08,  $0F,$02,$38,$26,  $0F,$29,$15,$14,  $0F,$02,$38,$26  ;sprite palette

SPRITEDATA:
	.db $7A,$32,$00,$7A
	.db $7A,$33,$00,$82
	.db $82,$34,$00,$7A
	.db $82,$35,$00,$82

WORLDBIN:
    .incbin "world.bin"

    .org $FFFA
    .dw NMI     ; processor will jump to the label NMI
    .dw RESET   ; when the processor first turns on or is reset, jump to lebel RESET
    .dw 0       ; external IRQ disabled

    .bank 2
    .org $0000
    .incbin "mario2.chr"
