using Test
using OptFrame
using OptFrame: TSP

include("load_tsp.jl")

function main()
    @testset "OptFrame.jl Test Suite" begin
        @test true

        @testset "TSP" begin
            load_tsp()
        end
    end

    return nothing
end

main()
