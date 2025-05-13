module TravelingSalesMan

import ..OptFrame

using Random: shuffle

export TSPProblem, TSPSolution
export initialize_tsp_problem, generate_random_initial_solution
export evaluate_solution, callback_deep_copy
export callback_tostring_tsp, free_tsp_solution
export generate_random_move_swap, apply_move_swap
export move_can_be_applied_swap, move_is_equal_swap
export nsseq_swap_iterator_init, nsseq_swap_iterator_first
export nsseq_swap_iterator_next, nsseq_swap_iterator_current
export nsseq_swap_iterator_is_done

mutable struct TSPProblem
    engine::OptFrame.Engine
    number_of_cities::Cint
    x_coordinates::Vector{Cint}
    y_coordinates::Vector{Cint}
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

function load_void_into_obj(pointer::Ptr{Cvoid}, type::Type)
    object = convert(Ptr{type}, pointer)
    return unsafe_load(object)
end

function euclidean_distance(x1::Cint, y1::Cint, x2::Cint, y2::Cint)::Float64
    return sqrt((x2 - x1)^2 + (y2 - y1)^2)
end

function initialize_tsp_problem(cities::Vector{Cint}, x_coordinates::Vector{Cint}, y_coordinates::Vector{Cint}, log_level::Cint)::TSPProblem
    n_cities = Cint(length(cities))
    distances::Vector{Vector{Float64}} = []
    for i in 1:n_cities
        row::Vector{Float64} = []
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

function callback_deep_copy(solution_void::Ptr{Cvoid})::Ptr{Cvoid}
    solution = load_void_into_obj(solution_void, TSPSolution)
    copy_solution = callback_deep_copy(solution)
    copy_pointer = OptFrame.global_register(copy_solution)
    return Ptr{Cvoid}(copy_pointer)
end

function evaluate_solution(problem::TSPProblem, solution::TSPSolution)::Float64
    evaluation = 0
    for i in 1:solution.path_size
        city1, city2 = solution.cities_path[i], solution.cities_path[(i+1)%solution.path_size+1]
        evaluation += problem.distances[city1][city2]
    end
    return evaluation
end

function evaluate_solution(problem_ptr::Ptr{TSPProblem}, solution_ptr::Ptr{TSPSolution})::Float64
    problem = unsafe_load(problem_ptr)
    solution = unsafe_load(solution_ptr)
    return evaluate_solution(problem, solution)
end


function evaluate_solution(problem_ptr::Ptr{Cvoid}, solution_ptr::Ptr{Cvoid})::Float64
    problem = load_void_into_obj(problem_ptr, TSPProblem)
    solution = load_void_into_obj(solution_ptr, TSPSolution)
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
    index_i = rand(1:solution.path_size-1)
    index_j = rand(index_i:solution.path_size)
    return MoveSwap(index_i, index_j)
end

function generate_random_move_swap(problem_void::Ptr{Cvoid}, solution_void::Ptr{Cvoid})::Ptr{Cvoid}
    problem = load_void_into_obj(problem_void, TSPProblem)
    solution = load_void_into_obj(solution_void, TSPSolution)
    move = generate_random_move_swap(problem, solution)
    move_pointer = OptFrame.global_register(move)
    return Ptr{Cvoid}(move_pointer)
end

function apply_move_swap(_::TSPProblem, move::MoveSwap, solution::TSPSolution)::MoveSwap
    solution.cities_path[move.index_i], solution.cities_path[move.index_j] =
        solution.cities_path[move.index_j], solution.cities_path[move.index_i]
    return deepcopy(move)
end

function apply_move_swap(problem_pointer::Ptr{MoveSwap}, move_pointer::Ptr{MoveSwap}, solution::TSPSolution)::Ptr{Cvoid}
    problem = unsafe_load(problem_pointer)
    move = unsafe_load(move_pointer)
    move_applied = apply_move_swap(problem, move, solution)
    applied_pointer = OptFrame.global_register(move_applied)
    return Ptr{Cvoid}(applied_pointer)
end

function apply_move_swap(problem_void::Ptr{Cvoid}, move_void::Ptr{Cvoid}, solution_void::Ptr{Nothing})::Ptr{Cvoid}
    problem = load_void_into_obj(problem_void, TSPProblem)
    move = load_void_into_obj(move_void, MoveSwap)
    solution = load_void_into_obj(solution_void, TSPSolution)
    move_applied = apply_move_swap(problem, move, solution)
    applied_pointer = OptFrame.global_register(move_applied)
    return Ptr{Cvoid}(applied_pointer)
end

function move_is_equal_swap(_::TSPProblem, move_a::MoveSwap, move_b::MoveSwap)::Bool
    move_a_idxs = (move_a.index_i, move_a.index_j)
    return move_b.index_i in move_a_idxs && move_b.index_j in move_a_idxs
end


function move_is_equal_swap(problem_void::Ptr{Cvoid}, move_a_void::Ptr{Cvoid}, move_b_void::Ptr{Cvoid})::Cint
    problem = load_void_into_obj(problem_void, TSPProblem)
    move_a = load_void_into_obj(move_a_void, MoveSwap)
    move_b = load_void_into_obj(move_b_void, MoveSwap)
    return Int32(move_is_equal_swap(problem, move_a, move_b))
end

function move_can_be_applied_swap(_::TSPProblem, move::MoveSwap, solution::TSPSolution)::Bool
    return move.index_i != move.index_j &&
           move.index_i < solution.path_size &&
           move.index_j < solution.path_size
end

function move_can_be_applied_swap(problem_void::Ptr{Cvoid}, move_void::Ptr{Cvoid}, solution_void::Ptr{Cvoid})::Cint
    problem = load_void_into_obj(problem_void, TSPProblem)
    move = load_void_into_obj(move_void, MoveSwap)
    solution = load_void_into_obj(solution_void, TSPSolution)
    return Cint(move_can_be_applied_swap(problem, move, solution))
end
function nsseq_swap_iterator_init()::MoveSwap
    return MoveSwap(Cint(1), Cint(1))
end

function nsseq_swap_iterator_init(_::TSPProblem, _::TSPSolution)::MoveSwap
    return nsseq_swap_iterator_init()
end

function nsseq_swap_iterator_init(_::Ptr{Cvoid}, _::Ptr{Cvoid})::Ptr{Cvoid}
    init_move = nsseq_swap_iterator_init()
    init_move_pointer = OptFrame.global_register(init_move)
    return Ptr{Nothing}(init_move_pointer)
end

function nsseq_swap_iterator_first(_::TSPProblem, iterator::MoveSwap)::Cvoid
    iterator.index_i = 1
    iterator.index_j = 2
end

function nsseq_swap_iterator_first(problem_void::Ptr{Cvoid}, iterator_void::Ptr{Cvoid})::Cint
    problem = load_void_into_obj(problem_void, TSPProblem)
    iterator_ptr = convert(Ptr{MoveSwap}(iterator_void))
    iterator::MoveSwap = unsafe_pointer_to_objref(iterator_ptr)
    nsseq_swap_iterator_first(problem, iterator)
    void_return = Int32(0)
    return void_return
end

function nsseq_swap_iterator_next(problem::TSPProblem, iterator::MoveSwap)::Nothing
    if iterator.index_j == problem.number_of_cities
        iterator.index_i += 1
        iterator.index_j = iterator.index_i + 1
    else
        iterator.index_j += 1
    end
end


function nsseq_swap_iterator_next(problem_void::Ptr{Cvoid}, iterator_void::Ptr{Cvoid})::Cint
    problem = load_void_into_obj(problem_void, TSPProblem)
    iterator::MoveSwap = load_void_into_obj(iterator_void, MoveSwap)
    nsseq_swap_iterator_next(problem, iterator)
    return iterator.index_i
end


function nsseq_swap_iterator_is_done(problem::TSPProblem, iterator::MoveSwap)::Bool
    return iterator.index_i >= problem.number_of_cities
end

function nsseq_swap_iterator_next(problem_void::Ptr{Cvoid}, iterator_void::Ptr{Cvoid})::Cint
    problem_ptr = convert(Ptr{TSPProblem}(problem_void))
    problem = unsafe_load(problem_ptr)
    iterator_ptr = convert(Ptr{MoveSwap}(iterator_void))
    iterator = unsafe_load(iterator_ptr)
    return Int32(nsseq_swap_iterator_is_done(problem, iterator))
end

function nsseq_swap_iterator_current(_::TSPProblem, iterator::MoveSwap)
    return deepcopy(iterator)
end

function nsseq_swap_iterator_current(problem_void::Ptr{Cvoid}, iterator_void::Ptr{Cvoid})::Ptr{Cvoid}
    iterator = load_void_into_obj(iterator_void, MoveSwap)
    problem = load_void_into_obj(problem_void, MoveSwap)
    iterator_copy = nsseq_swap_iterator_current(problem, iterator)
    iterator_copy_pointer = OptFrame.global_register(iterator_copy)
    return Ptr{Cvoid}(iterator_copy_pointer)
end

end # modules TravelingSalesman
