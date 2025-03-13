"""
An `a = Accumulator(v::AbstractVector; op=+, init=zero)` works as a replacement for `v`
with extra tracking computation, such as `sum`. See also `CumSum` and `Cavity`

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

julia> sum(a)
55

julia> a[1]=0
0

julia> sum(a)
54

```
"""
struct Accumulator{T,op,init} <: AbstractVector{T}
    sums::Vector{Vector{T}}
    function Accumulator(vals::AbstractVector{T}; op=+, init=zero) where T
        a = new{T,op,init}([T[]])
        for x in vals
            push!(a, x)
        end
        return a
    end
end

Accumulator() = Accumulator(Float64) 
Accumulator(::Type{T}) where T = Accumulator(T[])
Accumulator{T}() where {T}  = Accumulator(T)

Base.length(a::Accumulator) = length(a.sums[1])
Base.size(a::Accumulator) = tuple(length(a))

Base.lastindex(a::Accumulator) = lastindex(a.sums[1])

Base.:(==)(a::Accumulator, v::AbstractVector) = a.sums[1] == v
Base.:(==)(v::AbstractVector, a::Accumulator) = a.sums[1] == v

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
    v == a[i] && return v
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
    v
end

Base.:(==)(a::Accumulator, b::Accumulator) = first(a.sums) == first(b.sums)

Base.getindex(a::Accumulator, i) = first(a.sums)[i]

Base.sum(a::Accumulator{T,+,zero}) where T = only(last(a.sums))

Base.reduce(a::Accumulator{T,op,init}) where {T,op,init} = only(last(a.sums))

Base.isempty(a::Accumulator) = isempty(first(a.sums))
function Base.empty!(a::Accumulator)
    resize!(a.sums, 1)
    resize!(first(a.sums), 0)
end

function Base.show(io::IO, a::Accumulator{T,op,init}) where {T,op,init}
    print(io, "Accumulator(", a.sums[1], 
        op !== (+) ? ", op=$op" : "",
        init !== zero ? ", init=$init" : "",
        ")")
end
