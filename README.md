# CavityTools

[![Coverage](https://codecov.io/gh/abraunst/CavityTools.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/abraunst/CavityTools.jl) [![Build Status](https://github.com/abraunst/CavityTools.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/abraunst/CavityTools.jl/actions/workflows/CI.yml?query=branch%3Amain)

This small package contains:

* `cavity!` and `cavity`: Functions to compute the `N` all-but-one operations between `N` elements in time `O(N)`. The operation is arbitrary and needs only to be associative. This is equivalent to computing `[reduce(op, (src[j] for j in eachindex(src) if i != j); init) for i in eachindex(src)]` which however would need `N*(N-1)` evaluations of `op`.
  If `op` is commutative with exact inverse `invop`, you could obtain the same result of `cavity(src, op, init)`, also in time `O(N)`, with `invop.(reduce(op, src; init), src)`.

* `Accumulator`: An `a = Accumulator(v::AbstractVector)` works as a replacement for `v` with extra tracking computations.
  * Construction of `a` requires time `O(N)` where `N == length(v)`.
  * `sum(a)` requires time `O(1)`.
  * `cumsum(a)`, `cavity(a)` require time `O(1)` and return respectively a `CumSum` and `Cavity` objects that are linked to `a`.

* `c::CumSum(a::Accumulator)`: keeps a live-updated `cumsum` of `a`.
  * Create it with `c = cumsum(a::Accumulator)`
  * Retrieval `c[i]` takes time `O(log N)`.
  * `collect(c)` takes time `O(N)`
  * `searchsortedfirst(r, c)` takes time `O(log N)`

* `c::Cavity(a::Accumulator)`: keeps a live-updated `cavity` of `a`.
  * Create it with `c = cavity(a::Accumulator)`.
  * Retrieval `c[i]` takes time `O(log N)`.
  * `collect(c)` takes time `O(N)` (but is slower than `cavity(v::Vector)`).
  