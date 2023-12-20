;;;
;; A silly example that tries to demonstrate how to use list.nes.
;;
;; It will initialize a list of 256 16-bit items with a value of 0..255
;; respectively. After doing that, it will multiply each value by 2 and store it
;; again. As a final touch, the second item will be forced to have the same
;; value for the high and the low bytes.
;;
;; You can check that this works by running `make example` and then running the
;; resulting ROM file into an emulator with a RAM inspector like FCEUX or Mesen.
;; Then go from memory address $0400 onwards and check that the results are as
;; described.

.include "../test/common.s"

main:
    LIST_INIT $0400

    ;; We will store 256 16-bit items and $90 will keep track of it.
    lda #0
    sta $90
@fill_loop:
    ;; The 16-bit item will have the value of the current index as stored in
    ;; $90. The list will be initialized through the `List::push` function, so
    ;; the size is properly set at the end.
    lda $90
    jsr List::push
    lda #0
    jsr List::push

    ;; If we have set all the items we wanted, move into the next thing,
    ;; otherwise increase $90 and go back into the loop.
    lda $90
    cmp #$FF
    beq @set
    inc $90
    jmp @fill_loop

@set:
    ;; Reset the pointer to the start of the list since we want to iterate it
    ;; over.
    LIST_IT_FROM $0400

@set_loop:
    ;; There are two values to keep track: `List::ptr` and `List::ptr + 1`. For
    ;; the low byte we need to shift left once, and then the high byte needs to
    ;; add the possible carry to itself. In order to do this and call
    ;; `List::set` properly we need to be do some stuff with the stack (low
    ;; byte) or the `x` register (high byte).
    ldy #0
    lda (List::ptr), y
    asl
    pha

    lda #0
    iny
    adc (List::ptr), y
    tax

    ;; Pull the value that corresponds to the low byte and set it. After doing
    ;; that, though, did we get a $FF value? If so then it means that we are
    ;; done with it, otherwise proceed to grab the high byte stored on the `x`
    ;; registerm set it with `List::set` and loop again.
    pla
    jsr List::set
    cpy #$FF
    beq @final_get
    txa
    jsr List::set
    jmp @set_loop

@final_get:
    ;; We are done! Now for a final touch let's copy the value from the low byte
    ;; into the high byte of the second element.
    LIST_IT_FROM $0402

    jsr List::get
    jsr List::set

done:
    jmp done
