	.inesprg 1   ; 1x 16KB bank of PRG code
	.ineschr 1   ; 1x 8KB bank of CHR data
	.inesmap 0   ; mapper 0 = NROM, no bank swapping
	.inesmir 1   ; background mirroring (ignore for now)

;NESASM arranges everything in 8KB code and 8KB graphics banks. To fill the 16KB PRG space 2 banks are needed. Like most things in computing, the numbering starts at 0. For each bank you have to tell the assembler where in memory it will start.

	.bank 0
	.org $C000
	;insert code
RESET:
	SEI ;Disable IRQs
	CLD ;Disable Decimal mode
NMI:
	SEI
	CLD

	.bank 1
	.org $FFFA
	.dw NMI
	;called once per frame on vblank. processor will jump to the label NMI:

	.dw RESET 
	;called when processor is turned on or reset. processor will jump to the label RESET:
	
	.dw 0 ;external interrupt IRQ *DISABLED BY SETTING IT TO 0*

	.org $E000
	;insert more code
	;PPUMASK ($2001)
	LDA #%01000000 ;intensify blues and greens
	STA $2001
	
	.bank 2
	.org $0000
	;graphics always here

	.org $8000
MyFunction:    ;load hex FF into the accumulator
;STA MyFunction
;STA $8000
	LDA #$FF
	JMP MyFunction


