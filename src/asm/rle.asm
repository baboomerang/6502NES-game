;RLE decompressor by Shiru (NESASM version)
;uses 4 bytes in zero page
;decompress data from an address in X/Y to PPU_DATA

RLE_LOW		equ $00
RLE_HIGH	equ RLE_LOW+1
RLE_TAG		equ RLE_HIGH+1
RLE_BYTE	equ RLE_TAG+1

.segment "ZEROPAGE"
pointer: .res 1

.segment "CODE"
unrle:
	stx RLE_LOW
	sty RLE_HIGH
	ldy #0
	jsr rle_byte
	sta RLE_TAG
:loop1:
	jsr rle_byte
	cmp RLE_TAG
	beq :loop2
	sta PPU_DATA
	sta RLE_BYTE
	bne :loop1
:loop2:
	jsr rle_byte
	cmp #0
	beq :loop4
	tax
	lda RLE_BYTE
:loop3
	sta PPU_DATA
	dex
	bne :loop3
	beq :loop1
:loop4
	rts

rle_byte:
	lda [RLE_LOW],y
	inc RLE_LOW
	bne :skip
	inc RLE_HIGH
:skip:
	rts

; Decompress RLE-Encoded data and write data to PPUDATA
; Depends on: get_byte() function
decode_rle:
    ldy #00
    jsr get_byte
    sta rle_tag         ;first byte is rle tag delimiter
@readbyte:
    jsr get_byte
    cmp rle_tag
    beq @getlen         ;if the next value is a tag, get the length of repeats
    sta PPUDATA         ;else copy single byte to PPU RAM
    sta rle_val         ;and save a copy of that value
    bne @readbyte
@getlen:
    jsr get_byte
    cmp #00             ;if length is 0, then it is EOF
    beq @end
    tax                 ;else set x = length
    lda rle_val         ;set accumulator to rle value
@copyloop:
    sta PPUDATA         ;write rle value until x = 0
    dex
    bne @copyloop
    beq @readbyte       ;loop entire function until EOF (rle_tag, 00) byte pair
@end:
    rts

; Get a byte from a 16-bit pointer and post-increment the Y register
get_byte:
    lda (pointer), y  ; This should work if 'pointer' is defined in ZP
    iny
    bne @end
    inc pointer+1
@end:
    rts