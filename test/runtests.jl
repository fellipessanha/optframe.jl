using Test
using OptFrame
using OptFrame: TSP

include("load_tsp.jl")

function main()
    @testset "OptFrame.jl Test Suite" verbose = true begin
        @test true

        @testset "TSP" verbose = true begin
            load_tsp()
        end
    end

    return nothing
end

main()
