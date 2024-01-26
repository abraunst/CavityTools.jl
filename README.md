# CavityTools

[![Coverage](https://codecov.io/gh/abraunst/CavityTools.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/abraunst/CavityTools.jl)

This small package contains:

* `cavity!` and `cavity`: Functions to compute the `N` all-but-one operations between `N` elements in time `O(N)`. The operation is arbitrary and needs only to be associative. This is equivalent to computing `[reduce(op, (src[j] for j in eachindex(src) if i != j); init) for i in eachindex(src)]` which however would need `N*(N-1)` evaluations of `op`.
If `op` is commutative with exact inverse `invop`, you could obtain the same result of `cavity(src, op, init)`, also in time `O(N)`, with `invop.(reduce(op, src; init), src)`.

* `Accumulator`: An `a = Accumulator(v::Vector)` works as a replacement for `v` with extra tracking computation, such as `sum`. See also `CumSum` and `Cavity`

* `c::CumSum(a::Accumulator)`: keeps a live-updated cumsum of `a`. Retrieval `c[i]` takes time `O(N log N)`

* `c::Cavity(a::Accumulator)`: keeps a live-updated `cavity` of `a`. Retrieval `c[i]` takes time `O(N log N)`

* `ExponentialQueue`: `Accumulator` plus index tracking, intended for sampling in a Gillespie-like scheme. Indices are in `1:N`.
