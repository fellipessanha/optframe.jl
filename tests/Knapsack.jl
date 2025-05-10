module Knapsack

# no NOT load OptFrame here... leave it to parent!
#include("../src/Optframe.jl")
#using .OptFrame
import ..OptFrame

export KnapsackProblem, init_problem_kp, random_initial_solution, callback_sol_deepcopy_kp
export tostring_callback_julia_kp, callback_sol_deepcopy_kp, free_solution_kp
export evaluate_solution

using Random: shuffle

mutable struct KnapsackProblem
    vweights::Vector{Float64} 
    vprofits::Vector{Float64} 
    nitems::Cint            
    capacity::Float64
    engine::OptFrame.Engine
end

function init_problem_kp(vweights::Vector{Float64},vprofits::Vector{Float64},nitems::Int64,capacity::Float64,ll::Int64)
    prob = KnapsackProblem(vweights,vprofits,Cint(nitems),capacity, OptFrame.init_engine(ll))
    return prob
end

mutable struct KnapsackSolution
    selected::Vector{Bool}
end

# function evaluate_solution(p::Ptr{KnapsackProblem}, s::Ptr{KnapsackSolution})
function evaluate_solution(p_void::Ptr, s_void::Ptr)::Float64
    println("begin evaluate_solution()")
    s = convert(Ptr{KnapsackSolution}, s_void)
    p = convert(Ptr{KnapsackProblem}, p_void)
    prob = unsafe_load(p)
    n = Int(prob.nitems)
    sol = unsafe_load(s)
    total_weight = 0.0
    profit = 0.0
    for i in 1:n
        println("item i=",i)
        if sol.selected[i]
            total_weight += prob.vweights[i]
            profit += prob.vweights[i]
        end
    end
    println("end evaluate_solution() = ", profit)
    return profit
end

# function random_initial_solution(p::Ptr{KnapsackProblem})::Ptr{KnapsackSolution}
function random_initial_solution(p_void::Ptr)::Ptr
    println("begin random_initial_solution()")
    p = convert(Ptr{KnapsackProblem}, p_void)
    prob = unsafe_load(p)
    n = Int(prob.nitems)
    println("random_initial_solution n=",n)
    
    selection = falses(n)
    total_weight = 0.0
    for i in shuffle(1:n)
        if total_weight + prob.vweights[i] <= prob.capacity
            selection[i] = true
            total_weight += prob.vweights[i]
        end
    end

    solution = KnapsackSolution(selection)
    sol_raw_ptr = OptFrame.global_register(solution)
    return Ptr{Nothing}(sol_raw_ptr)
end

function free_solution_kp(s_ptr_void::Ptr)::Int32
    s_ptr = convert(Ptr{KnapsackSolution}, s_ptr_void)
    OptFrame.global_unregister(s_ptr)
    return 0
end

const initial_solution_c = @cfunction(random_initial_solution, Ptr{KnapsackSolution}, (Ptr{KnapsackProblem},))

# function callback_sol_deepcopy_kp(s1_ptr::Ptr{KnapsackSolution})::Ptr{KnapsackSolution}
function callback_sol_deepcopy_kp(s1_ptr_void::Ptr)::Ptr
    println("begin callback_sol_deepcopy_kp()")
    s1_ptr = convert(Ptr{KnapsackSolution}, s1_ptr_void)
    s1 = unsafe_load(s1_ptr)
    s2 = deepcopy(s1)
    sol2_raw_ptr = OptFrame.global_register(s2)
    return Ptr{Nothing}(sol2_raw_ptr)
end


function tostring_callback_julia_kp(sol::Ptr{KnapsackSolution}, buffer::Ptr{Cchar}, size::Csize_t)::Csize_t
    s = "solution as string"
    n = min(sizeof(s), size - 1)
    unsafe_copyto!(buffer, pointer(s), n)
    unsafe_store!(buffer + n, 0)  # null-terminate
    return sizeof(s)
end

end # module Knapsack