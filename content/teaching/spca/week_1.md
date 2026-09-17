---
title: Week 1
---

## Undefined Behavior

As discussed in the lectures, some things in C are undefined, and depending on which compiler and which optimization level you use, some unexpected things could happen which you should be aware of!

Have a look [here](https://en.cppreference.com/c/language/behavior) for some interesting examples of undefined behavior which may produce counterintuitive results.

### Signed Integer Overflow

How do you check if the sum of two integers overflows, given that your machine architecture implements wrap-around semantics?

Try 1:

```c
bool does_overflow(int x, int y) {
    if (y > 0) {
        return x + y < x;
    }
    // can only underflow
    return false;
}
```

This should work with `-O0` (ie. unoptimized build). However, compiling with `-O1` and greater, this will generally return false. Exploiting the properties of signed overflow does not work, as the compiler assumes either `x + y > x` (given `y > 0`) or something is off, which means it can do pretty much whatever it wants. Since signed overflow is undefined behavior, the compiler is free to assume it never happens, and eliminating the check leads to less emitted code and a potential execution speedup. The only thing that remains is `return false` which is what you will likely get as output for every invocation of this function. 

Try 2: 

```c
bool does_overflow(int x, int y) {
    if (y > 0) {
        // x + y > MAX_INT ==> x > MAX_INT - y
        return x > MAX_INT - y;
    }
    return false;
}
```

This should always return the correct answer as none of the operations lead to overflow.

Extra: 

Binary search may seem like a "trivial" algorithm, and you may even have implemented it during your A&D Coding Exam.
However, it appears to be quite tricky to get right, whith many textbooks priting incorrect implemenations (at least according to [this](https://dl.acm.org/doi/epdf/10.1145/52964.53012) paper from 1988). Even if you search the internet today for an implementation, you'll find plenty of versions that do:

```c
int binary_search(...) {
    int low = ...;
    int high = ...;

    while (low <= high) {
        int mid = (low + high) / 2; // potential overflow
    }
}
```

This can overflow if you work with very large arrays. When I asked Claude to "give me a binary search algo in C please", it immediately spit out a version that had `int mid = low + (high - low) / 2` together with a comment next to it `avoids overflow vs (low + high) / 2` so it seems this issue has been discussed extensively enough taht models mention it unprompted.

Extra: 

As learned in DDCA, x86 sets the overflow flag (OF) when the addition of two numbers overflows. The easiest way to test for overflow is therefore to just look at this flag. Before you start writing inline assembly, it's worth knowing that Clang and GCC expose many compiler intrinsics (i.e. functions not defined in the C standard library or elsewhere, but directly by the compiler) that are usually thin wrappers around instructions like this.

One of these functions is 

```c
bool __builtin_add_overflow(int a, int b, int *res);
```

This roughly compiles to (optimized): 

```shell
xor %eax, %eax  # %eax <- 0
add %esi, %edi  # %edi <- arg1 + arg2
seto %al        # %al <- overflow bit
ret  
```

### Code Instrumentation

If you want to catch every potential overflow bug in your program at runtime (by aborting the program), you can compile your code with `-fsanitize=undefined`. This links your code against the UBSan runtime library (`libubsan`), which contains functions such as `__ubsan_handle_add_overflow`. Just like `__builtin_add_overflow`, these functions check the overflow flag, and if it is set, they call a corresponding handler that reports the error and aborts the program.

## Bitwise Operators

Integer constants in C are by default interpreted as `int`. 

If you use constants for shifting, make sure to add a suffix `U` (unsigned), `UL` (unsigned long), `L` (long), etc. after them to prevent undefined behavior!

The compiler usually warns you about this, (make sure to use `-Wall`, to see all warnings), but this may slip by in the exam if you are stressed :)

eg. Check if a 64 bit integer is negative without `<` / `>` ...: 

```c
bool is_negative(int64_t x) {
    return x & (1UL << 63);
}
```

