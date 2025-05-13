module TravelingSalesMan

import ..OptFrame

using Random: shuffle

export TSPProblem, TSPSolution
export initialize_tsp_problem, generate_random_initial_solution
export evaluate_solution, callback_deep_copy
export callback_tostring_tsp, free_tsp_solution
export generate_random_move_swap, apply_move_swap

mutable struct TSPProblem
    engine::OptFrame.Engine
    number_of_cities::Cint
    x_coordinates::Vector{Cint}
    y_coordinates::Vector{Cint}
    distances::Vector{Vector{Cfloat}}
end

mutable struct TSPSolution
    path_size::Cint
    cities_path::Vector{Cint}
end

mutable struct MoveSwap
    index_i::Cint
    index_j::Cint
end

function euclidean_distance(x1::Cint, y1::Cint, x2::Cint, y2::Cint)::Cfloat
    return sqrt((x2 - x1)^2 + (y2 - y1)^2)
end

function initialize_tsp_problem(cities::Vector{Cint}, x_coordinates::Vector{Cint}, y_coordinates::Vector{Cint}, log_level::Cint)::TSPProblem
    n_cities = Cint(length(cities))
    distances::Vector{Vector{Cfloat}} = []
    for i in 1:n_cities
        row::Vector{Cfloat} = []
        for j in 1:n_cities
            push!(row, euclidean_distance(x_coordinates[i], y_coordinates[i], x_coordinates[j], y_coordinates[j]))
        end
        push!(distances, row)
    end
    return TSPProblem(OptFrame.init_engine(log_level), n_cities, x_coordinates, y_coordinates, distances)
end

function initialize_tsp_problem(cities::Vector{Int64}, x_coordinates::Vector{Int64}, y_coordinates::Vector{Int64})::TSPProblem
    return initialize_tsp_problem(cities, x_coordinates, y_coordinates, 0)
end

function initialize_tsp_problem(cities::Vector{Int64}, x_coordinates::Vector{Int64}, y_coordinates::Vector{Int64}, log_level::Int64)::TSPProblem
    cint_cities = [Cint(city) for city in cities]
    cint_x = [Cint(x) for x in x_coordinates]
    cint_y = [Cint(y) for y in y_coordinates]
    return initialize_tsp_problem(cint_cities, cint_x, cint_y, Cint(log_level))
end

function generate_random_initial_solution(problem::TSPProblem)::TSPSolution
    return TSPSolution(problem.number_of_cities, shuffle(1:problem.number_of_cities))
end

function generate_random_initial_solution(problem_ptr::Ptr{TSPProblem})::Ptr{TSPSolution}
    problem = unsafe_load(problem_ptr)
    solution = generate_random_initial_solution(problem)
    return OptFrame.global_register(solution)
end

function generate_random_initial_solution(problem_void::Ptr{Cvoid})::Ptr{Nothing}
    problem_ptr = convert(Ptr{TSPProblem}, problem_void)
    solution = generate_random_initial_solution(problem_ptr)
    return Ptr{Nothing}(solution)
end

function callback_deep_copy(solution::TSPSolution)::TSPSolution
    return deepcopy(solution)
end

function callback_deep_copy(solution_ptr::Ptr{TSPSolution})::Ptr{TSPSolution}
    solution = unsafe_load(solution_ptr)
    solution_copy = callback_deep_copy(solution)
    return Ptr{TSPSolution}(solution_copy)
end

function callback_deep_copy(solution_void::Ptr{Cvoid})::Ptr{Cvoid}
    solution_ptr = convert(Ptr{TSPSolution}, solution_void)
    return callback_deep_copy(solution_ptr)
end

function evaluate_solution(problem::TSPProblem, solution::TSPSolution)::Cfloat
    evaluation = 0
    for i in 1:solution.path_size
        city1, city2 = solution.cities_path[i], solution.cities_path[(i+1)%solution.path_size+1]
        evaluation += problem.distances[city1][city2]
    end
    return evaluation
end

function evaluate_solution(problem_ptr::Ptr{TSPProblem}, solution_ptr::Ptr{TSPSolution})::Cfloat
    problem = unsafe_load(problem_ptr)
    solution = unsafe_load(solution_ptr)
    return evaluate_solution(problem, solution)
end

function evaluate_solution(problem_ptr::Ptr{TSPProblem}, solution::TSPSolution)::Cfloat
    problem = unsafe_load(problem_ptr)
    return evaluate_solution(problem, solution)
end


function callback_tostring_tsp(_::Ptr{Cvoid}, buffer::Ptr{Cchar}, size::Csize_t)::Csize_t
    s = "solution as string"
    n = min(sizeof(s), size - 1)
    unsafe_copyto!(buffer, pointer(s), n)
    unsafe_store!(buffer + n, 0)
    return sizeof(s)
end

function free_tsp_solution(s_ptr_void::Ptr{Nothing})::Int32
    s_ptr = convert(Ptr{TSPSolution}, s_ptr_void)
    OptFrame.global_unregister(s_ptr)
    return 0
end

function generate_random_move_swap(_::TSPProblem, solution::TSPSolution)::MoveSwap
    index_i = rand(1:solution.path_size)
    index_j = rand(2:solution.path_size)
    if index_j == index_i
        index_j = 1
    end
    return MoveSwap(index_i, index_j)
end

function apply_move_swap(_::TSPProblem, move::MoveSwap, solution::TSPSolution)::MoveSwap
    solution.cities_path[move.index_i], solution.cities_path[move.index_j] =
        solution.cities_path[move.index_j], solution.cities_path[move.index_i]
    return deepcopy(move)
end

end # modules TravelingSalesman
