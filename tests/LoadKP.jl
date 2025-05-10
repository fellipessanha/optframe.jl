include("../src/Optframe.jl")
using .OptFrame
#
include("./Knapsack.jl")
using .Knapsack


# ==================

weights  = [12.0, 7.0, 11.0, 8.0, 9.0]
capacity = 26.0
n = length(weights)

println(n)

problem = init_problem_kp(weights, n, capacity, 0)

println("Finished!")
println(problem.nitems)

println(problem)
#problem_ptr = Ref(problem)
problem_ptr = Ptr{KnapsackProblem}(pointer_from_objref(problem))

sol_ptr = random_initial_solution(problem_ptr)
println(sol_ptr)



println("invoking callback_sol_deepcopy_utils")

callback_sol_deepcopy_kp(sol_ptr)

println("OK")

f_is_ptr  = @cfunction(random_initial_solution, Ptr{Cvoid}, (Ptr{Cvoid},))
f_cp_ptr  = @cfunction(callback_sol_deepcopy_kp, Ptr{Cvoid}, (Ptr{Cvoid},))
f_str_ptr = @cfunction(tostring_callback_julia_kp, Csize_t, (Ptr{Cvoid},Ptr{Cchar}, Csize_t))
f_del_ptr = @cfunction(free_solution_kp, Cint, (Ptr{Cvoid},))


println("will try add_constructive")

add_constructive(problem.engine, problem_ptr, f_is_ptr, f_cp_ptr, f_str_ptr, f_del_ptr)