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
gamestate   .rs 1
controller  .rs 1
controller2 .rs 1
worldptr    .rs 2

    .bank 0
    .org $C000
RESET:
    SEI         ;disable interrupts
    CLD         ;disable decimal mode
    LDX #$40
    STX $4017   ;disable sound
    LDX #$FF
    TXS         ;init stack
    INX
    STX PPUCTRL ;turn off ppu
    STX PPUMASK ;turn off ppu mask
    STX DMC_FREQ ;disable PCM channel
    STX gamestate ;set gamestate to titlescreen

    JSR PPUWAIT

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
    
    LDA #$02
    STA OAMDMA   ;tell ppu the sprite data lives in cpuram $0200
        
    JSR PPUWAIT

;tell ppu where to store the palettedata
    LDA PPUSTATUS
    LDA #$3F
    STA PPUADDR
    LDA #$00
    STA PPUADDR

    LDX #$00
LOADPALETTE:
    LDA PALETTEDATA, X
    STA PPUDATA
    INX CPX #$20
    BNE LOADPALETTE

;load sprites into cpu ram
    LDX #$00
LOADSPRITE:
    LDA SPRITEDATA, X
    STA $0200, X
    INX
    CPX #$20
    BNE LOADSPRITE




MODESELECT:
    LDA gamestate
    CMP #$01            ;if gamestate is 1, load world instead
    BEQ loadworld       ;else load title instead
loadtitle:
    LDA #LOW(TITLEBIN)
    STA worldptr
    LDA #HIGH(TITLEBIN)
    STA worldptr+1
    JMP BG
loadworld:
    LDA #LOW(WORLDBIN)
    STA worldptr
    LDA #HIGH(WORLDBIN)
    STA worldptr+1
BG:
    LDX #$00
    LDY #$00
WRITEBG:
    LDA [worldptr], Y
    STA PPUDATA
    INY
    CPX #$03
    BNE CHECKY
    CPY #$C0
    BEQ DONE
CHECKY:
    CPY #$00
    BNE WRITEBG
    INX
    INC (worldptr+1)
    JMP WRITEBG
DONE:
    JSR ENABLEPPU



Engine:
    JSR READJOY1
    JMP Engine

NMI:
    LDA #$02
    STA OAMDMA
    RTI

;;;;;;;;;;;;;;;;;;;;;;;;
;;;; SUBROUTINES
;;;;;;;;;;;;;;;;;;;;;;;;

PPUWAIT:
    BIT PPUSTATUS
    BPL PPUWAIT
    RTS

PAUSEPPU:
    SEI            ;disable interrupts
    LDA PPUCTRL
    ASL A          ;clear bit 7
    LSR A          ;shift %0 into bit 7
    STA PPUCTRL    ;disable nmi
    LDA #%00011110 ;enable background, sprites, sprite on vblank border, greyscale=0
    STA PPUMASK
    RTS

ENABLEPPU:
    CLI            ;enable interrupts
    LDA #%10010000 ;enable nmi and use second chr set of tiles ($1000)
    STA PPUCTRL
    LDA #%00011110 ;enable background, sprites, sprite on vblank border, greyscale=0
    STA PPUMASK
    RTS

READJOY1:
    LDA #$01
    STA JOY1    ;enable button polling for 5 cpu cycles
    LDA #$00
    STA JOY1    ;disable button polling
    LDX #$08
READJOY1LOOP:
    LDA JOY1       ;load 1 bit at a time (loop 8 times to get the whole byte)
    LSR A          ;shift 1 bit from A into carry
    ROL controller ;rotate out of carry into controller variable
    DEX            ;once x is zero, zero flag is set
    BNE READJOY1LOOP ;loop until x is zero
    RTS

;;;;;;;;;;;;;;;;;;;;;;;;
;;;; DATA BANKS
;;;;;;;;;;;;;;;;;;;;;;;;

    .bank 1
    .org $E000
palettedata:
    .db $15,$11,$28,$15,  $15,$35,$36,$37,  $15,$39,$3A,$3B,  $15,$21,$23,$01  ;background palette
    .db $0F,$24,$36,$08,  $0F,$02,$38,$26,  $0F,$29,$15,$14,  $0F,$02,$38,$26  ;sprite palette

spritedata:
	.db $7A,$32,$00,$7A
	.db $7A,$33,$00,$82
	.db $82,$34,$00,$7A
	.db $82,$35,$00,$82

titlebin:
    .incbin "titlescreen.bin"
worldbin:
    .incbin "world.bin"

    .org $FFFA
    .dw NMI     ; processor will jump to the label NMI
    .dw RESET   ; when the processor first turns on or is reset, jump to lebel RESET
    .dw 0       ; external IRQ disabled

    .bank 2
    .org $0000
    .incbin "mario2.chr"
