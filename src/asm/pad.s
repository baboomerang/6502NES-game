;-------------------------------------------------
; src/asm/pad.s
; Pad (Joypad/Controller) Subroutines
;-------------------------------------------------
.include "../include/nes2header.inc"
.include "../include/global.inc"


.segment "ZEROPAGE"
current_pad: .res 1

.segment "CODE"
; Improved controller read code: 133 cycles compared to 154 cycles
; Uses only 1 register and is also DPCM safe
;    bit:   7 6 5 4 3 2 1 0
; button: 	A B S S U D L R

; Read buttons from controller 1
pad_read_joy_1:
    lda #1
    sta current_pad ;set up ring counter with 1 as start
    sta JOY1        ;enable button polling
    lsr a           ;set acumulator 0, shift bit into carry
    sta JOY1        ;disable polling
@loop:
    lda JOY1        ;get 1 button from pad
    lsr a           ;add buttons
    rol current_pad
    bcc @loop       ;loop until the starting bit "1" shifts left into carry
    rts


moveplayer:
    rts
