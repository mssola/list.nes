;;;
;; The definition of `RUN_TESTS` will be inserted automatically when running
;; tests. Do not insert the definition manually.

.include "common.s"


main:
.ifdef RUN_TESTS
    jsr suite
.endif
halt:
    jmp halt

;;;
;; Test suite

suite:
    jsr list_sum
    jsr list_empty_get
    jsr large_list
    jsr list_set
    jsr list_empty_set
    jsr list_set_overflow

    rts

;; This is re-used in both `list_sum` and `list_set`.
.macro LIST_SUM_AUX
    lda #0
    sta $90

    LIST_INIT $0400

    lda #2
    jsr List::push
    lda #4
    jsr List::push
    lda #1
    jsr List::push

    LIST_IT_FROM $0400
:
    jsr List::get
    cpy #$FF
    beq :+
    clc
    adc $90
    sta $90
    jmp :-
:
    nop
.endmacro

list_sum:
    LIST_SUM_AUX
@test_list_sum:
    rts

list_empty_get:
    LIST_INIT $0400
    jsr List::get
    cpy #$FF
    beq :+
    lda #0
    sta $90
    jmp @test_list_empty_get
:
    lda #1
    sta $90
@test_list_empty_get:
    rts

large_list:
    lda #0
    sta $90
    sta $91
    sta $92

    LIST_INIT $0400

    ldx #0
:
    txa
    jsr List::push

    ;; Are we about to overflow the `x` register? If so, check if this was the
    ;; first time or not. If so, then we let it overflow and loop again $FF
    ;; times. Otherwise we will stop the loop, since we want to have a
    ;; $200-sized list.
    cpx #$FF
    bne :+
    inc $92
    lda #2
    cmp $92
    beq :++
:
    inx
    jmp :--
:
    ;; At this point we have stored this big list, let's add things up.
    lda #0
    sta $90
    sta $91
    LIST_IT_FROM $0400
:
    jsr List::get
    cpy #$FF
    beq @test_large_list
    clc
    adc $90
    sta $90
    lda #0
    adc $91
    sta $91
    jmp :-

@test_large_list:
    rts

list_set:
    LIST_SUM_AUX

    lda #0
    sta $90

    LIST_IT_FROM $0400

    lda #3
    jsr List::set
    lda #5
    jsr List::set
    lda #2
    jsr List::set

    LIST_IT_FROM $0400
:
    jsr List::get
    cpy #$FF
    beq @test_list_set
    clc
    adc $90
    sta $90
    jmp :-
@test_list_set:
    rts

list_empty_set:
    LIST_INIT $0400
    jsr List::set
    cpy #$FF
    beq :+
    lda #0
    sta $90
    jmp @test_list_empty_set
:
    lda #1
    sta $90
@test_list_empty_set:
    rts

list_set_overflow:
    ;; $0402 should not be set by this function, and this is to be checked; so
    ;; zero it out before doing anything.
    lda #0
    ldy #0
    sta $0402

    LIST_INIT $0400
    lda #1
    jsr List::push
    lda #2
    jsr List::push

    LIST_IT_FROM $0400
    lda #2
    jsr List::set
    sty $90
    lda #4
    jsr List::set
    sty $91
    lda #6
    jsr List::set
    sty $92
@test_list_overflow:
    rts
