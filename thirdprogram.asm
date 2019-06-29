	.inesprg 1 ;1x 16kb PRG code
	.ineschr 1 ;1x 8kb CHR data
	.inesmap 0 ;mapper 0 = NROM, no bank swapping
	.inesmir 1 ;background mirroring
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	.bank 0
	.org $C000

RESET:
	SEI	   ;disable IRQ
	CLD 	   ;disable decimal mode
	LDX #$40
	STX $4017  ;disable APU frame IRQ
	LDX #$FF
	TXS	   ;start stack
	INX	   ;X becomes 0 on increment
	STX $2000  ;setting value to FF disables NMI interrupt
	STX $2001  ;disables rendering on reset (blank screen)
	STX $4010  ;disable DMC IRQs(?)

vblankwait1:
	BIT $2002
	BPL vblankwait1

;skip clearing $200. Normally, Ram page 2 is used for display list to be copied to OAM. OAM needs to be initialized to $EF-$FF, not 0, or a bunch of garbage sprites will show at (0,0)

clearmem:
	LDA #$00
	STA $0000, x
	STA $0100, x
	STA $0200, x
	STA $0400, x
	STA $0500, x
	STA $0600, x
	STA $0700, x ; remove this line if you're storing reset-persistent data
	LDA #$FE
	STA $0300, x
	INX
	BNE clearmem

vblankwait2:
	BIT $2002
	BPL vblankwait2 ;wait for second vblank. THIS TIME THE PPU IS READY

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
EnablePalettes:
	LDA $2002    ; read PPU status to reset the high/low latch to high
	LDA #$3F
	STA $2006    ; write the high byte of $3F10 address
	LDA #$10
	STA $2006    ; write the low byte of $3F10 address
;by writing to the 2 ppu control registers, the next data will be written to $3F10: a region in the PPU Mirror section in the CPU available RAM
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	LDX #$00                ; start out at 0
LoadPalettesLoop:
	LDA PaletteData, x      ; load data from address (PaletteData + the value in x)
				; 1st time through loop it will load PaletteData+0
				; 2nd time through loop it will load PaletteData+1
				; 3rd time through loop it will load PaletteData+2
				; etc
	STA $2007               ; write to PPU
	INX                     ; X = X + 1
	CPX #$20                ; Compare X to hex $20, decimal 32
	BNE LoadPalettesLoop    ; Branch to LoadPalettesLoop if compare was Not Equal to zero
				; if compare was equal to 32, keep going down
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	LDA #%00100000   ;intensify blues
	STA $2001
	LDA #$80
	STA $0200        ; put sprite 0 in center ($80) of screen vert
	STA $0203        ; put sprite 0 in center ($80) of screen horiz
	LDA #$00
	STA $0201        ; tile number = 0
	STA $0202        ; color = 0, no flipping

	LDA #%10000000   ; enable NMI, sprites from Pattern Table 0
	STA $2000

	LDA #%00010000   ; enable sprites
	STA $2001

Forever:
	JMP Forever ;loop forever 


NMI:			 ; enable direct memory access transfer from cpu ram to ppu sprite memory
	LDA #$00
	STA $2003  ; set the low byte (00) of the RAM address
	LDA #$02
	STA $4014  ; set the high byte (02) of the RAM address, start the transfer
;at this point, transfer begins automatically. THIS HAS TO BE AT THE BEGINNING OF THE VBLANK code

	RTI ;return back to wherever it was called.

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	.bank 1
	.org $E000
testpalette:
	.db $0F,$31,$32,$33,$0F,$35,$36,$37,$0F,$39,$3A,$3B,$0F,$3D,$3E,$0F  ;background palette data
	.db $0F,$1C,$15,$14,$0F,$02,$38,$3C,$0F,$1C,$15,$14,$0F,$02,$38,$3C  ;sprite palette data

	.org $FFFA
	.dw NMI
	.dw RESET
	.dw 0

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	.bank 2
	.org $0000
	.incbin "mario.chr" ; include a preset charmap 
