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