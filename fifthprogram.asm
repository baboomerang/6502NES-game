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

;8192 bytes = #$2000
;4096 bytes = #$1000
;2048 bytes = #$0800
;1024 bytes = #$0400
;512 bytes  = #$0200
;256 bytes  = #$0100
;===================================================================================

;variables and constants can be defined in the CPU zeropage(?) at the beginning prior to any bank/prgmem declaration

	.rsset $0000
gamestate	.rs 1
controller	.rs 1

	.bank 0
	.org $C000
;bank 0 ( $C000-$DFFF ) 8191 bytes or ~8KiB
;bank 0+n ( $E000 ) has to start at $E000

RESET:
	SEI
	CLD		;disable decimal mode (because the NES6502 doesn't support it unlike the standard version)
	LDX #$40
	STX $4017
	LDX #$FF
	TXS		;create a stack at location $FF and it goes downwards in x value as items are pushed to it
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
	;STA $0200, x ; if we set this value to 0, it will start hsowing garbage sprites
	STA $0300, x
	STA $0400, x
	STA $0500, x
	STA $0600, x
	STA $0700, x ;remove this line if you want data to persist past a reset.
	LDA #$FF
	STA $0200, x ;setting this address to ff hides the garbage sprites from the display. (which is good and necessary)
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

;between each drawn frame, we have a very small unit of time to run game code or update the sprites and that our NMI interrupt tells the NES in which part of the code should it jump to, to resume execution of code.
;TOTAL CLOCK CYCLES BETWEEN EACH VBLANK: ~2000 cycles (be efficient with your code please)

NMI:
	LDA #$00
	STA OAMADDR ;$2003 ;set the low byte (00) of the ram address
	LDA #$02
	STA OAMDMA  ;$4014 ;set the high byte (02) of the ram address, start the transfer
	;RTI       ;all the code i want to run has to fit within the vblank time

ENABLEREADCONTROLLERS:
	LDA #$01
	STA JOY1 ;$4016
	LDA #$00
	STA JOY1 ;$4016
;we have told the CPU to enable controller latching and prepare for our attempted readings
;theres an efficient way of reading the controllers and a non efficient way.
;heres the nonefficient way:

; ReadA:
;   LDA $4016       ; player 1 - A
;   AND #%00000001  ; only look at bit 0
;   BEQ ReadADone   ; branch to ReadADone if button is NOT pressed (0)
;                   ; add instructions here to do something when button IS pressed (1)
;   LDA $0203       ; load sprite X position
;   CLC             ; make sure the carry flag is clear
;   ADC #$01        ; A = A + 1
;   STA $0203       ; save sprite X position
; ReadADone:        ; handling this button is done
; 
; 
; ReadB:
;   LDA $4016       ; player 1 - B
;   AND #%00000001  ; only look at bit 0
;   BEQ ReadBDone   ; branch to ReadBDone if button is NOT pressed (0)
;                   ; add instructions here to do something when button IS pressed (1)
;   LDA $0203       ; load sprite X position
;   SEC             ; make sure carry flag is set
;   SBC #$01        ; A = A - 1
;   STA $0203       ; save sprite X position
; ReadBDone:        ; handling this button is done
;one has to branch off each button in sequence and this consumes tons of cycles I bet if we check all buttons on the controller this way

READCONTROLLERBUTTONS:
	LDA $4016	;load a
	ROR A
	ROL controller
	LDA $4016	;load b
	ROR A
	ROL controller
	LDA $4016	;load select
        ROR A
        ROL controller
	LDA $4016	;load start
        ROR A
        ROL controller
	LDA $4016	;up
        ROR A
        ROL controller
	LDA $4016	;down
        ROR A
        ROL controller
	LDA $4016	;left
        ROR A
        ROL controller
        LDA $4016	;right
        ROR A
        ROL controller	
	RTI		;this will make sure that the whole controller is read before returning to drawing the next frame

	.bank 1
	.org $E000
PALETTE:
	.db $0F,$08,$28,$16,  $0F,$35,$36,$37,  $0F,$39,$3A,$3B,  $0F,$3D,$3E,$0F  ;background palette 
        .db $0F,$29,$15,$14,  $0F,$02,$38,$26,  $0F,$29,$15,$14,  $0F,$02,$38,$26  ;sprite palette
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
