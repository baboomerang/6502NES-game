.include "../include/nes.inc"

;-------------------------------------------------
; Init Code Segment
;-------------------------------------------------
.segment "CODE"

reset_handler:
    sei             ; Disable maskable interrupts (IRQ) during initialization
    cld             ; Disable decimal mode (standard 6502 practice, though the NES 2A03 CPU ignores it)
    ldx #$40
    stx $4017       ; Disable APU frame irq
    ldx #$ff
    txs             ; Transfer X to Stack Pointer (SP is now $01FF, the top of the stack)
    inx             ; Increment X from $FF to $00 (due to overflow)
    stx PPUCTRL     ; Disable NMI
    stx PPUMASK     ; Disable rendering (blank screen)
    stx DMC_FREQ    ; Disable DMC IRQ

    ; Wait one frame for the PPU to warm up
    jsr ppuwait

    txa             ; Set register A equal to the value of register X (which is $00). Set A to 0 basically.
@clearmem:
    sta $0000, x    ; Clear Zero Page ($0000 - $00FF)
    sta $0100, x    ; Clear Stack area ($0100 - $01FF)
    sta $0300, x    ; Clear general RAM ($0300 - $03FF)
    sta $0400, x
    sta $0500, x
    sta $0600, x
    sta $0700, x    ; Clear general RAM up to $07FF
    lda #$ff
    sta $0200, x    ; Store $FF to OAM Shadow RAM area: Moves all sprites offscreen by default (Y-coord $FF)
    lda #00
    inx
    bne @clearmem
    oamupdate $0200

    ; Wait another frame for the PPU to warm up (should be good now)
    ; Tip: if you want to wait for vblank again after this reset, then you should wait for NMI to run.
    jsr ppuwait

    jmp main_handler ; Jump to main game code