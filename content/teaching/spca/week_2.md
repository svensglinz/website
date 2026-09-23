---
title: Week 2
---

## Exercise - Decimal to Hex

Task: Write a function that takes in an `uint32_t` and prints it as an 8-character hexadecimal number.
The hexadecimal number should be printed in "big endian" format as you would customarily write a number (ie. most significant digit at the front)

Note: You can do this very easily by just using the formatting capabilities of `printf` from `<stdio.h>`, but this 
would of course not be the point :) 

For the exam, I suggest that you are comfortable with such kind of questions, as they often involve bit manipulations like you need here.


{{< collapse summary="Show Solution" >}}

```c
#include <stdio.h>
#include <stdint.h>

void print_hex(uint32_t x) {

    // simple conversion lookup table
    static char map[] = { '0' , '1' , '2', '3', '4' ,'5', '6', '7', '8', '9', 'A', 'B', 'C', 'D', 'E', 'F' };

    // 9 bytes of 0's. Note that C strings are 0 terminated
    char hex_str[9] = { 0 };

    for (int i = 0, j = 7; i < 32; i+= 4, j--) {
        int block = (x >> i) & 0xF;
        hex_str[j] = map[block];
    }

    printf("0x%s\n", hex_str);
}

```
{{< /collapse >}}
