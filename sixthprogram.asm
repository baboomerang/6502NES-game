    .inesprg 1  ;1x16kb PRG code
    .ineschr 1  ;1x8kb CHR data
    .inesmap 0  ;mapper 0 = NROM, no bank switching
    .inesmir 1  ;background/vertical mirroring

PPUCTRL		 = $2000
PPUMASK 	 = $2001
PPUSTATUS	 = $2002
PPU_SPR_ADDR	 = $2003 ;OAMADDR
OAMADDR		 = $2003

PPU_SPR_DATA	 = $2004 ;OAMDATA
OAMDATA		 = $2004

PPU_SCROLL_REG   = $2005 ;PPUSCROLL
PPUSCROLL	 = $2005

PPUADDR		 = $2006
PPUDATA		 = $2007

SND_DELTA_REG	 = $4010 ;DMC_FREQ
DMC_FREQ	 = $4010

SPR_DMA		 = $4014 ;OAMDMA
OAMDMA		 = $4014

JOY1		 = $4016
JOY2		 = $4017
APU_IO		 = $4018 ;goes from ($4018-$401F) CPU test functions/testmode

;zeropage
    .rsset $0000
controller  .rs 1
controller2 .rs 1

    .bank 0
    .org $C000
RESET:
    SEI   ;disable all interrupts
    CLD   ;disable decimal mode because its unsupported on the NES variant 6502
    LDX #$40   
    STX $4017    ;this disables sound interrupt request (sound IRQ)
    LDX #$FF     
    TXS          ;initialize stack register at FF (it decrements as data is pushed)
    INX          ;$FF ---> $00
    STX PPUCTRL  ;turn off ppu
    STX PPUMASK  ;turns off ppu mask
    STX SND_DELTA_REG ; disable the PCM channel so no random sounds

ppuwait:
    BIT PPUSTATUS
    BPL ppuwait
    TXA

CLEARMEM: ;store the value of the accumulator (should be #$00) into 2kb ram
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

ppuwait2:
    BIT PPUSTATUS
    BPL ppuwait2
   
;once ppu cycle count 
    LDA #$02
    STA OAMDMA   ;tell the ppu that the sprite data starts in ram $02XX (high byte) 
    NOP          ;give an extra cycle for the ppu
    
ENABLEPALETTES:
    LDA PPUSTATUS ;read from $2002 read ppu status to reset the latch to high.
    LDA #$3F
    STA PPUADDR  ;tell the ppu high byte of its own memory location
    LDA #$00
    STA PPUADDR  ;tell the ppu low byte of its own memory location
;ppu will start in its own private memory location at #$3F00 (separate from the cpu)
;ppu is ready by this point after this line

    LDX #$00
LOADPALETTE:
    LDA PALETTEDATA, X
    STA PPUDATA
    INX
    CPX #$20
    BNE LOADPALETTE

    LDX #$00
LOADSPRITE:
    LDA SPRITEDATA, X
    STA $0200, X
    INX
    CPX #$20
    BNE LOADSPRITE

;sprite data loaded, proceed with final setup
    CLI             ;enable interrupts again VERY IMPORTANT
    LDA #%10010000  ;enable NMI and use second chr set of tiles ($1000)
    STA PPUCTRL
    LDA #%00011110  ;enables background, sprites, show sprites on vblank borders, and
    STA PPUMASK     ;disables greyscale
;setup finished

Loop:
    JMP Loop

NMI:
    LDA #$02
    STA OAMDMA      ;copy sprite data from $0200 to $02FF to screen
    JSR READJOY1
    RTI

READJOY1:
    LDA #$01
    STA JOY1  ;enable console to poll buttons for one cpu cycle
    LDA #$00
    STA JOY1  ;disable polling buttons
    LDX #$08
READJOY1LOOP:
    LDA JOY1  ;load 1 bit at a time (must loop 8 times for the whole byte)
    LSR A
    ROL controller
    DEX       ;once x goes down to zero, zero flag is set
    BNE READJOY1LOOP ;loop until x = 0
    RTS       ;once x = 0, return from subroutine
 
    .bank 1
    .org $E000
PALETTEDATA:
	.db $0F,$11,$28,$0D,  $0F,$35,$36,$37,  $0F,$39,$3A,$3B,  $0F,$3D,$3E,$0F  ;background palette 
    .db $0F,$24,$36,$08,  $0F,$02,$38,$26,  $0F,$29,$15,$14,  $0F,$02,$38,$26  ;sprite palette

SPRITEDATA:
	.db $80,$32,$00,$80
	.db $80,$33,$00,$88
	.db $88,$34,$00,$80
	.db $88,$35,$00,$88


    .org $FFFA
    .dw NMI     ; a word is a double byte. Or two hex values $FE, $AF
    .dw RESET   ; $FFFA - $FFFF is 8 bytes, or 4 double bytes (2 words)
    .dw 0       ; all 3 vectors placed at the end of the cartridge

    .bank 2
    .org $0000
    .incbin "mario.chr"
