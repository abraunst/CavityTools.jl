using CavityTools
using Test
using Random

v = rand(0:200, 20)
a = Accumulator(v)
c = cumsum(a)

@testset "Accumulator setindex!" begin
    @test sum(a) == sum(v)
    @test a.sums == Accumulator(v).sums
    a[3] = v[3] = 70
    @test sum(a) == sum(v)
    @test a.sums == Accumulator(v).sums
    a[1] = v[1] = 55
    @test sum(a) == sum(v)
    @test a.sums == Accumulator(v).sums
    a[10] = v[10] = 44
    @test sum(a) == sum(v)
    @test a.sums == Accumulator(v).sums

    for i=5:15
        a[i] = i
        v[i] = i
        @test sum(a) == sum(v)
        @test a.sums == Accumulator(v).sums
    end
end



@testset "Cumsum" begin
    c = cumsum(v)
    ca = cumsum(a)
    @test c == ca
    @test c == collect(ca)
    @test c == collect(c)
    @test diff(ca) == diff(c)
    @test keys(ca) == keys(v)
    @test length(ca) == length(v)
    @test firstindex(ca) == 1
    for r in c[1]-0.5:0.5:c[end]+0.5
        @test searchsortedfirst(c,r) == searchsortedfirst(ca,r)
    end
end

@testset "nonnumerical" begin
    v = string.('a':'z')
    a = Accumulator(v, op = *, init = _->"")
    c = cumsum(a)
    for i in eachindex(v)
        @test c[i] == prod(v[1:i])
    end
    @test c[end] == prod(v) == reduce(a)
    a[2] = "X"
    @test c[5] == "aXcde"
end


@testset "Reproducibility" begin
    Q = ExponentialQueue(3)
    Q[1] = 0.5; Q[2] = 0.3
    Qcp = deepcopy(Q)

    x = pop!(Q; rng = MersenneTwister(0))
    xcp = pop!(Qcp; rng = MersenneTwister(0))
    @test x == xcp
end

@testset "cavity" begin
    x = rand(1:10^4,10^4+11); 
    a = Accumulator(x);
    y = sum(x) .- x
    c = Cavity(a);
    @test c == y
    @test all(c[i] == y[i] for i in eachindex(c))
    @test cavity(x, +, 0) |> first == y
end

@testset "ExponentialQueue" begin
    e = ExponentialQueue([5,10],[10.0,0.0])
    i,t = peek(e)
    @test i == 5
    @test !isempty(e)
    i,t = pop!(e)
    @test i == 5
    @test isempty(e)
    e[10] = 5
    empty!(e)
    @test isempty(e)
end

@testset "ExponentialQueueDict" begin
    e = ExponentialQueueDict{String}()
    e["event1"] = 10
    i,t = peek(e)
    @test i == "event1"
    @test !isempty(e)
    i,t = pop!(e)
    @test i == "event1"
    @test isempty(e)
    e = ExponentialQueueDict{Int}()
    e[1000] = 10
    empty!(e)
    @test isempty(e)
end

nothing
