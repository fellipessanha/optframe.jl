using Test

import OptFrame
import OptFrameTSP as TSP
import OptFrameKnapsack as KP

include("load_optframe.jl")
include("load_tsp.jl")
include("load_kp.jl")

function main()
    @testset "OptFrame.jl Test Suite" verbose = true begin
        @testset "■ Load OptFrame" verbose = true begin
            load_optframe()
        end

        @testset "▶ TSP" verbose = true begin
            load_tsp()
        end

        @testset "▶ Knapsack" verbose = true begin
            load_kp()
        end
    end

    return nothing
end

main()
