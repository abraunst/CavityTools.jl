using CavityTools
using Test

v = rand(0:200, 20)
a = Accumulator(v)

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
    for r in c[1]-0.5:0.5:c[end]+0.5
        @test searchsortedfirst(c,r) == searchsortedfirst(a,r)
    end
end

nothing