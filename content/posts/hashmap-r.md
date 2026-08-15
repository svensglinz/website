+++
title = 'Fast Maps for R'
date = 2026-08-15T18:00:00+02:00
draft = false
summary = 'HashmapR - A fast, vectorized hashmap implementation for R'
+++

## Background

R was the first programming language I learned while studying Economics, and it's what originally drew me closer to Computer Science. When I worked as a Data Analyst at SGEPT, I encountered a painstakingly slow piece of code that desperately needed efficient, vectorized key-value lookups. R has plenty of vectorized functions, but I could not find a fast, vectorized hashmap.

This led to **hashmapR**, a flexible, vectorized hashmap implemented in C++.

## Why Another Hashmap?

Technically R already has some form of a hashmap (environments) but they come with significant drawbacks:

- **String-only keys**: Environments only accept string keys, and each string is interned into the global symbol table permanently. Managing multiple large maps can quickly fill up memory.
- **Poor bulk operation performance**: Vectorized operations in existing solutions are often implemented by looping (in R) over a function that executes each operation individually — the overhead kills performance at scale.

**hashmapR** addresses both:
- **Flexible keys and values**: Any serializable R object works as a key or value
- **True vectorization**: Bulk operations execute natively in C++, completely bypassing R's interpreter

## Implementation

hashmapR wraps a C++ `std::unordered_map`. Each key and value is stored in a growable R list, preventing premature garbage collection.

Hashing is type-aware:
- **Primitives** (strings, integers, floats) are extracted and hashed directly via `std::hash`
- **Complex objects** are serialized to bytes, then hashed

This flexibility means you can use virtually any R object as a key. The real performance win comes from **native vectorization** — bulk operations execute entirely in C++, bypassing R's interpreter overhead completely.

R's copy-on-write semantics mean inserted objects aren't deep-copied: only references are stored. This is worth remembering if you store non-COW objects. 

## Key Features

- **Type Flexibility**: Use any serializable R object as a key or value
- **Serialization**: Save and restore maps easily:
  ```r
  saveRDS(map$to_list(), "my_map.rds")
  map_restored <- hashmap()$from_list(readRDS("my_map.rds"))
  ```
- **Utility Operations**: Invert, query size, clear, clone, and more

## Getting Started

Install from CRAN:
```r
install.packages("hashmapR")
```

Or the development version:
```r
devtools::install_github("svensglinz/hashmapR")
```

Usage is straightforward:

```r
library(hashmapR)

# Create and populate a hashmap
map <- hashmap()
map["user_1"] <- "Alice"
map["user_2"] <- "Bob"

# Single lookup
map["user_1"]  # "Alice"

# Vectorized bulk operations
map$set(list("user_1", "user_2"), list("Alice", "Bob"), vectorize=TRUE)
map$get(list("user_1", "user_2"), vectorize=TRUE)

# Utility functions 
map$contains("user_1") # TRUE
map$size() # 2
map$clear()

# create a new, inverted map, [A -> C, B -> C ] ==> [C -> list(A, B)]
map$invert(duplicates = "stack")
```

## Benchmarks

Coming Soon

---

*hashmapR is available on [CRAN](https://cran.r-project.org/package=hashmapR) and on [GitHub](https://github.com/svensglinz/hashmapR). Contributions and issues are welcome!*

