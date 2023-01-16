struct ExponentialQueue
    acc::Accumulator{Float64}
    idx::Vector{Int}
    ridx::Vector{Int}
end

ExponentialQueue(N::Integer) = ExponentialQueue(Accumulator(), fill(0,N), Int[])

function Base.setindex!(e::ExponentialQueue, p, i)
    if e.idx[i] == 0
        push!(e.acc, p)
        e.idx[i] = length(e.acc)
        push!(e.ridx, i)
    else
        e.acc[e.idx[i]] = p
    end
    p
end

Base.in(i, e::ExponentialQueue) = !iszero(e.idx[i])

Base.getindex(e::ExponentialQueue, i) = diff(e.acc)[e.idx[i]]


function Base.deleteat!(e::ExponentialQueue, i)
    l, k = e.idx[i], e.ridx[length(e.acc)]
    e.acc[l] = e.acc.sums[1][end]
    e.idx[k], e.ridx[l] = l, k
    e.idx[i] = 0
    pop!(e.acc)
    pop!(e.ridx)
    e
end

function Base.pop!(e::ExponentialQueue)
    t = -log(rand())/sum(e.acc)
    j = searchsortedfirst(e.acc, rand() * sum(e.acc))
    i = e.ridx[j]
    deleteat!(e, i)
    i,t
end

Base.isempty(e::ExponentialQueue) = isempty(e.acc)

function Base.empty!(e::ExponentialQueue)
    e.idx .= 0
    empty!(e.ridx)
    empty!(e.acc)
end