
abstract type AbstractExponentialQueue{T,F} <: AbstractDict{T, F} end

struct ExponentialQueue <: AbstractExponentialQueue{Int,Float64}
    acc::Accumulator{Float64,+,zero}
    sum::CumSum{Float64,+,zero}
    idx::Vector{Int}
    ridx::Vector{Int}
end


"""
`ExponentialQueue()` keeps an updatable queue of up to `N` events with ids `1...N` and contant rates Q[1] ... Q[N]. 
This is intended for sampling in continuous time.

julia> Q = ExponentialQueue()
ExponentialQueue(Accumulator{Float64, +, zero}([Float64[]]), [0, 0, 0, 0, 0, 0, 0, 0, 0, 0  …  0, 0, 0, 0, 0, 0, 0, 0, 0, 0], Int64[])

julia> Q[1] = 1.2 #updates rate of event 1
1.2

julia> Q[55] = 2.3 #updates rate of event 55
2.3

julia> i,t = pop!(Q) # gets time and id of next event and remove it from the queue
(55, 0.37869716808319576)

See also: `ExponentialQueueDict`
"""
function ExponentialQueue(v = [])
    ridx = Int[]
    R2 = Float64[]
    N = 0
    for (i,ri) in v
        N = max(N, i)
        if ri > 0
            push!(ridx, i)
            push!(R2, ri)
        end
    end
    idx = fill(0, N)
    for (j,i) in enumerate(ridx)
        idx[i] = j
    end
    acc = Accumulator(R2)
    ExponentialQueue(acc, cumsum(acc), idx, ridx)
end

@deprecate ExponentialQueue(N::Integer) ExponentialQueue()

function Base.show(io::IO, Q::ExponentialQueue) 
    print(io, "ExponentialQueue(", [i=>r for (i,r) in zip(Q.ridx, Q.acc.sums[1])], ")")
end


"""
`ExponentialQueueDict{K}` keeps an updatable queue of elements of type `K` with contant rates Q[k]. 
This is intended for sampling in continuous time.

julia> Q = ExponentialQueueDict{Int}()
ExponentialQueueDict(Pair{Int64, Float64}[])

julia> Q[1] = 1.2 # updates rate of event 1
1.2

julia> Q[55] = 2.3 # updates rate of event 55
2.3

julia> i,t = pop!(Q) # gets time and id of next event and remove it from the queue
(55, 0.37869716808319576)

See also: `ExponentialQueue` for a slightly more efficient queue for the case `K == Int`
"""
struct ExponentialQueueDict{K,F} <: AbstractExponentialQueue{K,F}
    acc::Accumulator{F,+,zero}
    sum::CumSum{F,+,zero}
    idx::Dict{K,Int}
    ridx::Vector{K}
end

function Base.show(io::IO, Q::ExponentialQueueDict{K,F}) where {K,F}
    print(io, "ExponentialQueueDict(", Pair{K,F}[i=>Q.acc[Q.idx[i]] for i in eachindex(Q.idx)], ")")
end

function ExponentialQueueDict{K,F}() where {K,F<:Real}
    acc = Accumulator{F}()
    ExponentialQueueDict(acc, cumsum(acc), Dict{K,Int}(), K[])
end

function ExponentialQueueDict(v)
    acc = Accumulator([float(r) for (_,r) in v])
    ExponentialQueueDict(acc, cumsum(acc), Dict(k=>i for (i,(k,_)) in enumerate(v)), [i for (i,_) in v])
end

ExponentialQueueDict() = ExponentialQueueDict{Any,Float64}()

function _addidx(e::ExponentialQueue, i)
    i <= 0 && throw(BoundsError(e, i))
    i > length(e.idx) && append!(e.idx, fill(0, i - length(e.idx)))
    e.idx[i] = length(e.acc)
end

function _addidx(e::ExponentialQueueDict, i)
    e.idx[i] = length(e.acc)
end


function Base.setindex!(e::AbstractExponentialQueue, p, i)
    if p <= 0
        # do not store null rates
        haskey(e, i) && delete!(e, i)
        return p
    end

    if haskey(e, i)
        e.acc[e.idx[i]] = p
    else
        push!(e.acc, p)
        _addidx(e, i)
        push!(e.ridx, i)
    end
    p
end

Base.haskey(e::ExponentialQueue, i) = i ∈ eachindex(e.idx) && !iszero(e.idx[i])

Base.haskey(e::ExponentialQueueDict, i) = haskey(e.idx, i)

Base.getindex(e::AbstractExponentialQueue, i) = haskey(e, i) ? e.acc[e.idx[i]] : 0.0


_deleteidx!(e::ExponentialQueueDict, i) = delete!(e.idx, i)

_deleteidx!(e::ExponentialQueue, i) = (e.idx[i] = 0)

function Base.delete!(e::AbstractExponentialQueue, i)
    l, k = e.idx[i], e.ridx[length(e.acc)]
    e.acc[l] = e.acc.sums[1][end]
    e.idx[k], e.ridx[l] = l, k
    pop!(e.acc)
    pop!(e.ridx)
    _deleteidx!(e, i)
    e
end


"""
k,t = peek(Q): Sample next event and time from the queue.
"""
function Base.peek(e::AbstractExponentialQueue; rng = Random.default_rng())
    t = -log(rand(rng))/sum(e.acc)
    i = peekevent(e; rng)
    i => t
end

"""
peekevent(Q; rng): Sample next event from the queue (with probability proportional to its rate)
"""
function peekevent(e::AbstractExponentialQueue; rng = Random.default_rng())
    j = searchsortedfirst(e.sum, rand(rng) * sum(e.acc))
    e.ridx[min(j, lastindex(e.ridx))]    
end

"""
k,t = pop!(Q): Sample next event and time from the queue and remove it from the queue.
"""
function Base.pop!(e::AbstractExponentialQueue; rng = Random.default_rng())
    i, t = peek(e; rng)
    delete!(e, i)
    i => t
end

Base.isempty(e::AbstractExponentialQueue) = isempty(e.acc)

function Base.empty!(e::ExponentialQueue)
    e.idx .= 0
    empty!(e.ridx)
    empty!(e.acc)
end

function Base.empty!(e::ExponentialQueueDict)
    empty!(e.idx)
    empty!(e.ridx)
    empty!(e.acc)
end

Base.values(e::ExponentialQueueDict) = e.acc

Base.keys(e::ExponentialQueueDict) = e.ridx

Base.iterate(e::AbstractExponentialQueue, i = 1) = length(e.acc) < i ? nothing : ((e.ridx[i]=>e.acc[i]), i+1)

Base.eltype(::AbstractExponentialQueue{T}) where T = Pair{T,Float64}

Base.length(e::AbstractExponentialQueue) = length(e.acc)

Base.:(==)(e1::AbstractExponentialQueue, e2::AbstractExponentialQueue) = (Dict(e1) == Dict(e2))
