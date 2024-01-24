"""
An `a = Accumulator(v::Vector)` works as a replacement for `v`
with extra tracking computation that allow to maintain a live 
cumsum(a) that gets updated when the vector does.

```
julia> a = Accumulator([1:10;])
Accumulator([10, 4, 8, 1, 3, 3, 5, 6, 9, 5])

julia> c = cumsum(a)
CumSum(Accumulator([10, 4, 8, 1, 3, 3, 5, 6, 9, 5]))

julia> c[end]
55

julia> a[1]=0
0

julia> c[end]
54
```
"""
struct Accumulator{T,op,init}
    sums::Vector{Vector{T}}
    function Accumulator(vals::AbstractVector{T}; op=+, init=zero) where T
        a = new{T,op,init}([T[]])
        for x in vals
            push!(a, x)
        end
        return a
    end
end

"""
An `CumSum(a::Accumulator)` gets updated each time that 
`a` does. The time for an update and retrieval is both
`O(log(length(a)))`.
It is normally constructed with `cumsum(a)`, which takes 
time `O(1)`
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

Accumulator() = Accumulator(Float64) 
Accumulator(::Type{T}) where T = Accumulator(T[])
Accumulator{T}() where {T}  = Accumulator(T)

Base.length(a::Accumulator) = length(a.sums[1])

Base.lastindex(a::Accumulator) = lastindex(a.sums[1])

Base.:(==)(a::Accumulator, v::Vector) = a.sums[1] == v
Base.:(==)(v::Vector, a::Accumulator) = a.sums[1] == v

function Base.push!(a::Accumulator{T,op,init}, v) where {T, op, init}
    x = length(a)
    for s in a.sums
        length(s) == x && push!(s,init(T))
        s[x + 1] = op(s[x + 1], v)
        x >>= 1
    end
    if length(a.sums[end]) == 2
        push!(a.sums, [op(a.sums[end][1], a.sums[end][2])])
    end
end

function Base.pop!(a::Accumulator{T,op,init}) where {T, op, init}
    a[length(a)] = init(T)
    pop!(a.sums[1])
    x = length(a)
    for k in 2:length(a.sums)
        x >>= 1
        length(a.sums[k]) > x + 1 && pop!(a.sums[k])
    end
end

function Base.setindex!(a::Accumulator{T,op,init},v,i::Integer) where {T,op,init}
    x = i - 1
    r = promote_type(typeof(v), T)(v)
    for s in a.sums
        s[x + 1] = r
        left = (x & 1 == 0)
        x ⊻= 1
        if x + 1 ∈ eachindex(s)
            r = left ? op(r, s[x + 1]) : op(s[x + 1], r)
        end
        x >>= 1
    end
end

Base.:(==)(a::Accumulator, b::Accumulator) = a.sums[1] == b.sums[1]

Base.getindex(a::Accumulator, i) = a.sums[1][i]

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

Base.sum(a::Accumulator) = a.sums[end][end]

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


Base.isempty(a::Accumulator) = isempty(a.sums[1])
function Base.empty!(a::Accumulator)
    resize!(a.sums, 1)
    resize!(a.sums[1], 0)
end

function Base.show(io::IO, a::Accumulator{T,op,init}) where {T,op,init}
    print(io, "Accumulator(", a.sums[1], 
        op !== (+) ? ", op=$op" : "",
        init !== zero ? ", init=$init" : "",
        ")")
end

function Base.show(io::IO, c::CumSum)
    print(io, "CumSum(", c.acc, ")")
end

Base.:(==)(c::CumSum, v::Vector) = v[1] == c.acc[1] && all(c.acc[i] == v[i] - v[i-1] for i=2:lastindex(v))
Base.:(==)(v::Vector, c::CumSum) = c == v

function Base.iterate(c::CumSum{T, op, init}, state = nothing) where {T, op, init}
    a = c.acc
    (s, i) = isnothing(state) ? (init(T), 0) : state
    i == length(a) && return nothing
    s = op(s, a[i + 1])
    (s, (s, i + 1))
end