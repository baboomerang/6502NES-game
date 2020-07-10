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
playerptr   .rs 1

;r_butt  =   %00000001  ;#$01
;l_butt  =   %00000010  ;#$02
;d_butt  =   %00000100  ;#$04
;u_butt  =   %00001000  ;#$08
;start   =   %00010000  ;#$10
;select  =   %00100000  ;#$20
;b_butt  =   %01000000  ;#$40
;a_butt  =   %10000000  ;#$80

r_butt  = $01
l_butt  = $02
d_butt  = $04
u_butt  = $08
start   = $10
select  = $20
b_butt  = $40
a_butt  = $80

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
    LDA palettedata, X
    STA PPUDATA
    INX
    CPX #$20
    BNE LOADPALETTE

;load sprites into cpu ram
    LDX #$00
LOADSPRITE:
    LDA spritedata, X
    STA $0200, X
    INX
    CPX #$20
    BNE LOADSPRITE



MODESELECT:
    LDA gamestate
    CMP #$01            ;if gamestate is 1, load world instead
    BEQ loadworld       ;else load title instead
loadtitle:
    LDA #LOW(titlebin)
    STA worldptr        ;set the pointer to title screen
    LDA #HIGH(titlebin)
    STA worldptr+1
    JMP BG
loadworld:
    LDA #LOW(worldbin)
    STA worldptr        ;set the pointer to world screen
    LDA #HIGH(worldbin)
    STA worldptr+1

BG:
    BIT PPUSTATUS       ;tell ppu to store data in nametable
    LDA #$20
    STA PPUADDR
    LDA #$00
    STA PPUADDR

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

    JMP Engine

NMI:
    ;PHA
    ;TXA
    ;PHA
    ;TYA
    ;PHA
    ;performing controller code reads are weird
    
    LDA #$00
    JSR READJOY1

    LDA controller          ;load #%xxxx xxxx
    CMP #u_butt             ;compare 2F to 08
    BCC SKIPMOVE            ;if they are the same skip draw
    INC $0203

SKIPMOVE:
    LDA #$02
    STA OAMDMA

    JSR MusicEngine
    ;your code above this line

    ;PLA
    ;TAY
    ;PLA
    ;TAX
    ;PLA
    RTI

;;;;;;;;;;;;;;;;;;;;;;;;
;;;; SUBROUTINES       ;
;;;;;;;;;;;;;;;;;;;;;;;;

MusicEngine:
    RTS

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
    LDA #%00001110 ;enable background, sprites, sprite on vblank border, greyscale=0
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
;;;; DATA BANKS        ;
;;;;;;;;;;;;;;;;;;;;;;;;

    .bank 1
    .org $E000
palettedata:
    .db $15,$36,$25,$14,  $15,$35,$36,$37,  $15,$39,$3A,$3B,  $15,$21,$23,$01  ;background palette
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
    .incbin "mario.chr"
