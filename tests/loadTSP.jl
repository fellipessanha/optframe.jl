using Base: unsafe_load_commands
include("../src/Optframe.jl")
using .OptFrame
#
include("./TravelingSalesMan.jl")
using .TravelingSalesMan

cities = [1, 2, 3]
x_coordinates = [10, 20, 30]
y_coordinates = [10, 20, 30]

problem = initialize_tsp_problem(cities, x_coordinates, y_coordinates)

println(problem)

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
evaluation_from_ptr = evaluate_solution(problem_ptr, solution_ptr)

println("evaluation from object: ", evaluation)
println("evaluation from pointer: ", evaluation_from_ptr)

evaluator_pointer = @cfunction(evaluate_solution, Cdouble, (Ptr{Cvoid}, Ptr{Cvoid}))
evaluator_index = add_evaluator(problem.engine, evaluator_pointer, false, problem_void)
println("added evaluator with index ", evaluator_index)

initial_solution_pointer = @cfunction(generate_random_initial_solution, Ptr{Cvoid}, (Ptr{Cvoid},))
deepcopy_callback_pointer = @cfunction(callback_deep_copy, Ptr{Cvoid}, (Ptr{Cvoid},))
tostring_callback_pointer = @cfunction(callback_tostring_tsp, Csize_t, (Ptr{Cvoid}, Ptr{Cchar}, Csize_t))
free_tsp_solution_pointer = @cfunction(free_tsp_solution, Cint, (Ptr{Cvoid},))

constructive_index = add_constructive(problem.engine, initial_solution_pointer, problem_void, deepcopy_callback_pointer, tostring_callback_pointer, free_tsp_solution_pointer)
println("created component OptFrame:Constructive ", constructive_index)

