utils = require "utils"

utils.StartRun("Unit tests")

---
-- We push three elements and we sum them up. We expect a proper sum value
-- stored at $90, the items on $040{0, 1, 2} and the List pointers at the last
-- position.

utils.MemTest("@test_list_sum", {
                {0x60, "03"}, {0x62, "03"},                  -- List::{ptr, last} should be at the very end (one past the last written).
                {0x90, "07"},                                -- We pushed three elements: 2, 4, 1; and the sum is left in 0x90.
                {0x400, "02"}, {0x401, "04"}, {0x402, "01"}  -- The three elements pushed by this test.
})

---
-- We initialize an empty list and we try to call `get` with no elements. The
-- pointers should not move and the test function should set a `1` on $90 if
-- `get` set $FF to `y` (which is what we want).

utils.MemTest("@test_list_empty_get", {
                {0x60, "00"}, {0x62, "00"}, -- List::{ptr, last} did not advance.
                {0x90, "01"}                -- $FF was simply returned.
})

---
-- We initialize a large list ($200-sized) with the 8-bit index as a value
-- (hence 0-$FF twice). In $90-$91 we leave the sum of all the values.

utils.MemTest("@test_large_list", {
                {0x90, "00"}, {0x91, "FF"} -- (0..255) * 2 = 65280, which is 0xFF00 in hexadecimal.
})

---
-- We run the same code of `@test_list_sum` so to get a new three-sized array,
-- but then we overwrite the contents. This test makes sure that perform the sum
-- again gives us a new value and, hence, the previous values were actually
-- overwritten by `List::set`.

utils.MemTest("@test_list_set", {
                {0x60, "03"}, {0x62, "03"},                  -- List::{ptr, last} should be at the very end (one past the last written).
                {0x90, "0A"},                                -- We overwrote the three elements: 3, 5, 2; and the sum is left in 0x90.
                {0x400, "03"}, {0x401, "05"}, {0x402, "02"}  -- The three elements pushed by this test.
})

---
-- We initialize an empty list and we try to call `set` with no elements. The
-- pointers should not move and the test function should set a `1` on $90 if
-- `get` set $FF to `y` (which is what we want).

utils.MemTest("@test_list_empty_set", {
                {0x60, "00"}, {0x62, "00"}, -- List::{ptr, last} did not advance.
                {0x90, "01"}                -- $FF was simply returned.
})

---
-- We initialize a list with two elements, and then we try to call `List::set`
-- three times. The first two writes work, the third not.

utils.MemTest("@test_list_overflow", {
                {0x60, "02"}, {0x62, "02"},                  -- List::{ptr, last} should be at the very end (one past the last written).
                {0x90, "00"}, {0x91, "00"}, {0x92, "FF"},    -- We overwrote the three elements: 3, 5, 2; and the sum is left in 0x90.
                {0x400, "02"}, {0x401, "04"}, {0x402, "00"}  -- The three elements pushed by this test.
})

utils.EndRun()
