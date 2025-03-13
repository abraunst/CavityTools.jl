using CavityTools
using Test
using Random

v = rand(0:200, 20)
a = Accumulator(v)
c = cumsum(a)

@testset "Accumulator" begin
    @test string(Accumulator()) == "Accumulator(Float64[])"
    @test Accumulator{Int}() == Accumulator(Int)
    @test a == v
    @test v == a
    @test a == Accumulator(v)
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
    @test string(CumSum(Accumulator([1]))) == "CumSum(Accumulator([1]))"
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


@testset "cavity" begin
    x = rand(1:10^4,10^4+11); 
    a = Accumulator(x);
    y = sum(x) .- x
    c = Cavity(a);
    @test keys(y) == keys(c) 
    @test c == y
    @test all(c[i] == y[i] for i in eachindex(c))
    @test cavity(x, +, 0) |> first == y
    @test cavity([1],+,0) == ([0], 1)
end

@testset "cavity with iterator" begin
    r = rand(1:10^4,10^4+11)
    source_itr = (sqrt(x) for x in r)
    source_vec = collect(source_itr)
    @test cavity(source_itr, +, 0.0) == cavity(source_vec, +, 0.0)
end

nothing
