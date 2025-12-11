;-------------------------------------------------
; Macros
;-------------------------------------------------

.macro oamupdate addr
    lda #<addr       ;get the low byte of addr
    sta OAMADDR
    lda #>addr       ;get the high byte of addr
    sta OAMDMA       ;latch and begin transfer to ppu
.endm

.macro setscroll xsel, ysel
    bit PPUSTATUS    ;reset ppu latch
    lda xsel
    sta PPUSCROLL    ;set x scroll
    lda ysel
    sta PPUSCROLL    ;set y scroll
.endm

.macro setppu addr
    bit PPUSTATUS    ;reset ppu latch
    lda #>addr       ;get the high byte first
    sta PPUADDR
    lda #<addr       ;get the low byte second
    sta PPUADDR
.endm

.macro setptr ptr, addr
    lda #<addr       ;get the low byte first
    sta ptr
    lda #>addr       ;get the high byte second
    sta ptr+1
.endm

.macro enableppu
    cli              ;clear interrupt-disable bit (enable interrupts)
    lda #10000000b   ;enable nmi and use second set of chr tiles ($1000)
    sta PPUCTRL
    lda #00011110b   ;enable background, sprites, sprites on vblank border, disable grayscale
    sta PPUMASK
.endm

.macro disableppu
    sei              ;set interrupt-disable bit (disable interrupts)
    lda #00000000b   ;disable nmi, still use second set of chr tiles
    sta PPUCTRL
    lda #00          ;disable all graphics, enable grayscale mode
    sta PPUMASK
.endm
