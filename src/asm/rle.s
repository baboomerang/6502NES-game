;RLE decompressor by Shiru (NESASM version)
;uses 4 bytes in zero page
;decompress data from an address in X/Y to PPUDATA
.include "../include/global.inc"
.include "../include/zeropage.inc"

.segment "CODE"
ppu_rle_decode_direct:
	ldy #0				    ; Y is used as offset for indirect addressing
	; Read the initial tag byte and store it
	lda (ZP_RLE_POINTER),y
	sta ZP_RLE_TAG
	jsr inc_zp_ptr_y	; Increment pointer

::loop_byte:
	; Read next byte
	lda (ZP_RLE_POINTER),y
	jsr inc_zp_ptr_y	; Increment pointer

	cmp ZP_RLE_TAG    ; Is it a run tag?
	bne ::output_byte ; No, output the single byte

::run_detected:
	; Yes, it's a run tag. Read the run length.
	lda (ZP_RLE_POINTER),y
	jsr inc_zp_ptr_y	; Increment pointer

	; Handle end-of-stream (length 0)
	beq ::end_of_stream

	; Start of a run. Length is in A.
	tax					      ; Length to X for countdown
	lda ZP_RLE_SELECTED_BYTE ; Get the value to repeat

::output_run:
	sta PPUDATA			  ; Output repeated byte
	dex					      ; Decrement counter
	bne ::output_run	; Loop if not done
	jmp ::loop_byte		; Unconditional jump back to the main loop

::output_byte:
	; Not a run tag. Output the byte and store as last written byte.
	sta PPUDATA
	sta ZP_RLE_SELECTED_BYTE
	jmp ::loop_byte

::end_of_stream:
	rts

; --- Helper subroutine to increment a 16-bit zero-page pointer ---
; Clobbers A
inc_zp_ptr_y:
	inc ZP_RLE_POINTER	 ; Increment the low byte ($00)
	; BNE checks the Z (Zero) flag set by the INC instruction.
    ; If ZP_RLE_POINTER was $FF, it becomes $00 (Z flag is set), the BNE *fails*
    ; and drops through to increment the high byte. This is correct logic.
	bne ::skip_inc_high	 ; If low byte is non-zero, no carry to high byte.
	inc ZP_RLE_POINTER+1 ; Else, increment the high byte ($01).
::skip_inc_high:
	rts

; Decompress RLE-Encoded data and write data to PPUDATA
; Depends on: get_byte() function
ppu_decode_rle:
    ldy #00
    jsr get_byte
    sta ZP_RLE_TAG         ;first byte is rle tag delimiter
@readbyte:
    jsr get_byte
    cmp ZP_RLE_TAG
    beq @getlen         ;if the next value is a tag, get the length of repeats
    sta PPUDATA         ;else copy single byte to PPU RAM
    sta ZP_RLE_SELECTED_BYTE         ;and save a copy of that value
    bne @readbyte
@getlen:
    jsr get_byte
    cmp #00             ;if length is 0, then it is EOF
    beq @end
    tax                 ;else set x = length
    lda ZP_RLE_SELECTED_BYTE         ;set accumulator to rle value
@copyloop:
    sta PPUDATA         ;write rle value until x = 0
    dex
    bne @copyloop
    beq @readbyte       ;loop entire function until EOF (ZP_RLE_TAG, 00) byte pair
@end:
    rts

; Get a byte from a 16-bit pointer and post-increment the Y register
get_byte:
    lda (ZP_RLE_POINTER),y  ; This should work if 'pointer' is defined in ZP
    iny
    bne @end
    inc ZP_RLE_POINTER+1
@end:
    rts