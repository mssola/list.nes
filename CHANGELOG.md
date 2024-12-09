## v1.0

Initial version with a `list.s` file which implements the `List` scope. This
scope defines two 16-bit pointers from which you can manipulate a list, but they
are more useful when used together with the macros `LIST_INIT`, `LIST_IT_FROM`
and `LIST_NEXT`; and the functions `set`, `push` and `get`.
