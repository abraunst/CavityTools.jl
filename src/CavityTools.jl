module CavityTools

using Random

export Accumulator, CumSum, Cavity, cavity, cavity!


include("accumulator.jl")
include("cumsum.jl")
include("cavity.jl")

end
