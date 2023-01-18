# CavityTools

[![Coverage](https://codecov.io/gh/abraunst/CavityTools.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/abraunst/CavityTools.jl)

This small package contains:

* `cavity!` and `cavity`: Functions to compute the `N` all-but-one operations between `N` elements in time `O(N)`. The operation is arbitrary and needs only to be associative.

* `Accumulator`: A data structure keeping a live-updatable `cumsum`. Updating or retrieving one element costs `O(log(N))`, computing the total sum costs `O(1)`. `searchsortedfirst(a::Accumulator, v)` is also implemented, taking also `O(log(N))` time.

* `ExponentialQueue`: `Accumulator` plus index tracking, intended for sampling in a Gillespie-like scheme