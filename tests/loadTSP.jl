using Base: unsafe_load_commands
include("../src/Optframe.jl")
using .OptFrame
#
include("./TravelingSalesMan.jl")
using .TravelingSalesMan

x_coordinates, y_coordinates = parse_trp_file("../berlin52.txt")
cities = [i for i in 1:length(x_coordinates)]

problem = initialize_tsp_problem(cities, x_coordinates, y_coordinates)

# Verbosity filter 4 is disabled. Filter -1 is debug.
b2 = experimental_set_parameter(problem.engine, "COMPONENT_LOG_LEVEL", "-1")
println("b2=", b2)

#println(problem)

problem_ptr = Ptr{TSPProblem}(pointer_from_objref(problem))
problem_void = Ptr{Cvoid}(problem_ptr)

println("initializing random solution")

solution = generate_random_initial_solution(problem)
solution_ptr = generate_random_initial_solution(problem_ptr)

println("solutions generated")
println("from object: ", solution)
println("from pointer: ", unsafe_load(solution_ptr))

solution_copy = callback_deep_copy(solution)
println("deep copying solution. got: ", solution_copy)

println("evaluating solution...")

evaluation = evaluate_solution(problem, solution)

println("evaluation from object: ", evaluation)

evaluator_pointer = @cfunction(evaluate_solution, Cdouble, (Ptr{Cvoid}, Ptr{Cvoid}))
evaluator_index = add_evaluator(problem.engine, evaluator_pointer, false, problem_void)
println("added evaluator with index ", evaluator_index)

initial_solution_pointer = @cfunction(generate_random_initial_solution, Ptr{Cvoid}, (Ptr{Cvoid},))
deepcopy_callback_pointer = @cfunction(callback_deep_copy, Ptr{Cvoid}, (Ptr{Cvoid},))
tostring_callback_pointer = @cfunction(callback_tostring_tsp, Csize_t, (Ptr{Cvoid}, Ptr{Cchar}, Csize_t))
free_tsp_solution_pointer = @cfunction(free_tsp_solution, Cint, (Ptr{Cvoid},))

constructive_index = add_constructive(problem.engine, initial_solution_pointer, problem_void, deepcopy_callback_pointer, tostring_callback_pointer, free_tsp_solution_pointer)
println("created component OptFrame:Constructive ", constructive_index)

initial_search_index = create_initial_search(problem.engine, evaluator_index, constructive_index)

println("created component OptFrame:InitialSearch ", initial_search_index)

swap_move = generate_random_move_swap(problem, solution)

println("generated swap move:", swap_move)
println("pre-swap solution: ", solution)
println("post-swap solution: ", solution)

random_move_pointer = @cfunction(generate_random_move_swap, Ptr{Cvoid}, (Ptr{Cvoid}, Ptr{Cvoid},))
apply_move_pointer = @cfunction(apply_move_swap, Ptr{Cvoid}, (Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid},))
equals_move_pointer = @cfunction(move_is_equal_swap, Cint, (Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid},))
can_be_applied_move_pointer = @cfunction(move_can_be_applied_swap, Cint, (Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid},))

idx_ns = add_ns(
    problem.engine,
    random_move_pointer,
    apply_move_pointer,
    equals_move_pointer,
    can_be_applied_move_pointer,
    problem_void,
    free_tsp_solution_pointer
)
println("created component OptFrame:NS:FNS ", idx_ns)

iterator_init_ptr = @cfunction(nsseq_swap_iterator_init, Ptr{Cvoid}, (Ptr{Cvoid}, Ptr{Cvoid}))
iterator_first_ptr = @cfunction(nsseq_swap_iterator_first, Cint, (Ptr{Cvoid}, Ptr{Cvoid},))
iterator_next_ptr = @cfunction(nsseq_swap_iterator_next, Cint, (Ptr{Cvoid}, Ptr{Cvoid},))
iterator_is_done_ptr = @cfunction(nsseq_swap_iterator_is_done, Cint, (Ptr{Cvoid}, Ptr{Cvoid},))
iterator_current_ptr = @cfunction(nsseq_swap_iterator_current, Ptr{Cvoid}, (Ptr{Cvoid}, Ptr{Cvoid},))

nsseq_idx = add_nsseq(
    problem.engine,
    initial_solution_pointer,
    iterator_init_ptr,
    iterator_first_ptr,
    iterator_next_ptr,
    iterator_is_done_ptr,
    iterator_current_ptr,
    apply_move_pointer,
    equals_move_pointer,
    can_be_applied_move_pointer,
    problem_void,
    free_tsp_solution_pointer
)
println("added nsseq with idx = ", nsseq_idx)

println("try check (with disabled prints)")
res = check(problem.engine, 300, 5, false)
println("check=", res)

