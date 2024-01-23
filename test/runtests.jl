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



@testset "Accumulator searchsortedfirst" begin
    c = cumsum(v)
    ca = cumsum(a)
    for r in c[1]-0.5:0.5:c[end]+0.5
        @test searchsortedfirst(c,r) == searchsortedfirst(ca,r)
    end
end

@testset "nonnumerical" begin
    v = string.('a':'z')
    a = Accumulator(v,*,T->"")
    c = cumsum(a)
    for i in eachindex(v)
        @test c[i] == prod(v[1:i])
    end
    @test c[end] == prod(v) == sum(a)
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
