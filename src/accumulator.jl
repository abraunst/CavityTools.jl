struct Accumulator{T}
    sums::Vector{Vector{T}}
    function Accumulator(vals::Vector{T}) where T
        a = new{T}([T[]])
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

function Base.push!(a::Accumulator{T}, v) where T
    x = length(a)
    for s in a.sums
        length(s) == x && push!(s,zero(T))
        s[x + 1] += v
        x >>= 1
    end
    if length(a.sums[end]) == 2
        push!(a.sums, [a.sums[end][1] + a.sums[end][2]])
    end
end

function Base.pop!(a::Accumulator{T}) where T
    a[length(a)] = zero(T)
    pop!(a.sums[1])
    x = length(a)
    for k in 2:length(a.sums)
        x >>= 1
        length(a.sums[k]) > x + 1 && pop!(a.sums[k])
    end

end

function Base.setindex!(a::Accumulator{T},v,i::Integer) where T
    x = i - 1
    r = promote_type(typeof(v), T)(v)
    for s in a.sums
        s[x + 1] = r
        x ⊻= 1
        if x + 1 ∈ eachindex(s)
            r += s[x + 1]
        end
        x >>= 1
    end
end

Base.:(==)(a::Accumulator, b::Accumulator) = (diff(a) == diff(b))

function Base.getindex(a::Accumulator{T},i) where T
    m = zero(T)
    K = length(a.sums)
    for k in K:-1:1
        s = a.sums[k]
        if (i >> (k-1)) & 1 == 1
            m += s[xor(i >> (k-1), 1) + 1]
        end
    end
    return m
end

Base.sum(a::Accumulator) = a.sums[end][end]

Base.broadcasted(a::Accumulator) = Ref(a)

function Base.searchsortedfirst(a::Accumulator{T}, r) where T
    x = 0
    m = zero(promote_type(typeof(r),T))
    for k in length(a.sums):-1:1
        s = a.sums[k]
        x + 1 > length(s) && return length(a) + 1
        if m + s[x + 1] < r
            m += s[x + 1]
            x ⊻= 1
        end
        x <<= 1
    end
    return (x >>= 1) + 1
end


Base.isempty(a::Accumulator) = isempty(diff(a))
