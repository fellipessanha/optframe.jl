include("../src/Optframe.jl")
using .OptFrame
#
include("./Knapsack.jl")
using .Knapsack

weights = [12.0, 7.0, 11.0, 8.0, 9.0]
profits = [6.0, 3.5, 5.5, 4.0, 4.5]
capacity = 26.0
n = length(weights)

problem = knapsack_problem_init(weights, profits, n, capacity)

println("Finished!")
println(problem.nitems)

println(problem)
#problem_ptr = Ref(problem)
problem_ptr = Ptr{KnapsackProblem}(pointer_from_objref(problem))


println("invoking random_initial_solution")

sol = random_initial_solution(problem)
println(sol)

println("invoking callback_sol_deepcopy_utils")

sol2 = callback_sol_deepcopy_kp(sol)

println("sol2=", sol2)

println("testing evaluator")

e = evaluate_solution(problem, sol)
println("evaluation:", e)

println("OK")

println("will try add_evaluator")

f_ev_ptr = @cfunction(evaluate_solution, Cdouble, (Ptr{Cvoid}, Ptr{Cvoid}))
idx_ev = add_evaluator(problem.engine, f_ev_ptr, false, Ptr{Nothing}(problem_ptr))
println("created component OptFrame:GeneralEvaluator:Evaluator ", idx_ev)

println("will try add_constructive")
f_is_ptr = @cfunction(random_initial_solution, Ptr{Cvoid}, (Ptr{Cvoid},))
f_cp_ptr = @cfunction(callback_sol_deepcopy_kp, Ptr{Cvoid}, (Ptr{Cvoid},))
f_str_ptr = @cfunction(tostring_callback_julia_kp, Csize_t, (Ptr{Cvoid}, Ptr{Cchar}, Csize_t))
f_del_ptr = @cfunction(free_solution_kp, Cint, (Ptr{Cvoid},))

idx_c = add_constructive(problem.engine, f_is_ptr, Ptr{Nothing}(problem_ptr), f_cp_ptr, f_str_ptr, f_del_ptr)
println("created component OptFrame:Constructive ", idx_c)


println("loading initial search")
initial_search_index = create_initial_search(problem.engine, idx_ev, idx_c)
println("created component OptFrame:InitialSearch ", initial_search_index)


println("testing add_ns")

m = ns_rand_bitflip(problem, sol)
println(m)

println("will try apply move=", m)

if move_cba_bitflip(problem, m, sol)
    println("can be applied!")
    println(sol)
    m2 = move_apply_bitflip(problem, m, sol)
    println(sol)
    println(m)
    println(m2)
else
    println("cannot be applied!")
end

println("trying move equality")
if move_eq_bitflip(problem, m, m2)
    println("moves are equal!")
else
    println("moves are not equal!")
end

println("will try add_constructive")
f_nsrand_ptr = @cfunction(ns_rand_bitflip, Ptr{Cvoid}, (Ptr{Cvoid}, Ptr{Cvoid},))
f_moveapply_ptr = @cfunction(move_apply_bitflip, Ptr{Cvoid}, (Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid},))
f_moveeq_ptr = @cfunction(move_eq_bitflip, Cint, (Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid},))
f_movecba_ptr = @cfunction(move_cba_bitflip, Cint, (Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid},))
decref_callback_ptr = @cfunction(free_solution_kp, Cint, (Ptr{Cvoid},))

idx_ns = add_ns(problem.engine, f_nsrand_ptr, f_moveapply_ptr, f_moveeq_ptr,
    f_movecba_ptr, Ptr{Nothing}(problem_ptr), decref_callback_ptr)
println("created component OptFrame:NS:FNS ", idx_ns)

println("creating nsseq(neighbor search sequence)")

iterator_init_ptr = @cfunction(nsseq_bitflip_iterator_init, Ptr{Cvoid}, (Ptr{Cvoid}, Ptr{Cvoid},))
iterator_first_ptr = @cfunction(nsseq_bitflip_iterator_first, Cvoid, (Ptr{Cvoid}, Ptr{Cvoid},))
iterator_next_ptr = @cfunction(nsseq_bitflip_iterator_next, Cvoid, (Ptr{Cvoid}, Ptr{Cvoid},))
iterator_is_done_ptr = @cfunction(nsseq_bitflip_iterator_is_done, Cvoid, (Ptr{Cvoid}, Ptr{Cvoid},))
iterator_current_ptr = @cfunction(nsseq_bitflip_iterator_current, Ptr{Cvoid}, (Ptr{Cvoid}, Ptr{Cvoid},))

nsseq_idx = add_nsseq(
    problem.engine,
    f_nsrand_ptr,
    iterator_init_ptr,
    iterator_first_ptr,
    iterator_next_ptr,
    iterator_is_done_ptr,
    iterator_current_ptr,
    f_moveapply_ptr,
    f_moveeq_ptr,
    f_movecba_ptr,
)

println("added nsseq with idx = ", nsseq_idx)


println("loading initial search")
initial_search_index = create_initial_search(problem.engine, idx_ev, idx_c)
println("created initial search with index ", initial_search_index)

component_list_index = create_component_list(problem.engine, "[OptFrame:NS 0]", "OptFrame:NS[]")

println(component_list_index)

# list loaded engine components
list_engine_components(problem.engine)

println()
println("engine will list builders ")
println("    skipping...")
println()
println("engine will list builders for :BasicSA ")
println(list_builders(problem.engine, ":BasicSA"))
println()


print("")
print("testing builder (build_global_search) for SA...")
print("")

gs_idx = build_global_search(problem.engine,
    "OptFrame:ComponentBuilder:GlobalSearch:SA:BasicSA",
    "OptFrame:GeneralEvaluator:Evaluator 0 OptFrame:InitialSearch 0  OptFrame:NS[] 0 0.99 100 999")
println("sos_idx=", gs_idx)


lout = run_global_search(problem.engine, gs_idx, 4.0)
println("lout=", lout)


println("try check")
res = check(problem.engine, 5, 3, false)
println("check=", res)

println("Finished!")
