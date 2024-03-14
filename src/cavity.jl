struct Cavity{T, op, init} <: AbstractVector{T}
    acc::Accumulator{T, op, init}
end

Base.size(c::Cavity) = size(c.acc)
Base.keys(c::Cavity) = keys(c.acc.sums[1])

function Base.getindex(c::Cavity{T,op,init}, i) where {T, op, init}
    @boundscheck checkbounds(c, i)
    a = c.acc
    s = init(T)
    i -= 1
    @inbounds for ak in a.sums
        j = xor(i, 1) + 1
        if j in eachindex(ak)
            s = op(s, ak[j])
        end
        i >>= 1
    end
    s
end

@inline function Base.iterate(c::Cavity{T, op, init},
        (i,L,R) = (0,
            fill(init(T), length(c.acc.sums)),
            fill(init(T), length(c.acc.sums)))) where {T, op, init}
    i == length(c) && return nothing
    a = c.acc.sums
    k = i == 0 ? length(a) - 1 : count_ones(xor(i - 1, i))
    for f in k:-1:1
        j = xor(i >> (f-1), 1) + 1
        l, r = L[f + 1], R[f + 1]
        L[f] = ( isodd(j) && j ∈ eachindex(a[f])) ? op(l, a[f][j]) : l
        R[f] = (iseven(j) && j ∈ eachindex(a[f])) ? op(a[f][j], r) : r
    end
    op(first(L), first(R)), (i + 1, L, R)
end

function cavity!(dest, source, op, init)
    @assert length(dest) == length(source)
    isempty(source) && return init
    if length(source) == 1
        @inbounds dest[begin] = init
        return op(first(source), init)
    end
    accumulate!(op, dest, source)
    full = op(dest[end], init)
    right = init
    for (i,s)=zip(lastindex(dest):-1:firstindex(dest)+1,Iterators.reverse(source))
        @inbounds dest[i] = op(dest[i-1], right);
        right = op(s, right);
    end
    @inbounds dest[begin] = right
    full
end

function cavity(source, op, init)
    dest = [init for _ in source]
    full = cavity!(dest, source, op, init)
    dest, full
end
