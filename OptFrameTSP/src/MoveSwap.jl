import OptFrame

function generate_random_move_swap(_::TSPProblem, solution::TSPSolution)::MoveSwap
    index_i = rand(1:solution.path_size-2)
    index_j = rand(index_i+1:solution.path_size)
    abs(index_i - index_j) >= 1 || error("bad move swap")
    return MoveSwap(index_i, index_j)
end

function generate_random_move_swap(
    problem_void::Ptr{Cvoid},
    solution_void::Ptr{Cvoid},
)::Ptr{Cvoid}
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

function apply_move_swap(
    problem_pointer::Ptr{MoveSwap},
    move_pointer::Ptr{MoveSwap},
    solution::TSPSolution,
)::Ptr{Cvoid}
    problem = unsafe_load(problem_pointer)
    move = unsafe_load(move_pointer)
    move_applied = apply_move_swap(problem, move, solution)
    applied_pointer = OptFrame.global_register(move_applied)
    return Ptr{Cvoid}(applied_pointer)
end

function apply_move_swap(
    problem_void::Ptr{Cvoid},
    move_void::Ptr{Cvoid},
    solution_void::Ptr{Nothing},
)::Ptr{Cvoid}
    problem = load_void_into_obj(problem_void, TSPProblem)
    move = load_void_into_obj(move_void, MoveSwap)
    solution = load_void_into_obj(solution_void, TSPSolution)
    move_applied = apply_move_swap(problem, move, solution)
    applied_pointer = OptFrame.global_register(move_applied)
    return Ptr{Cvoid}(applied_pointer)
end

function apply_update_move_swap(
    _::TSPProblem,
    move::MoveSwap,
    solution::TSPSolution,
    e::Float64,
)::PairMoveDoubleLib
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

function apply_update_move_swap(
    problem_void::Ptr{Cvoid},
    move_void::Ptr{Cvoid},
    solution_void::Ptr{Cvoid},
    e::Cdouble,
)::PairMoveDoubleLib
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


function move_is_equal_swap(
    problem_void::Ptr{Cvoid},
    move_a_void::Ptr{Cvoid},
    move_b_void::Ptr{Cvoid},
)::Cint
    problem = load_void_into_obj(problem_void, TSPProblem)
    move_a = load_void_into_obj(move_a_void, MoveSwap)
    move_b = load_void_into_obj(move_b_void, MoveSwap)
    return Int32(move_is_equal_swap(problem, move_a, move_b))
end

function move_can_be_applied_swap(
    _::TSPProblem,
    move::MoveSwap,
    solution::TSPSolution,
)::Bool
    return move.index_i != move.index_j &&
           move.index_i < solution.path_size &&
           move.index_j < solution.path_size
end

function move_can_be_applied_swap(
    problem_void::Ptr{Cvoid},
    move_void::Ptr{Cvoid},
    solution_void::Ptr{Cvoid},
)::Cint
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

function nsseq_swap_iterator_first(
    problem_void::Ptr{Cvoid},
    iterator_void::Ptr{Cvoid},
)::Cint
    p = convert(Ptr{TSPProblem}, problem_void)
    problem = unsafe_load(p)
    void_return = Int32(0)
    it = convert(Ptr{MoveSwap}, iterator_void)
    it2 = unsafe_pointer_to_objref(it)
    it2.index_i = 1
    it2.index_j = 3
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
    it = convert(Ptr{MoveSwap}, iterator_void)
    iterator = unsafe_load(it)
    iterator = nsseq_swap_iterator_next(problem, iterator)
    unsafe_store!(it, iterator)
    return Int32(0)
end


function nsseq_swap_iterator_is_done(problem::TSPProblem, iterator::MoveSwap)::Bool
    return iterator.index_i >= problem.number_of_cities
end

function nsseq_swap_iterator_is_done(
    problem_void::Ptr{Cvoid},
    iterator_void::Ptr{Cvoid},
)::Cint
    problem_ptr = convert(Ptr{TSPProblem}, problem_void)
    problem = unsafe_load(problem_ptr)
    iterator_ptr = convert(Ptr{MoveSwap}, iterator_void)
    iterator = unsafe_load(iterator_ptr)
    return Int32(nsseq_swap_iterator_is_done(problem, iterator))
end

function nsseq_swap_iterator_current(_::TSPProblem, iterator::MoveSwap)
    return deepcopy(iterator)
end

function nsseq_swap_iterator_current(
    problem_void::Ptr{Cvoid},
    iterator_void::Ptr{Cvoid},
)::Ptr{Cvoid}
    problem = load_void_into_obj(problem_void, TSPProblem)
    iterator = load_void_into_obj(iterator_void, MoveSwap)
    iterator_copy = nsseq_swap_iterator_current(problem, iterator)
    iterator_copy_pointer = OptFrame.global_register(iterator_copy)
    return Ptr{Cvoid}(iterator_copy_pointer)
end

