## list.nes

This is a small library that allows NES developers to maintain and
manipulate big lists on the system.

The use case for this is indeed rare for NES games, where you usually have an
already defined table or an array with a fixed small size (or at least not
huge). That being said, I encountered this problem while solving [day 4 of
Advent of Code 2023](https://adventofcode.com/2023/day/4) (see my repo
[mssola/aoc2023.nes](https://github.com/mssola/aoc2023.nes)), in which I needed
to manipulate a list of around 600 bytes. This was a bit tricky to get right and
it added a bunch of code that was unrelated to the challenge itself. Hence, I
extracted the logic into this library and tuned things down from the lessons I
learnt along the way.

Moreover, you could also use this library to keep track of small lists, but you
have to keep in mind that pointer arithmetics and bound checks can hinder
performance. In other words, if you have a small list (less or equal than what
it can be addressed with an 8-bit index), then it's not worth the trouble: there
are other more performant ways to achieve the same thing. In short, this library
is useful only when indexing this list requires 16-bit arithmetic.

It's all pretty simple but being assembly code it comes with some gotchas that
you need to be aware of.

### Installing

You need to copy the code into some vendor directory, or add this repository as
a git submodule. After doing that, simply `.include` it in your code and it's
ready to be used.

As for the memory mapping, please do note that this library needs 4 bytes in
order to store two 16-bit pointers that keep track of the list. By default these
4 bytes are located at \$60-\$63. If that clashes with something from your code,
simply change these variables, named `List::ptr` and `List::last`. Each of these
pointers are 16-bit long (hence 2 bytes long), and they don't need to be in
continguous memory locations.

### Creating a list

In order to create a list you don't need to reserve a whole memory location in a
fixed way. Rather, what you do is to set the `List::ptr` and the `List::last`
pointers to the beginning of the memory from which your list will grow. Thus,
it's up to you to set this to a valid memory address which is free for as many
bytes as you'll need. This library will not try to avoid possible clashes and
will simply grow mindlessly as long as you keep pushing data to it.

And so, what are these pointers? `List::ptr` stores the memory location in
little endian format in which the current read/write will happen, while
`List::last` stores the last memory address in which a push happened. That is,
`List::last` resolves to how big your list is, while `List::ptr` is simply an
iterator over this list. Hence, in order to "create" a list you have to set both
these pointers to the same memory address, or simply use the provided
`LIST_INIT` macro, which asks for a full 16-bit address:

``` assembly
LIST_INIT $0400
;; now you have a list that starts at memory address $0400.
```

### Pushing data

The most basic operation from this library is `List::push`, which will push a
new value to the list and grow it by one byte. Example:

``` assembly
LIST_INIT $0400

;; The value to be pushed has to be stored into the `a` register.
lda #2
jsr List::push
;; now your list is: [$02] ($0400: $02).

lda #$F0
jsr List::push
;; now your list is: [$02, $F0] ($0400: $02, $0401: $F0).

;; and so on...
```

Note that both the `a` and the `y` registers will be affected after calling
`List::push`, and that the carry flag might also be set.

### Getting data

Now that you have pushed data, it would be cool to actually get it back! For
that you have two ways. First of all, you can perform a load with indirect
addressing by using the `List::ptr` pointer. Hence, the following allows you to
fetch the item at memory address `$0401`:

``` assembly
lda #$01
sta List::ptr
lda #$04
sta List::ptr + 1

ldy #0
lda (List::ptr), y
```

Note that there is a macro which resets the iterator pointer called
`LIST_IT_FROM`. Hence, the previous code could have been written like so:

``` assembly
LIST_IT_FROM $0401

ldy #0
lda (List::ptr), y
```

This is convenient for random access, but when you are iterating over the list
it might be tedious to move the pointer over and over. This is why there is also
the `LIST_NEXT` macro, which will move the `List::ptr` pointer for you:

``` assembly
LIST_IT_FROM $0401

ldy #0
lda (List::ptr), y

LIST_NEXT ;; so `List::ptr` points to $0402.
```

But doing things like this there is the gotcha that you don't know when to stop
if you are just iterating over the whole list. In order to solve this problem
there is another way of fetching data: the `List::get` function. This function
works like this:

1. Try to fetch the value on `List::ptr`.
2. If `List::ptr` is already at the end of the list, it will set `a` to `0` and
   `y` to `$FF`.
3. If not, then the value will be copied to `a` and `y` will be set to `0`.
4. Move `List::ptr` to the next element if possible.

This way you can come up with a code like this:

``` assembly
;; Imagine we have a list already initialized at $0400. Let's reset the `List::ptr`
;; so to start iterating from there.
LIST_IT_FROM $0400

@loop:
  jsr List::get
  cpy #$FF
  beq @done
  ;; do whatever with the value on `a`.
  jmp @loop
@done:
  ;; move on...
```

This way you don't have to care about pointers or anything: just set where you
want to start iterating your list, and call `List::get` until `y` has an `$FF`
value. Note though that, because of the implicit pointer arithmetic, the carry
flag and others might have been updated after you have called this function.

### Setting values without growing the list

As we have seen with `List::push`, this subroutine will also move the
`List::last` pointer, so our list grew on each push. Now let's say that we have
already initialized a list at `$0400` and we want to set some values without
growing the list any further. One way would be to, again, just use the
`List::ptr` variable:

``` assembly
LIST_IT_FROM $0402

lda #1
ldy #0
sta (List::ptr), y
```

But again, when doing it while iterating this can be a bit tedious. That's why
there is the `List::set` function. Here you'd have:

``` assembly
LIST_IT_FROM $0402
lda #1
jsr List::set
;; `List::ptr` has been moved to point to $0403 so you can use it on the next iteration.
```

And again, this `List::set` function works in the same way as `List::get`, in
which the `y` register contains whether the operation could be performed or not.
That is, if we were at the end of the list, then `y` is set to `$FF`, otherwise
to `0`. This again is pretty convenient when performing a loop:

``` assembly
;; Imagine we have a list at $0400. Let's reset the `List::ptr` so to start
;; iterating from there.
LIST_IT_FROM $0400

@loop:
  lda #2
  jsr List::set
  cpy #$FF
  bne @loop
  ;; move on...
```

Finally, keep in mind that this function, besides updating the `a` and the `y`
registers, will also update the carry flag.

### Putting it all together

You can check out an example in the [examples/mul.s](./examples/mul.s) file.
Otherwise you can also see it being used in real life on my solution for [day 4
of Advent of Code
2023](https://github.com/mssola/aoc2023.nes/blob/main/src/4.s).

## License

Released under the [LGPLv3+](http://www.gnu.org/licenses/lgpl-3.0.txt),
Copyright (C) 2023-<i>Ω</i> Miquel Sabaté Solà.
