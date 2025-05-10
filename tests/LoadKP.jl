include("../src/Optframe.jl")
using .OptFrame
#
include("./Knapsack.jl")
using .Knapsack


# ==================

weights  = [12.0, 7.0, 11.0, 8.0, 9.0]
profits  = [6.0, 3.5, 5.5, 4.0, 4.5]
capacity = 26.0
n = length(weights)

println(n)

problem = init_problem_kp(weights, profits, n, capacity, 0)

println("Finished!")
println(problem.nitems)

println(problem)
#problem_ptr = Ref(problem)
problem_ptr = Ptr{KnapsackProblem}(pointer_from_objref(problem))

sol_ptr = random_initial_solution(problem_ptr)
println(sol_ptr)

println("invoking callback_sol_deepcopy_utils")

callback_sol_deepcopy_kp(sol_ptr)

println("testing evaluator")

e = evaluate_solution(problem_ptr, sol_ptr)
println(e)

println("OK")

println("will try add_evaluator")

f_ev_ptr  = @cfunction(evaluate_solution, Cdouble, (Ptr{Cvoid},Ptr{Cvoid}))
idx_ev = add_evaluator(problem.engine, f_ev_ptr, false, problem_ptr)
println("idx_ev = ", idx_ev)

println("will try add_constructive")

f_is_ptr  = @cfunction(random_initial_solution, Ptr{Cvoid}, (Ptr{Cvoid},))
f_cp_ptr  = @cfunction(callback_sol_deepcopy_kp, Ptr{Cvoid}, (Ptr{Cvoid},))
f_str_ptr = @cfunction(tostring_callback_julia_kp, Csize_t, (Ptr{Cvoid},Ptr{Cchar}, Csize_t))
f_del_ptr = @cfunction(free_solution_kp, Cint, (Ptr{Cvoid},))


idx_c = add_constructive(problem.engine, f_is_ptr, problem_ptr, f_cp_ptr, f_str_ptr, f_del_ptr)
println("idx_c = ", idx_c)


println("try check")


res = check(problem.engine,10, 100, true)
println("check=",res)

println("Finished!")