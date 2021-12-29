;-------------------------------------------------
; iNES header
;-------------------------------------------------
.inesprg 2 ;2x16kb PRG code
.ineschr 1 ;1x8kb CHR data
.inesmap 0 ;mapper 0 = NROM, no bank switching
.inesmir 1 ;background/vertical mirroring

;-------------------------------------------------
; NES Constants
;-------------------------------------------------
.incsrc nes.inc

;-------------------------------------------------
; Macros
;-------------------------------------------------
.incsrc macros.asm

;-------------------------------------------------
; Variables
;-------------------------------------------------
.enum $0000
    gamestate    .dsb 1
    needs_nmi    .dsb 1
    needs_dma    .dsb 1
    needs_draw   .dsb 1
    needs_ppureg .dsb 1
    needs_pads   .dsb 1
    xscroll      .dsb 1
    yscroll      .dsb 1
    soft_PPUCTRL .dsb 1
    soft_PPUMASK .dsb 1
    curr_pad     .dsb 1
    pointer      .dsb 2 ;general purpose global pointer
    rle_tag      .dsb 1 ;used in ppu.asm for rle decoding
    rle_val      .dsb 1 ;used in ppu.asm for rle decoding
.ende

;-------------------------------------------------
; Program Bank(s)
;-------------------------------------------------

    ;bank 0 (will be mapped at $8000-$bfff)
    .org $8000
reset_handler:
    sei             ;disable maskable interrupts
    cld             ;disable decimal mode
    ldx #$40
    stx $4017       ;disable APU frame irq
    ldx #$ff
    txs             ;init stack
    inx
    stx PPUCTRL     ;disable nmi
    stx PPUMASK     ;disable rendering
    stx DMC_FREQ    ;disable dmc irq
    jsr ppuwait
    txa
@clearmem:
    sta $0000, x
    sta $0100, x
    sta $0300, x
    sta $0400, x
    sta $0500, x
    sta $0600, x
    sta $0700, x
    lda #$ff
    sta $0200, x    ;ff value moves sprites offscreen
    lda #00
    inx
    bne @clearmem
    oamupdate $0200

main:
    ;load background and sprite palettes
    setppu $3f00
    ldx #00
@loadpal:
    lda palette, x
    sta PPUDATA
    inx
    cpx #32
    bne @loadpal

    ;load titlescreen at the first nametable
    setppu $2000
    setptr pointer, titlescreen
    jsr decode_rle

    ;enable ppu with certain features
    bit PPUSTATUS
    lda #VBLANK_NMI|NT_2000|BG_0000|OBJ_1000
    sta PPUCTRL
    lda #BG_ON|OBJ_ON
    sta PPUMASK
    jsr ppuwait

main_loop:
    inc needs_nmi
    lda #>(@end-1)
    pha
    lda #<(@end-1)
    pha
@switch:
    lda gamestate
    asl
    tax
    lda state_table+1, x
    pha
    lda state_table, x
    pha
    rts             ;jump to a subroutine based on the gamestate
@end:
    inc needs_pads
    jsr ppuwait     ;spin until nmi
    jmp main_loop


bit_table:
    .db KEY_RIGHT, KEY_LEFT, KEY_DOWN, KEY_UP
    .db KEY_START, KEY_SELECT, KEY_B, KEY_A
state_table:
    .dw TITLE_CODE-1, INGAME_CODE-1, GAMEOVER_CODE-1

;Code that runs specifically for the Titlescreen
TITLE_CODE:
    lda curr_pad
    bit bit_table+4 ;KEY_START
    beq :+
    lda #1
    sta gamestate   ;set gamestate to ingame
    ;TODO: perform gamestate transition
    ;loading level cutscene
    ;load intro level
    ;unpack rle
    ;set attributes
    ;spawn sprites
    ;spawn player
    ;set pointers to sprites and player
+:
    rts

;Code that runs specifically ingame
INGAME_CODE:
    jsr moveplayer
    rts

;Code that runs specifically for the Gameover screen
GAMEOVER_CODE:
    rts


;NMI happens once every 29,658 CPU cycles
;VBlank lasts for ~2273 CPU cycles
nmi_handler:
    php    ;3
    pha    ;3
    txa    ;2
    pha    ;3
    tya    ;2
    pha    ;3
    ;total 18 cycles
    lda needs_nmi
    beq @end
    lda #00
    sta needs_nmi
    lda needs_dma
    beq :+
    oamupdate $0200
    lda #00
    sta needs_dma
+:
    lda needs_draw
    beq :+
    bit PPUSTATUS
    jsr draw         ;copy bytes from buffer to PPU
    lda #00
    sta needs_dma
+:
    lda needs_ppureg
    beq :+
    lda soft_PPUCTRL ;copy buffered $2000/$2001 writes
    sta PPUCTRL
    lda soft_PPUMASK
    sta PPUMASK
    setscroll xscroll, yscroll
    lda #00
    sta needs_ppureg
+:
    lda needs_pads
    beq :+
    jsr readpad      ;update current pad
    lda #00
    sta needs_pads
@end:
+   jsr music_engine
    pla    ;4
    tay    ;2
    pla    ;4
    tax    ;2
    pla    ;4
    plp    ;4
    ;total 22 cycles
    rti    ;6


irq_handler:
    rti


palette:
@background:;.db $ff,$36,$25,$14,$ff,$35,$36,$37
            ;.db $ff,$39,$3a,$3b,$ff,$21,$23,$01
            .incbin "../tilesets/title.pal"
@sprite:    .db $0f,$24,$36,$08,$0f,$02,$38,$26
            .db $0f,$29,$15,$14,$0f,$02,$38,$26

titlescreen:
.incbin "../tilesets/title.rle"

;-------------------------------------------------
; Subroutines
;-------------------------------------------------
.incsrc pad.asm
.incsrc ppu.asm
.incsrc apu.asm

;-------------------------------------------------
; Interrupt Vectors
;-------------------------------------------------
    .org $fffa
    .dw nmi_handler
    .dw reset_handler
    .dw irq_handler

;-------------------------------------------------
; CHR-ROM Bank
;-------------------------------------------------
.incbin "../tilesets/title.chr"
