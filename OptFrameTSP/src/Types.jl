import OptFrame

mutable struct TSPProblem
    engine::OptFrame.Engine
    number_of_cities::Cint
    x_coordinates::Vector{Float64}
    y_coordinates::Vector{Float64}
    distances::Vector{Vector{Float64}}
end

mutable struct TSPSolution
    path_size::Cint
    cities_path::Vector{Cint}
end

mutable struct MoveSwap
    index_i::Cint
    index_j::Cint
end

mutable struct Move2Opt
    index_i::Cint
    index_j::Cint
end
