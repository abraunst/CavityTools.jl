
abstract type AbstractExponentialQueue{T} end

struct ExponentialQueue <: AbstractExponentialQueue{Int}
    acc::Accumulator{Float64,+,zero}
    sum::CumSum{Float64,+,zero}
    idx::Vector{Int}
    ridx::Vector{Int}
end


"""
`ExponentialQueue(N)` keeps an updatable queue of up to `N` events with ids `1...N` and contant rates Q[1] ... Q[N]. 
This is intended for sampling in continuous time.

julia> Q = ExponentialQueue(100)
ExponentialQueue(Accumulator{Float64, +, zero}([Float64[]]), [0, 0, 0, 0, 0, 0, 0, 0, 0, 0  …  0, 0, 0, 0, 0, 0, 0, 0, 0, 0], Int64[])

julia> Q[1] = 1.2 #updates rate of event 1
1.2

julia> Q[55] = 2.3 #updates rate of event 55
2.3

julia> i,t = pop!(Q) # gets time and id of next event and remove it from the queue
(55, 0.37869716808319576)

See also: `ExponentialQueueDict`
"""
function ExponentialQueue(N::Integer)
    acc = Accumulator()
    ExponentialQueue(acc, cumsum(acc), fill(0,N), Int[])
end

function ExponentialQueue(ridx::AbstractVector{Int}, R::AbstractVector{Float64})
    N = maximum(ridx)
    idx = fill(0, N)
    for (i,vi) in pairs(ridx)
        idx[vi] = i
    end
    acc = Accumulator(R)
    ExponentialQueue(acc, cumsum(acc), idx, ridx)
end

function Base.show(io::IO, Q::ExponentialQueue) 
    print(io, "ExponentialQueue(", Q.ridx, ", ", Q.acc.sums[1], ")")
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
struct ExponentialQueueDict{K} <: AbstractExponentialQueue{K}
    acc::Accumulator{Float64,+,zero}
    sum::CumSum{Float64,+,zero}
    idx::Dict{K,Int}
    ridx::Vector{K}
end

function Base.show(io::IO, Q::ExponentialQueueDict{K}) where K
    print(io, "ExponentialQueueDict(", Pair{K,Float64}[i=>Q.acc[Q.idx[i]] for i in eachindex(Q.idx)], ")")
end

function ExponentialQueueDict{K}() where K
    acc = Accumulator()
    ExponentialQueueDict(acc, cumsum(acc), Dict{K,Int}(), K[])
end

function ExponentialQueueDict(v::AbstractVector{Pair{K,Float64}}) where K
    acc = Accumulator(last.(v))
    ExponentialQueueDict(acc, cumsum(acc), Dict(k=>i for (i,(k,_)) in pairs(v)), first.(v))
end

ExponentialQueueDict() = ExponentialQueueDict{Any}()

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
        e.idx[i] = length(e.acc)
        push!(e.ridx, i)
    end
    p
end

Base.haskey(e::ExponentialQueue, i) = !iszero(e.idx[i])

Base.haskey(e::ExponentialQueueDict, i) = haskey(e.idx, i)

Base.getindex(e::AbstractExponentialQueue, i) = haskey(e, i) ? e.acc[e.idx[i]] : 0.0

function Base.delete!(e::AbstractExponentialQueue, i)
    l, k = e.idx[i], e.ridx[length(e.acc)]
    e.acc[l] = e.acc.sums[1][end]
    e.idx[k], e.ridx[l] = l, k
    e.idx[i] = 0
    pop!(e.acc)
    pop!(e.ridx)
    e
end

"""
k,t = peek(Q): Sample next event and time from the queue.
"""
function Base.peek(e::AbstractExponentialQueue; rng = Random.default_rng())
    t = -log(rand(rng))/sum(e.acc)
    i = peekevent(e; rng)
    i, t
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
    i, t
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
