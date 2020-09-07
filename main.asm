    .inesprg 1  ;1x16kb PRG code
    .ineschr 1  ;1x8kb CHR DATA
    .inesmap 0  ;mapper 0 = NROM, no bank switching
    .inesmir 1  ;background/vertical mirroring

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

JOY1	     = $4016
JOY2		 = $4017
APU_IO		 = $4018 ;goes from ($4018-$401F) CPU test functions/testmode

    .enum $0000
gamestate    .dsb 1
drawflag     .dsb 1
nametblflag  .dsb 1
scrollflag   .dsb 1
spriteflag   .dsb 1

menumode     .dsb 1
playermode   .dsb 1

prev_pad     .dsb 1
curr_pad     .dsb 1
prev_pad2    .dsb 1
curr_pad2    .dsb 1

worldptr     .dsb 2
playerptr    .dsb 2
    .ende

;;;;;;;;;;;;;;;;;;;;;;; CONSTANTS

r_butt  = 1 << 0
l_butt  = 1 << 1
d_butt  = 1 << 2
u_butt  = 1 << 3
start   = 1 << 4
select  = 1 << 5
b_butt  = 1 << 6
a_butt  = 1 << 7

;;;;;;;;;;;;;;;;;;;;;;; MACROS

    ;12 cycles
    .macro OAMUPDATE j
    LDA #<j      ;get the lowbyte of j
    STA OAMADDR  
    LDA #>j      ;get the highbyte of j
    STA OAMDMA   ;begin transfer to ppu
    .endm

    .macro SETPTR ptr, data
    LDA #<data    ;get the lowbyte of data
    STA ptr
    LDA #>data    ;get the highbyte of data
    STA ptr+1     ;result is little-endian pointer to target address
    .endm

    .macro SETPPUADDR j
    BIT PPUSTATUS    ;reset ppu latch (for safety)
    LDA #>j          ;store highbyte FIRST
    STA PPUADDR
    LDA #<j          ;then store lowbyte SECOND
    STA PPUADDR
    .endm

    .macro LDSPR spritedata, targetaddr, size
    LDX #$00
    -:
    LDA spritedata, X    ;load indexed copy of sprite to shadow oam
    STA targetaddr, X    ;store that respectively in shadow oam 
    INX
    CPX size             ;copy bytes until given size
    BNE -
    .endm

;;;;;;;;;;;;;;;;;;;;;;; CODE

    ;bank 0 (will be mapped at $C000-$DFFF)
    .base $C000
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

    OAMUPDATE #$0200

    SETPPUADDR #$3F00
    LDX #$00
LOADPALETTE:
    LDA palettedata, X
    STA PPUDATA
    INX
    CPX #$20
    BNE LOADPALETTE

    ;write titlescreen array
    LDA #$5C
    STA $0400
    LDA #$6C
    STA $0401
    LDA #$7C
    STA $0402
    LDSPR titlesprite, #$0200, #4
    SETPTR playerptr, #$0200


BG:
    SETPTR worldptr, titlebin
    SETPPUADDR #$2000   ;set target address to first nametable
    LDX #$00
    LDY #$00
@WRITEBG:
    LDA (worldptr), Y
    STA PPUDATA
    INY
    CPX #$03
    BNE @CHECKY
    CPY #$C0
    BEQ @DONE
@CHECKY:
    CPY #$00
    BNE @WRITEBG
    INX
    INC (worldptr+1)    ;increment the high byte of the pointer
    JMP @WRITEBG
@DONE:
    JSR ENABLEPPU


Engine:
    INC spriteflag

    JSR PLAYERMOVEMENT
    JSR ENEMYMOVEMENT
    
    JSR MUSICENGINE

    JSR PPUWAIT
    JMP Engine

NMI:
    PHP   ;3
    PHA   ;3
    TXA   ;2
    PHA   ;3
    TYA   ;2
    PHA   ;3
    ;total 18 cycles
    LDA curr_pad
    STA prev_pad

    BIT PPUSTATUS   ;reset latch
    JSR READJOY1    ;133 cycles

    LDA spriteflag
    BEQ +
    OAMUPDATE #$0200

    LDA #0
    STA spriteflag  ;latch the dma flag when done
+: 
    PLA   ;4
    TAY   ;2
    PLA   ;4
    TAX   ;2
    PLA   ;4
    PLP   ;4
    ;total 22 cycles
    RTI   ;6

IRQ:
    ;irrelevant since NROM is hardwired with no IRQ nor bank-switch support
    ;leaving it here incase it inspires someone else
    RTI

;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;; MUSIC ENGINE      ;
;;;;;;;;;;;;;;;;;;;;;;;;;;

MUSICENGINE:
    LDY #$FF    ;best music engine in the world
    RTS

;;;;;;;;;;;;;;;;;;;;;;;;
;;;; SUBROUTINES       ;
;;;;;;;;;;;;;;;;;;;;;;;;

PPUWAIT:
    BIT PPUSTATUS
    BPL PPUWAIT
    RTS

ENABLEPPU:
    CLI            ;enable interrupts
    LDA #%10010000 ;enable nmi and use second chr set of tiles ($1000)
    STA PPUCTRL
    LDA #%00011110 ;enable background, sprites, sprites on vblankborder, greyscale=0
    STA PPUMASK
    RTS

DISABLEPPU:
    SEI            ;disable interrupts
    LDA #%00010000 ;disable nmi
    STA PPUCTRL
    LDA #%00000000 ;disable background, sprites, and sprites on vblankborder
    STA PPUMASK
    RTS

;improved controller read code: 133 cycles compared to 154 cycles
;uses only 1 register and is also DPCM safe
;bit        7   6     5       4      3   2       1       0    
;button 	A 	B 	Select 	Start 	Up 	Down 	Left 	Right 
READJOY1:       ;16 cycles first part
    LDA #1           ;                                                    ;2 odd
    STA curr_pad     ;set up ring counter with 1 as start                 ;3 even
    STA JOY1         ;enable button polling                               ;4 even 
    LSR A            ;set accumulator to 0                                ;2 even
    STA JOY1         ;disable polling                                     ;4 even
-:                   ;111 cycles for 8 loops
    LDA JOY1         ;load 1 bit at a time. Total 8 bits need to be read  ;4 even
    LSR A            ;accumulator into carry                              ;2 even
    ROL curr_pad     ;rotate out of carry into variable                   ;5 odd
    BCC -            ;carry will be 0 once all 8 buttons are loaded       ;3 even
    RTS              ;+6 cycles

PLAYERMOVEMENT:
    LDA curr_pad
    BEQ @END
@a:
    BIT a_butt
    BNE +
@b:
    BIT b_butt
    BNE +
@start_:
    BIT start
    BNE +
@select_:
    BIT select
    BNE +
@left:
    BIT l_butt
    BNE +
@right:
    BIT r_butt
    BNE +
@up:
    BIT u_butt
    BNE +
    CPX
@down:
    BIT d_butt
    BNE +
@END:
    LDA $0400, X
    STX menumode
    LDY #0
    STA (playerptr), Y
    RTS
    .pad $E000

;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;; GRAPHICS DATA        ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;

    ;bank 1 (will be mapped $E000 - $FFFF)
    .base $E000
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
    .db $5C,$75,$03,$32
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
    .dw NMI
    .dw RESET
    .dw IRQ

    ;bank 2 (will be mapped to $0000-$1FFF in the PPU)
    ;somehow it is implied by asm6f that any chr data
    ;at the end of the reset vector declaration will
    ;go automatically in the PPU - thank you NROM mapper
    ;its so dumb but whatever. nobody talks about this
    .incbin "mario2.chr" 
