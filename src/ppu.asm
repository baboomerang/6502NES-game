; Wait until PPU is ready to render
ppuwait:
    bit PPUSTATUS
    bpl ppuwait
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
; Input: 16-bit pointer
get_byte:
    lda (pointer), y
    iny
    bne @end
    inc (pointer+1)
@end:
    rts

; Copy bytes of data from the drawing buffer to PPUDATA
draw:
    rts

; Load a full uncompressed nametable (1024 bytes) from PRG rom to PPUDATA
; Input: 16-bit pointer
loadnametable_full:
    ldx #$00
    ldy #$00
@write:
    lda (pointer), y    ;load byte at address (pointer + y)
    sta PPUDATA
    iny
    cpx #$03
    bne @check_y
    cpy #$c0
    beq @end
@check_y:
    cpy #$00
    bne @write
    inx
    inc (pointer+1)     ;increment the high byte of the pointer ONLY
    jmp @write
@end:
    rts
