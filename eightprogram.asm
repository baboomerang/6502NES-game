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

SND_DELTA_REG  = $4010 ;DMC_FREQ
DMC_FREQ	 = $4010

SPR_DMA		 = $4014 ;OAMDMA
OAMDMA		 = $4014

JOY1		 = $4016
JOY2		 = $4017
APU_IO		 = $4018 ;goes from ($4018-$401F) CPU test functions/testmode

    .rsset $0000
gamestate   .rs 1
drawflag    .rs 1
nametblflag .rs 1
scrollflag  .rs 1
spriteflag  .rs 1

controller  .rs 1
controller2 .rs 1
worldptr    .rs 2
playerptr   .rs 2

r_butt  = 1 << 0
l_butt  = 1 << 1
d_butt  = 1 << 2
u_butt  = 1 << 3
start   = 1 << 4
select  = 1 << 5
b_butt  = 1 << 6
a_butt  = 1 << 7

    .macro AMP
    LDA \1
    AND \2
    CMP \2
    .endm

    ;13 cycles
    .macro STZ ; STZ $LLHH
    PHA        ;3
    LDA #$00   ;2
    STA \1     ;store zerovalue ;4
    PLA        ;4
    .endm

    ;12 cycles
    .macro OAMUPDATE ; OAMUPDATE #i, #i 
    LDA \1
    STA OAMADDR ;write lowbyte
    LDA \2
    STA OAMDMA  ;write highbyte, begin transfer immediately
    .endm

    .macro SETPTR ;SETPTR ptr*, $LLHH
    LDA #LOW(\2)
    STA \1        ;set the low byte of pointer to lowbyte of world address
    LDA #HIGH(\2)
    STA \1+1      ;set the high byte of pointer to highbyte of world address
    .endm
    
    ;257 cpu cycles = 2+(4+5+2+2+3)*16-1 , with sprite length 16
    ;formula: 16x-1 where x is the length of sprite
    ;                  source  dest. length
    .macro LDSPR ;LDSPR $LLHH, $LLHH, #i
    LDX #$00
.load\@
    LDA \1, X    ;copy indexed sprite by byte to shadow OAM
    STA \2, X
    INX
    CPX \3       ;loop until specified size
    BNE .load\@
    .endm


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
    
    OAMUPDATE #$00, #$02

;tell ppu where to store the palettedata
PPULOADPAL:
    LDA PPUSTATUS
    LDA #$3F
    STA PPUADDR
    LDA #$10
    STA PPUADDR
    LDX #$00
LOADPALETTE:
    LDA palettedata, X
    STA PPUDATA
    INX
    CPX #$20
    BNE LOADPALETTE


MODESELECT:
    LDA gamestate
    CMP #$01            ;if gamestate is 1, load world instead
    BEQ loadworld       ;else load title instead
loadtitle:
    SETPTR worldptr, titlebin
    LDSPR titlesprite, $0200, #$04
    SETPTR playerptr, $0200
    JMP BG
loadworld:
    SETPTR worldptr, worldbin

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
    INC (worldptr+1)    ;increment the high byte of the pointer
    JMP WRITEBG
DONE:
    JSR ENABLEPPU


;we have about 29780 cpu cycles to work with between each END OF RENDER
;and the rising edge of an NMI

Engine:
    JSR READJOY1    ;154 cycles, could be NMI'd at any point
    
    LDY #$01
    STY drawflag
    STY spriteflag

    JSR MUSICENGINE ;lets see, could be NMI'd too 
    JMP Engine

;PREVBLANK: 262 scanlines per frame, 341 PPU cycles per line, 1 pixel per clock
;ONCE NMI OCCURS: 2270 cycles between an NMI and START OF RENDER
NMI:
    PHP   ;3
    PHA   ;3
    TXA   ;2
    PHA   ;3
    TYA   ;2
    PHA   ;3
    ;total 18 cycles
    LDA drawflag
    BEQ END
    STZ drawflag            ;latch it immediately, avoid double NMI's permanently

DMA:
    LDA spriteflag
    BEQ NAME
    STZ spriteflag
    OAMUPDATE #$00, #$02

NAME:
    LDA nametblflag
    BEQ SCROLL
    STZ nametblflag
    ;JSR DECOMPRESSOR       ;lz77 decompressor into memory
    ;we have enough time to send ~180 bytes during vblank

SCROLL:
    LDA scrollflag
    BEQ END
    STZ scrollflag

END:
    PLA   ;4
    TAY   ;2
    PLA   ;4
    TAX   ;2
    PLA   ;4
    PLP   ;4
    ;total 22 cycles
    RTI   ;6

;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;; MUSIC ENGINE      ;
;;;;;;;;;;;;;;;;;;;;;;;;;;

MUSICENGINE:
    LDY #$FF    ;best music engine in the world
    RTS

;;;;;;;;;;;;;;;;;;;;;;;;
;;;; SUBROUTINES       ;
;;;;;;;;;;;;;;;;;;;;;;;;

PPUWAIT:        ;this could be a macro tbh
    BIT PPUSTATUS
    BPL PPUWAIT
    RTS

ENABLEPPU:
    CLI            ;enable interrupts
    LDA #%10010000 ;enable nmi and use second chr set of tiles ($1000)
    STA PPUCTRL
    LDA #%00011110 ;enable background, sprites, sprite on vblank border, greyscale=0
    STA PPUMASK
    RTS

;improved controller read code: 133 cycles compared to 154 cycles
READJOY1:     ;16 cycles first part
    LDA #$01
    STA JOY1         ;enable button polling
    STA controller   ;set up ring counter with 1 as start
    LSR A            ;set accumulator to 0
    STA JOY1         ;disable polling
READJOY1LOOP: ;111 cycles for 8 loops
    LDA JOY1         ;load 1 bit at a time. Total 8 bits need to be read
    LSR A            ;accumulator into carry
    ROL controller   ;rotate out of carry into variable
    BCC READJOY1LOOP ;carry will be 0 once all 8 buttons are loaded
    RTS              ;+6 cycles

;;;;;;;;;;;;;;;;;;;;;;;;
;;;; DATA BANKS        ;
;;;;;;;;;;;;;;;;;;;;;;;;

    .bank 1
    .org $E000
palettedata:
    .db $FF,$36,$25,$14   ;background palette
    .db $FF,$35,$36,$37
    .db $FF,$39,$3A,$3B
    .db $FF,$21,$23,$01
    .db $0F,$24,$36,$08   ;sprite palette
    .db $0F,$02,$38,$26
    .db $0F,$29,$15,$14 
    .db $0F,$02,$38,$26 

titlesprite:
    .db $5C,$28,$00,$32

playersprite:
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
