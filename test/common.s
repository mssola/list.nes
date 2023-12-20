.segment "HEADER"
    .byte 'N', 'E', 'S', $1A

    .byte $02
    .byte $01

    .byte $00
    .byte $00

.segment "VECTORS"
    .addr nmi, reset, irq

.segment "CHARS"
.segment "STARTUP"
.segment "CODE"

.include "../list.s"

reset:
    sei
    cld

    ldx #$40
    stx $4017

    ldx #$ff
    txs

    inx
    stx $2000
    stx $2001
    stx $4010

@vblankwait1:
    bit $2002
    bpl @vblankwait1

    ldx #0
    lda #0
@ram_reset_loop:
    sta $000, x
    sta $100, x
    sta $300, x
    sta $400, x
    sta $500, x
    sta $600, x
    sta $700, x
    inx
    bne @ram_reset_loop

    lda #$ef
@sprite_reset_loop:
    sta $200, x
    inx
    bne @sprite_reset_loop

    lda #$00
    sta $2003
    lda #$02
    sta $4014

@vblankwait2:
    bit $2002
    bpl @vblankwait2

    lda #$3F
    sta $2006
    lda #$00
    sta $2006

    lda #$0F
    ldx #$20
@palettes_reset_loop:
    sta $2007
    dex
    bne @palettes_reset_loop

    jmp main

;; Unused
nmi:
irq:
    rti
