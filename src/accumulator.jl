struct Accumulator{T,op,init}
    sums::Vector{Vector{T}}
    function Accumulator(vals::Vector{T}, op=+, init=zero) where T
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

Base.length(a::Accumulator) = length(diff(a))

Base.lastindex(a::Accumulator) = lastindex(diff(a))

Base.diff(a::Accumulator) = a.sums[1]

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

Base.:(==)(a::Accumulator, b::Accumulator) = (diff(a) == diff(b))

function Base.getindex(a::Accumulator{T,op,init},i) where {T,op,init}
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

function Base.searchsortedfirst(a::Accumulator{T,op,init}, r) where {T,op,init}
    x = 0
    m = init(T)
    for k in length(a.sums):-1:1
        s = a.sums[k]
        x + 1 > length(s) && return length(a) + 1
        n = op(s[x + 1], m)
        if n < r
            m = n
            x ⊻= 1
        end
        x <<= 1
    end
    return (x >>= 1) + 1
end


Base.isempty(a::Accumulator) = isempty(diff(a))
