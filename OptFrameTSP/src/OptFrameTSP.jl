module OptFrameTSP

import Random: randperm # instead of `Random.shuffle`
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

function load_void_into_obj(pointer::Ptr{Cvoid}, type::Type)
    object = convert(Ptr{type}, pointer)

    return unsafe_load(object)
end

# Function to parse the file and extract coordinates
function parse_trp_file(::Type{T}, file_path::AbstractString) where {T}
    # Initialize empty arrays for x and y coordinates
    x_coordinates = T[]
    y_coordinates = T[]

    # Open the file for reading
    open(file_path, "r") do file
        # Read through each line of the file
        for line in eachline(file)
            # Check if the line starts with "NODE_COORD_SECTION"
            if line == "NODE_COORD_SECTION"
                # Start reading coordinates from the next line
                for coord_line in eachline(file)
                    # Split the line into parts
                    parts = split(coord_line)
                    # Break if we reach the end of the coordinates section
                    if isempty(parts) || length(parts) < 3
                        break
                    end
                    # Parse x and y coordinates, ignoring the first column
                    push!(x_coordinates, parse(T, parts[2]))
                    push!(y_coordinates, parse(T, parts[3]))
                end
                break  # Exit after processing the coordinates section
            end
        end
    end

    return (x_coordinates, y_coordinates)
end

parse_trp_file(file_path::AbstractString) = parse_trp_file(Float64, file_path)

function euclidean_distance(x1::T, y1::T, x2::T, y2::T)::T where {T}
    return sqrt((x2 - x1)^2 + (y2 - y1)^2)
end

function initialize_tsp_problem(cities::Vector{Cint}, x_coordinates::Vector{T}, y_coordinates::Vector{T}, log_level::Cint)::TSPProblem where {T}
    n_cities  = Cint(length(cities))
    distances = Vector{T}[]

    for i in 1:n_cities
        row = T[]

        for j in 1:n_cities
            push!(row, euclidean_distance(x_coordinates[i], y_coordinates[i], x_coordinates[j], y_coordinates[j]))
        end
        
        push!(distances, row)
    end
    
    return TSPProblem(OptFrame.init_engine(log_level), n_cities, x_coordinates, y_coordinates, distances)
end

function initialize_tsp_problem(cities::Vector{U}, x_coordinates::Vector{T}, y_coordinates::Vector{T})::TSPProblem where {T,U<:Integer}
    cint_cities = Cint.(cities)

    return initialize_tsp_problem(cint_cities, x_coordinates, y_coordinates, Cint(0))
end

function generate_random_initial_solution(problem::TSPProblem)::TSPSolution
    return TSPSolution(problem.number_of_cities, randperm(problem.number_of_cities))
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
    evaluation = 0.0
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
    index_i = rand(1:solution.path_size-2)
    index_j = rand(index_i+1:solution.path_size)
    abs(index_i - index_j) >= 1 || error("bad move swap")
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

function apply_update_move_swap(_::TSPProblem, move::MoveSwap, solution::TSPSolution, e::Float64)::PairMoveDoubleLib
    diff = 0.0
    println("apply update i=", move.index_i, " j=", move.index_j)
    n = problem.number_of_cities
    before_i = ((n + move.index_i - 1) % n) + 1
    after_i = ((n + move.index_i + 1) % n) + 1
    before_j = ((n + move.index_j - 1) % n) + 1
    after_j = ((n + move.index_j + 1) % n) + 1

    diff -= problem.distances[before_i][move.index_i]
    diff -= problem.distances[move.index_i][after_i]
    diff -= problem.distances[before_j][move.index_j]
    diff -= problem.distances[move.index_j][after_j]
    diff += problem.distances[before_i][move.index_j]
    diff += problem.distances[move.index_j][after_i]
    diff += problem.distances[before_j][move.index_i]
    diff += problem.distances[move.index_i][after_j]

    solution.cities_path[move.index_i], solution.cities_path[move.index_j] =
        solution.cities_path[move.index_j], solution.cities_path[move.index_i]

    return PairMoveDoubleLib(OptFrame.global_register(deepcopy(move)), diff)
end

function apply_update_move_swap(problem_void::Ptr{Cvoid}, move_void::Ptr{Cvoid}, solution_void::Ptr{Cvoid}, e::Cdouble)::PairMoveDoubleLib
    problem = load_void_into_obj(problem_void, TSPProblem)
    move = load_void_into_obj(move_void, MoveSwap)
    solution = load_void_into_obj(solution_void, TSPSolution)
    pair_md = apply_update_move_swap(problem, move, solution, e)
    return pair_md
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
    iterator.index_j = 3
end

function nsseq_swap_iterator_first(problem_void::Ptr{Cvoid}, iterator_void::Ptr{Cvoid})::Cint
    #println("begin nsseq_swap_iterator_first()")
    p = convert(Ptr{TSPProblem}, problem_void)
    problem = unsafe_load(p)
    void_return = Int32(0)
    it = convert(Ptr{MoveSwap}, iterator_void)
    it2 = unsafe_pointer_to_objref(it)
    it2.index_i = 1
    it2.index_j = 3
    #println("end nsseq_swap_iterator_first")
    return void_return
end

function nsseq_swap_iterator_next(problem::TSPProblem, iterator::MoveSwap)::MoveSwap
    if iterator.index_j == problem.number_of_cities
        iterator.index_i += 1
        iterator.index_j = iterator.index_i + 1
    else
        iterator.index_j += 1
    end
    return iterator
end


function nsseq_swap_iterator_next(problem_void::Ptr{Cvoid}, iterator_void::Ptr{Cvoid})::Cint
    problem = load_void_into_obj(problem_void, TSPProblem)
    # iterator::MoveSwap = load_void_into_obj(iterator_void, MoveSwap)
    it = convert(Ptr{MoveSwap}, iterator_void)
    iterator = unsafe_load(it)
    iterator = nsseq_swap_iterator_next(problem, iterator)
    unsafe_store!(it, iterator)
    #return iterator.index_i
    return Int32(0)
end


function nsseq_swap_iterator_is_done(problem::TSPProblem, iterator::MoveSwap)::Bool
    return iterator.index_i >= problem.number_of_cities
end

function nsseq_swap_iterator_is_done(problem_void::Ptr{Cvoid}, iterator_void::Ptr{Cvoid})::Cint
    #println("begin nsseq_swap_iterator_is_done()")
    problem_ptr = convert(Ptr{TSPProblem}, problem_void)
    problem = unsafe_load(problem_ptr)
    iterator_ptr = convert(Ptr{MoveSwap}, iterator_void)
    iterator = unsafe_load(iterator_ptr)
    #println("end nsseq_swap_iterator_is_done")
    return Int32(nsseq_swap_iterator_is_done(problem, iterator))
end

function nsseq_swap_iterator_current(_::TSPProblem, iterator::MoveSwap)
    return deepcopy(iterator)
end

function nsseq_swap_iterator_current(problem_void::Ptr{Cvoid}, iterator_void::Ptr{Cvoid})::Ptr{Cvoid}
    #println("begin nsseq_swap_iterator_current")
    problem = load_void_into_obj(problem_void, TSPProblem)
    iterator = load_void_into_obj(iterator_void, MoveSwap)
    iterator_copy = nsseq_swap_iterator_current(problem, iterator)
    iterator_copy_pointer = OptFrame.global_register(iterator_copy)
    return Ptr{Cvoid}(iterator_copy_pointer)
end

end # module TSP

