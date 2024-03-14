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
struct CumSum{T,op,init}
    acc::Accumulator{T,op,init}
end

Base.cumsum(a::Accumulator) = CumSum(a)
Base.length(c::CumSum) = length(c.acc)
Base.firstindex(c::CumSum) = 1
Base.lastindex(c::CumSum) = lastindex(c.acc)
Base.keys(c::CumSum) = keys(c.acc.sums[begin])
Base.diff(c::CumSum) = c.acc

function Base.getindex(c::CumSum{T,op,init},i) where {T,op,init}
    a = c.acc
    m = init(T)
    K = length(a.sums)
    for k in K:-1:1
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

Base.:(==)(c::CumSum, v::Vector) = v[1] == c.acc[1] && all(c.acc[i] == v[i] - v[i-1] for i=2:lastindex(v))
Base.:(==)(v::Vector, c::CumSum) = c == v

function Base.searchsortedfirst(c::CumSum{T,op,init}, r; lt = isless, rev = false) where {T,op,init}
    a = c.acc
    x = 0
    m = init(T)
    for k in length(a.sums):-1:1
        s = a.sums[k]
        x + 1 > length(s) && return length(a) + 1
        n = op(s[x + 1], m)
        if xor(rev, lt(n, r))
            m = n
            x ⊻= 1
        end
        x <<= 1
    end
    return (x >>= 1) + 1
end

@inline function Base.iterate(c::CumSum{T, op, init}, state = nothing) where {T, op, init}
    a = c.acc
    sums, i = isnothing(state) ? (fill(init(T), length(a.sums) + 1), 0) : state
    i == length(a) && return nothing
    k = count_ones(xor(i + 1, i))
    sums[1:k] .= op(sums[k+1], a.sums[k][(i >> (k-1))+1])
    first(sums), (sums, i + 1)
end
