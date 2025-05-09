module Knapsack

include("../src/Optframe.jl")
using .OptFrame

export KnapsackProblem, init_problem_kp, random_initial_solution, callback_sol_deepcopy_kp

using Random: shuffle

mutable struct KnapsackProblem
    vweights::Vector{Float64} 
    nitems::Cint            
    capacity::Float64
    engine::OptFrame.Engine
end

function init_problem_kp(vweights::Vector{Float64},nitems::Int64,capacity::Float64,ll::Int64)
    prob = KnapsackProblem(vweights,Cint(nitems),capacity, OptFrame.init_engine(ll))
    return prob
end

mutable struct KnapsackSolution
    selected::Vector{Bool}
end

function random_initial_solution(p::Ptr{KnapsackProblem})::Ptr{KnapsackSolution}
    prob = unsafe_load(p)
    n = Int(prob.nitems)
    
    selection = falses(n)
    total_weight = 0.0
    for i in shuffle(1:n)
        if total_weight + prob.vweights[i] <= prob.capacity
            selection[i] = true
            total_weight += prob.vweights[i]
        end
    end

    solution = KnapsackSolution(selection)
    sol_raw_ptr = register(prob.engine, solution)
    return sol_raw_ptr
end

function free_solution(ptr::Ptr{KnapsackSolution})
    # Wrap pointer back to a Julia reference (unsafe!)
    # This assumes the object was allocated in Julia and not already freed
    obj_ref = Base.unsafe_pointer_to_objref(ptr)::KnapsackSolution

    # Now let GC know this is no longer needed by simply doing nothing with it
    # And optionally forcing GC (not recommended in production)
    GC.gc()
    return nothing
end

const initial_solution_c = @cfunction(random_initial_solution, Ptr{KnapsackSolution}, (Ptr{KnapsackProblem},))

function callback_sol_deepcopy_kp(s1_ptr::Ptr{KnapsackSolution})::Ptr{KnapsackSolution}
    s1 = unsafe_load(s1_ptr)
    s2 = deepcopy(s1)
    sol2_raw_ptr = global_register(s2)
    return sol2_raw_ptr
end

end # module Knapsack