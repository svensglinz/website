---
Title: Week 4
---

## Memory allocation

In the lecture, you should have learned about the differences between static, automatic and dynamic memory allocation. 

### Static Memory

Static allocation means that the memory for your variables, arrays, etc. is "baked into" your binary. (If the data is all zeros, the binary only contains metadata telling the operating system to allocate (and zero) that memory at program startup.)

This applies to things such as `static` variables. If two consecutive function calls read from a statically allocated variable, they get the same value back, so this data clearly cannot live on the stack.

### The stack

Every non-static variable you declare locally in a function is allocated on the stack. If a function needs more stack memory, it simply *decreases* the stack pointer (remember: the stack grows downward). When the function returns, the stack pointer is restored and the memory is implicitly deallocated. This is why it is called "automatic": you never have to worry about allocation or deallocation.

### Dynamic Memory - Malloc

If you need a long-lived region of memory, or one that is large or of unknown size, you may not want to put it on the stack. For this, `libc` gives you `malloc`.

But what does `malloc` actually do under the hood? Where does this memory come from?

In lecture 4 (slide 5) you saw a rough outline of your program's address space (more on this in the later lecture on virtual memory). It contains a region called the `heap`, and the end of the heap is marked by the *program break*, `brk`.

Our dynamically allocated memory lives in the heap. If you look at `man 2 brk`, you will find:

```c
int brk(void *addr);
void *sbrk(intptr_t increment);
```

`brk` moves the program break (the top of your heap) to `addr`, while `sbrk` grows or shrinks the heap by `increment` bytes. This is what `malloc` uses under the hood when it needs more memory: it expands the heap, giving you a larger accessible region.

However, as you will learn in the malloc lab, calling `malloc(x)` does not simply increase `brk` by `x` bytes and hand you the start of that region. That would be wildly inefficient! Instead, `malloc` actively manages memory for you (using free lists, slab allocators, etc.). The important point is that `malloc(100)` does not mean `brk` grows by only 100 bytes. It may grow the heap by, say, 132 kB, chop that memory into smaller chunks, and hand you a pointer to one of them. This saves `malloc` from calling `brk` too often, which is a system call (more on this in Computer Systems) and not exactly "fast".

Let's look at a program that repeatedly allocates 1000 bytes using `malloc`:

```c
#include <stdlib.h>
int main() {
    for (int i = 0; i < 1000; i++) {
        malloc(1000);
    }
    return 0;
}
```

Let's compile and run this with `strace`. Strace will show you which system calls your program executes under the hood (including the `brk` we are interested in).

```bash
gcc ./malloc_test.c -o malloc_test -O0 // disable optimizations to ensure compiler doesn't remove our call to malloc
strace -e brk ./malloc_test
```

You will probably get something like this:

```text
brk(NULL)                               = 0x6120d2e59000
brk(NULL)                               = 0x6120d2e59000
brk(0x6120d2e7a000)                     = 0x6120d2e7a000
brk(0x6120d2e9b000)                     = 0x6120d2e9b000
brk(0x6120d2ebc000)                     = 0x6120d2ebc000
brk(0x6120d2edd000)                     = 0x6120d2edd000
brk(0x6120d2efe000)                     = 0x6120d2efe000
brk(0x6120d2f1f000)                     = 0x6120d2f1f000
brk(0x6120d2f40000)                     = 0x6120d2f40000
brk(0x6120d2f61000)                     = 0x6120d2f61000

```

As you can see, malloc only calls `brk` 8 times, each for an allocation of 132 kB! (The first two calls, `brk(NULL)`, just query where the heap currently ends.)

Now let's increase allocation size from 1000 bytes to 1 Mio bytes (~1MB).
and look at the same thing again. 

```c
#include <stdlib.h>

int main() {
    for (int i = 0; i < 1000; i++) {
        malloc(1000000);
    }
    return 0;
}
```

What we see now is that brk was only called ONCE to increase the size of the heap by 132kB. So where is all our memory allocated ? It for sure cannot be on the heap...

```text
brk(NULL)                               = 0x5b9a508eb000
brk(NULL)                               = 0x5b9a508eb000
brk(0x5b9a5090c000)                     = 0x5b9a5090c000
```

Now `brk` is called only once to grow the heap by 132 kB. So where did our 1000 × 1 MB go? It clearly cannot be on the heap...

The reason is that `malloc` only serves "small" allocations from the heap. For large allocations (such as 1 MB), it uses the `mmap` system call, which basically tells the operating system: "Give me *some* region of memory that is x bytes large. I don't care where."

Run the following to see these calls.

```bash
strace -e mmap ./malloc_test
```

Why does it do this? To prevent fragmentation. If you `free` a region on the heap, the heap can only shrink if that region sits at the very *top*. Otherwise you just leave a hole in it, and the larger the allocation, the larger the potential hole. With `mmap`, freeing is clean: `malloc` calls `munmap`, which returns the entire region to the operating system at once, leaving no hole behind.

To see that indeed, each allocation now triggers a **separate** `mmap` call (as we cannot overallocate anymore as in the `brk` case to prevent fragmentation) count the number of `mmap` calls yourself.

```bash
strace -e mmap ./malloc_test 2>&1 | wc --lines
```

This should be a bit over 1000. 1000 because of `malloc` and the rest for some other stuff.