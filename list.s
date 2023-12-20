;;;
;; list.nes - a small library to maintain big lists on the NES.
;;
;; Copyright (C) Miquel Sabaté Solà <mikisabate@gmail.com>
;;
;; This library is free software: you can redistribute it and/or modify
;; it under the terms of the GNU Lesser General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.
;;
;; This library is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU Lesser General Public License for more details.
;;
;; You should have received a copy of the GNU Lesser General Public License
;; along with this library.  If not, see <https://www.gnu.org/licenses/>.

.p02

;; Initialize a new list which starts at the given 16-bit address.
.macro LIST_INIT address
    lda #.lobyte(address)
    sta List::ptr
    sta List::last
    lda #.hibyte(address)
    sta List::ptr + 1
    sta List::last + 1
.endmacro

;; For an already initialized list, reset the `List::ptr` variable so the list
;; can be iterated with functions like `List::get`.
.macro LIST_IT_FROM address
    lda #.lobyte(address)
    sta List::ptr
    lda #.hibyte(address)
    sta List::ptr + 1
.endmacro

;; Move the `List::ptr` variable so to point to the next element.
.macro LIST_NEXT
    clc
    lda #1
    adc List::ptr
    sta List::ptr
    lda #0
    adc List::ptr + 1
    sta List::ptr + 1
.endmacro

;;;
;; List provides the scope for the variables and subroutines that have been
;; defined in order to maintain and manipulate big lists on the NES.
;;
;; This library can also work for smaller list but there are other more
;; performant ways to achieve the same thing. Thus, use this library only if you
;; need to have a list that may store more than 255 bytes and indexing in the
;; usual ways might be a problem otherwise.
;;
;; For more information on the usage and the API check the documentation
;; (README.md file on the https://github.com/mssola/list.nes repository).
.scope List
    ;; NOTE (important): this library needs 4 bytes ($60-$63) to store
    ;; information of this list. These are two 16-bit pointers which are used
    ;; for the subroutines being defined here. If you have a clash with these
    ;; memory addresses, do feel free to change them, but remember that the code
    ;; assumes that both pointers are 16-bit (they don't need to be contiguous).
    ptr  = $60
    last = $62

    ;; Set the value of `a` into the list and advance one position without
    ;; growing the list.
    ;;
    ;; Use this function instead of `List::push` if you have already set
    ;; `List::ptr` as desired (e.g. with `LIST_IT_FROM`) and you just want to
    ;; set a specific value to this address. That is, the list has already been
    ;; defined somewhere else and you are just modifying some position.
    ;;
    ;; If the list pointer is already at the end and the operation is not
    ;; possible, then `y` is set to $FF, otherwise `y` will be set to 0.
    ;;
    ;; NOTE: registers modified: `a` and `y`.
    .proc set
        tay

        ;; Check if `List::ptr` >= `List::last` (16-bit comparison). If this is
        ;; the case, then we are actually done, otherwise we can proceed to set
        ;; the value as desired.
        lda List::ptr + 1
        cmp List::last + 1
        bcc @do
        bne @done
        lda List::ptr
        cmp List::last
        bcc @do
    @done:
        ;; We were actually done: set `y` to `$FF` to denote "end of list".
        ldy #$FF
        lda #0
        rts
    @do:
        tya
        ldy #0
        sta (List::ptr), y

        LIST_NEXT

        rts
    .endproc

    ;; Push the value of `a` after the last position of the list and grow one
    ;; more byte.
    ;;
    ;; Note that this subroutine assumes that we are already at the last item of
    ;; the list. Hence, if you reset `List::ptr` (e.g. with `LIST_IT_FROM`) and
    ;; then call this subroutine, you will also move the `List::last` pointer
    ;; accordingly and thus you might have (accidentally) shrinked the list. If
    ;; this is not a behavior that you want (you just want to set a value at a
    ;; specific location), then take a look at `List::set` instead.
    ;;
    ;; NOTE: registers modified: `a` and `y`.
    ;; NOTE: this subroutine might set the carry flag.
    .proc push
        ldy #0
        sta (List::ptr), y

        clc
        lda #1
        adc List::ptr
        sta List::ptr
        sta List::last
        lda #0
        adc List::ptr + 1
        sta List::ptr + 1
        sta List::last + 1
        rts
    .endproc

    ;; Get the contents of the current position of the list pointer and advance
    ;; it.
    ;;
    ;; The byte will be stored into the 'a' register. If the list pointer is
    ;; already at the end and won't fetch relevant data, then `y` is set to $FF,
    ;; otherwise `y` will be set to 0.
    ;;
    ;; NOTE: registers modified: 'a' and 'y'.
    ;; NOTE: this subroutine might set the carry flag.
    .proc get
        ;; Check if `List::ptr` >= `List::last` (16-bit comparison). If this is
        ;; the case, then we are actually done, otherwise we can proceed to
        ;; fetch the value as desired.
        lda List::ptr + 1
        cmp List::last + 1
        bcc @do
        bne @done
        lda List::ptr
        cmp List::last
        bcc @do
    @done:
        ;; We were actually done: set `y` to `$FF` to denote "end of list" and
        ;; zero out the returned value.
        ldy #$FF
        lda #0
        rts
    @do:
        ;; Fetch the value and push it into the stack since `LIST_NEXT` will
        ;; actually mess with the `a` register.
        ldy #0
        lda (List::ptr), y
        pha

        LIST_NEXT

        ;; Get the value back from the stack so to set the proper return value.
        pla

        rts
    .endproc
.endscope
