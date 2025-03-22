"""
An `CumSum(a::Accumulator)` gets updated each time that 
`a` does. The time for an update and retrieval is both
`O(log(length(a)))`.
It is normally constructed with `cumsum(a)`, which takes 
time `O(1)`

```
julia> a = Accumulator([1:10;])
10-element Accumulator{Int64, +, zero}:
  1
  2
  3
  4
  5
  6
  7
  8
  9
 10

julia> c = cumsum(a)
CumSum(Accumulator([1, 2, 3, 4, 5, 6, 7, 8, 9, 10]))

julia> c[end]
55

julia> a[1] = 100
100

julia> c[end]
154
```
"""
struct CumSum{T,op,init} <: AbstractVector{T}
    acc::Accumulator{T,op,init}
end

function Base.cumsum(a::Accumulator)
    Base.require_one_based_indexing(a)
    CumSum(a)
end

Base.size(c::CumSum) = size(c.acc)
Base.length(c::CumSum) = length(c.acc)
Base.firstindex(c::CumSum) = firstindex(c.acc)
Base.lastindex(c::CumSum) = lastindex(c.acc)
Base.keys(c::CumSum) = keys(c.acc)
Base.diff(c::CumSum) = @view c.acc[2:end]

function Base.getindex(c::CumSum{T,op,init},i) where {T,op,init}
    a = c.acc
    m = init(T)
    K = length(a.sums)
    @inbounds for k in K:-1:1
        s = a.sums[k]
        if (i >> (k-1)) & 1 == 1
            m = op(m, s[xor(i >> (k-1), 1) + 1])
        end
    end
    return m
end

function Base.show(io::IO, c::CumSum{T,op,init}) where {T,op,init}
    print(io, "CumSum(", c.acc, op != (+) || init != zero ? "; op=$op, init=$init)" : ")")
end

function Base.searchsortedfirst(c::CumSum{T,op,init}, r; lt = isless, rev = false) where {T,op,init}
    a = c.acc
    x::Int = 0
    m = init(T)
    for k in reverse(eachindex(a.sums))
        s = @inbounds a.sums[k]
        x + 1 > length(s) && return length(a) + 1
        @inbounds n = op(s[x + 1], m)
        if xor(rev, lt(n, r))
            m = n
            x ⊻= 1
        end
        x <<= 1
    end
    return (x >> 1) + 1
end

@inline function Base.iterate(c::CumSum{T, op, init}, 
                state = (fill(init(T), length(c.acc.sums) + 1), 0)) where {T, op, init}
    a = c.acc
    sums, i = state
    i == length(a) && return nothing
    @inbounds k = count_ones(xor(i + 1, i))
    @inbounds x = op(sums[k+1], a.sums[k][(i >> (k-1))+1])
    @inbounds for j in 1:k
        sums[j] = x
    end
    first(sums), (sums, i + 1)
end
