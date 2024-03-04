"""
`ExponentialQueue(N)`` keeps an updatable queue of up to `N` events with ids `1...N` and contant rates Q[1] ... Q[N]. 
This is intended for sampling in continuous time.

julia> Q = ExponentialQueue(100)
ExponentialQueue(Accumulator{Float64, +, zero}([Float64[]]), [0, 0, 0, 0, 0, 0, 0, 0, 0, 0  …  0, 0, 0, 0, 0, 0, 0, 0, 0, 0], Int64[])

julia> Q[1] = 1.2 #updates rate of event 1
1.2

julia> Q[55] = 2.3 #updates rate of event 55
2.3

julia> i,t = pop!(Q) # gets time and id of next event and remove it from the queue
(55, 0.37869716808319576)
"""
struct ExponentialQueue
    acc::Accumulator{Float64}
    idx::Vector{Int}
    ridx::Vector{Int}
end

ExponentialQueue(N::Integer) = ExponentialQueue(Accumulator(), fill(0,N), Int[])

function Base.setindex!(e::ExponentialQueue, p, i)
    if p <= 0
        # do not store null rates
        haskey(e, i) && deleteat!(e, i)
        return p
    end

    if haskey(e, i)
        e.acc[e.idx[i]] = p
    else
        e.idx[i] == 0
        push!(e.acc, p)
        e.idx[i] = length(e.acc)
        push!(e.ridx, i)
    end
    p
end

Base.haskey(e::ExponentialQueue, i) = !iszero(e.idx[i])

Base.getindex(e::ExponentialQueue, i) = haskey(e, i) ? diff(e.acc)[e.idx[i]] : 0.0


function Base.deleteat!(e::ExponentialQueue, i)
    l, k = e.idx[i], e.ridx[length(e.acc)]
    e.acc[l] = e.acc.sums[1][end]
    e.idx[k], e.ridx[l] = l, k
    e.idx[i] = 0
    pop!(e.acc)
    pop!(e.ridx)
    e
end

function Base.pop!(e::ExponentialQueue; rng = Random.default_rng())
    t = -log(rand(rng))/sum(e.acc)
    j = searchsortedfirst(e.acc, rand(rng) * sum(e.acc))
    i = e.ridx[j]
    deleteat!(e, i)
    i, t
end

Base.isempty(e::ExponentialQueue) = isempty(e.acc)

function Base.empty!(e::ExponentialQueue)
    e.idx .= 0
    empty!(e.ridx)
    empty!(e.acc)
end
