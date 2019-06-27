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


	LDA #%00100000   ;intensify blues
	STA $2001

Forever:
	JMP Forever ;loop forever 
NMI:
	;insert code here
	RTI ;return back to wherever it was called.

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	.bank 1
	.org $FFFA
	.dw NMI
	.dw RESET
	.dw 0

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	.bank 2
	.org $0000
	.incbin "mario.chr" ; include 8kb charmap from smb1
