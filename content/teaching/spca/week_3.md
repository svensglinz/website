---
Title: Week 3
---

## Your C Program in Memory

In the lecture, you should have seen that when you run your program, the Operating System loads this
into an address space where it will place different sections of your code. (More on how this works in later lectures)

These are among other `.text` where your compiled program goes, `.data` where some static data goes 
(eg. when you define `static int my_array[] = { 1, 2, 3}`) or `.rodata` which holds read only data such as
string literals. 

**Remember:**
> String literals in C (ie `char* my_string = "MY_STRING"`) are stored in read only memory. This for example allows the compiler
> to reuse a string in case you define the same thing twice.
> Since string literals are read-only, do never ever pass
> something like that to a function that takes char * as an argument. (If it takes const char*, things may be different since
> the function should theoretically not modify the string, but then again, you could just "cast away" the const and then...)

If you do not just want to believe what the lectures tell you regarding memory layout, you don't have to :) 

Linux exposes a lot about what you may ever want to know about your running processes through the [proc](https://www.geeksforgeeks.org/linux-unix/proc-file-system-linux/) filesystem. One of the things you will find here is the address space layout / page mappings of each process. 

Let's write a little program

```c
#include <stdio.h>
#include <unistd.h>

int main() {
    char *my_string_literal = "hello world";
    printf("my string lives at %p\n", my_string_literal);
    pause(); // "sleep" until we send a signal to the process (eg. ctrl+C in your terminal)
    return 0;
}

```

Then lets compile and run it

```bash
# compile your program
gcc string_literal.c -o string_literal

 # run program in the background
./string_literal &

echo process id is $!

# print out mappings
cat /proc/$\!/maps

```

This should show you something like this

```c
// of course this will be different for you (remember: Address Space Layout Randomization)
my string lives at 0x5c9c4f399004
```

```
5c9c4f397000-5c9c4f398000 r--p 00000000 103:05 548280                    /home/sven/string_literal
5c9c4f398000-5c9c4f399000 r-xp 00001000 103:05 548280                    /home/sven/string_literal
5c9c4f399000-5c9c4f39a000 r--p 00002000 103:05 548280                    /home/sven/string_literal
5c9c4f39a000-5c9c4f39b000 r--p 00002000 103:05 548280                    /home/sven/string_literal
5c9c4f39b000-5c9c4f39c000 rw-p 00003000 103:05 548280                    /home/sven/string_literal
5c9c870e4000-5c9c87105000 rw-p 00000000 00:00 0                          [heap]
7f4ebbc00000-7f4ebbc28000 r--p 00000000 103:05 4229267                   /usr/lib/x86_64-linux-gnu/libc.so.6
7f4ebbc28000-7f4ebbdb1000 r-xp 00028000 103:05 4229267                   /usr/lib/x86_64-linux-gnu/libc.so.6
7f4ebbdb1000-7f4ebbe00000 r--p 001b1000 103:05 4229267                   /usr/lib/x86_64-linux-gnu/libc.so.6
7f4ebbe00000-7f4ebbe04000 r--p 001ff000 103:05 4229267                   /usr/lib/x86_64-linux-gnu/libc.so.6
7f4ebbe04000-7f4ebbe06000 rw-p 00203000 103:05 4229267                   /usr/lib/x86_64-linux-gnu/libc.so.6
7f4ebbe06000-7f4ebbe13000 rw-p 00000000 00:00 0 
7f4ebbf37000-7f4ebbf3a000 rw-p 00000000 00:00 0 
7f4ebbf5b000-7f4ebbf5d000 rw-p 00000000 00:00 0 
7f4ebbf5d000-7f4ebbf5e000 r--p 00000000 103:05 4229261                   /usr/lib/x86_64-linux-gnu/ld-linux-x86-64.so.2
7f4ebbf5e000-7f4ebbf89000 r-xp 00001000 103:05 4229261                   /usr/lib/x86_64-linux-gnu/ld-linux-x86-64.so.2
7f4ebbf89000-7f4ebbf93000 r--p 0002c000 103:05 4229261                   /usr/lib/x86_64-linux-gnu/ld-linux-x86-64.so.2
7f4ebbf93000-7f4ebbf95000 r--p 00036000 103:05 4229261                   /usr/lib/x86_64-linux-gnu/ld-linux-x86-64.so.2
7f4ebbf95000-7f4ebbf97000 rw-p 00038000 103:05 4229261                   /usr/lib/x86_64-linux-gnu/ld-linux-x86-64.so.2
7ffece650000-7ffece672000 rw-p 00000000 00:00 0                          [stack]
7ffece6bd000-7ffece6c1000 r--p 00000000 00:00 0                          [vvar]
7ffece6c1000-7ffece6c3000 r-xp 00000000 00:00 0                          [vdso]
ffffffffff600000-ffffffffff601000 --xp 00000000 00:00 0                  [vsyscall]

```

As you can see, you have the stack pretty much at the top, you have some other libraries such as `libc` which the program needs (eg. to execute `printf`),
you have the heap, and at the very bottom, you have your `string_literal` program. Note that only one of the regions is executable (`x`). This is where your `.text`
section lives. Another region is both readable and writeable (`rw`), this is where your `.data` section lives. 

And if you check the address that your program printed, you will see that it lives in one of the read only regions of your address space (ie. in the `.rodata` section). 

Now you know with absolute certainty that trying to modify your string will crash your program, as you do not have permission to write to the memory where the string lives.


