	.inesprg 1 ;1x16kb PRG code
	.ineschr 1 ;1x8kb CHR data
	.inesmap 0 ;mapper 0 = NROM, no bank swapping
	.inesmir 1 ;background/vertical mirroring

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
	.bank 0
	.org $C000
;bank 0 ( $C000-$DFFF ) 8191 bytes or ~8KiB

RESET:
	SEI
	CLD
	LDX #$40
	STX $4017
	LDX #$FF
	TXS
	INX
	STX PPUCTRL 
	STX PPUMASK
	STX SND_DELTA_REG

vblankwait1:
	BIT PPUSTATUS   ;tests value at $2002 and copies it to SR (status register NV-ZDIC)
	BPL vblankwait1 ;branch on N status register being 0 (so any positive result X>=0)

;internal RAM  2047 bytes    ( $0000-$07FF )
;program RAM   2047 bytes    ( $6000-$7FFF )

;according to nesdev wiki, ram $200,x needs to be set to $EE-$FF but here it's being set to $00. This may cause graphical problems down the road.

clearmem:
	LDA #$00
	STA $0000, x
	STA $0100, x
	;STA $0200, x
	STA $0300, x
	STA $0400, x
	STA $0500, x
	STA $0600, x
	STA $0700, x ;remove this line if you want data to persist past a reset.
	LDA #$FF
	STA $0200, x
	INX
	BNE clearmem

vblankwait2:
	BIT PPUSTATUS
	BPL vblankwait2

ENABLEPALETTES:
	LDA PPUSTATUS ;from $2002 read PPU status to reset the high/low latch to high.
	LDA #$3F
	STA PPUADDR ;to $2006 write the high byte of the $3F10 address
	LDA #$10
	STA PPUADDR ;to $2006 write the low byte of the $3F10 address


	LDX #$00
PPUCOPYPALETTEDATA:
	LDA PALETTE, x
	STA PPUDATA
	INX
	CPX #$20 ;32 in decimal
	BNE PPUCOPYPALETTEDATA
;branches until x=dec(32) or hex (#$20)
;.db = 16 bits of background palette
;.db = 16 bits of sprite palette
;total = 32 bits

PREPARESPRITEDATA:
	LDX #$00
PPUCOPYSPRITEDATA:
	LDA SPRITES, x
	STA $0200, x
	INX
	CPX #20
	BNE PPUCOPYSPRITEDATA
	
	LDA #%10000000   ; enable NMI, sprites from Pattern Table 1
	STA PPUCTRL
	LDA #%00010000   ; enable sprites
	STA PPUMASK

Forever:
	JMP Forever

NMI:
	LDA #$00
	STA OAMADDR ;$2003
	LDA #$02
	STA OAMDMA  ;$4014

	RTI

	.bank 1
	.org $E000
PALETTE:
	.db $0F,$08,$28,$16,$0F,$35,$36,$37,$0F,$39,$3A,$3B,$0F,$3D,$3E,$0F  ;background palette 
        .db $0F,$29,$15,$14,$0F,$02,$38,$26,$0F,$29,$15,$14,$0F,$02,$38,$26  ;sprite palette
SPRITES:
	;vert ;tile ;attr ;horiz
	.db $80,$32,$00,$80
	.db $80,$33,$00,$88
	.db $88,$34,$00,$80
	.db $88,$35,$00,$88

	.org $FFFA
	.dw NMI
	.dw RESET
	.dw 0
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	.bank 2
	.org $0000
	.incbin "mario.chr" ;include presetcharmap
