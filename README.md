# CavityTools

[![Coverage](https://codecov.io/gh/abraunst/CavityTools.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/abraunst/CavityTools.jl) [![Build Status](https://github.com/abraunst/CavityTools.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/abraunst/CavityTools.jl/actions/workflows/CI.yml?query=branch%3Amain)


This small package contains:

* `cavity!` and `cavity`: Functions to compute the `N` all-but-one operations between `N` elements in time `O(N)`. The operation is arbitrary and needs only to be associative. This is equivalent to computing `[reduce(op, (src[j] for j in eachindex(src) if i != j); init) for i in eachindex(src)]` which however would need `N*(N-1)` evaluations of `op`.
  If `op` is commutative with exact inverse `invop`, you could obtain the same result of `cavity(src, op, init)`, also in time `O(N)`, with `invop.(reduce(op, src; init), src)`.

* `Accumulator`: An `a = Accumulator(v::Vector)` works as a replacement for `v` with extra tracking computations.
  * Construction of `a` requires time `O(N)` where `N == length(v)`.
  * `sum(a)`, `cumsum(a)`, `cavity(a)` all require time `O(1)`.
  * See also: `CumSum` and `Cavity`.

* `c::CumSum(a::Accumulator)`: keeps a live-updated `cumsum` of `a`. 
  * Create it with `c = cumsum(a::Accumulator)`
  * Retrieval `c[i]` takes time `O(log N)`.
  * `collect(c)` takes time `O(N)`
  * `searchsortedfirst(r, c)` takes time `O(log N)`

* `c::Cavity(a::Accumulator)`: keeps a live-updated `cavity` of `a`.
  * Create it with `c = cavity(a::Accumulator)`.
  * Retrieval `c[i]` takes time `O(log N)`.
  * `collect(c)` takes time `O(N)` (but is slower than `cavity(v::Vector)`).


* `Q::ExponentialQueueDict{K}()`: `Dict`-like interface to a collection of events with associated independent probability rates, intended for sampling on a Gillespie-like scheme.
  * Events are of type `K`. 
  * Rates can be queried by `getindex` (i.e. `r = Q[k]`) and updated via `setindex!` (i.e. `Q[k] = r`). both in time `O(log N)` where `N` is the number of stored events. 
  * Next event type and time can extracted from the queue by `k,t = pop!(Q)` or `k,t=peek(Q)`. On `pop!`, event `k` is then removed from the collection. `pop!` takes time `O(log N)`, `peek` is `O(1)`.
  * If event time is unneeded, next event alone can be extracted with `k = peekevent(Q)`.

* `Q::ExponentialQueue(N::Integer)`: Like `ExponentialQueue{Int}` but events are stored on a vector instead of a `Dict`, so it is slightly more efficient. Event indices are in `1:N`.