module Knapsack

import ..OptFrame

export KnapsackProblem, knapsack_problem_init
export random_initial_solution, callback_sol_deepcopy_kp
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

function knapsack_problem_init(vweights::Vector{Float64},vprofits::Vector{Float64},nitems::Int64,capacity::Float64,ll::Int64=0)
    prob = KnapsackProblem(vweights,vprofits,Cint(nitems),capacity, OptFrame.init_engine(ll))
    return prob
end

mutable struct KnapsackSolution
    selected::Vector{Bool}
end

function evaluate_solution(problem::KnapsackProblem, solution::KnapsackSolution)
    total_weight = 0.0
    profit = 0.0
    for i in 1:problem.nitems
        if solution.selected[i]
            total_weight += problem.vweights[i]
            profit += problem.vweights[i]
        end
    end
    return profit
end

function evaluate_solution(p_ptr::Ptr{KnapsackProblem}, s_ptr::Ptr{KnapsackSolution})::Float64
    problem = unsafe_load(p_ptr)
    solution = unsafe_load(s_ptr)
    return evaluate_solution(problem, solution)
end

function evaluate_solution(problem::KnapsackProblem, s_ptr::Ptr{KnapsackSolution})::Float64
    return evaluate_solution(problem, unsafe_load(s_ptr))
end

function evaluate_solution(p_void::Ptr{Nothing}, s_void::Ptr{Nothing})::Float64
    s_ptr = convert(Ptr{KnapsackSolution}, s_void)
    p_ptr = convert(Ptr{KnapsackProblem}, p_void)
    problem = unsafe_load(p_ptr)
    solution = unsafe_load(s_ptr)
    return evaluate_solution(problem, solution)
end

function random_initial_solution(problem::KnapsackProblem)::KnapsackSolution
    selection = falses(problem.nitems)
    sum = 0.0
    for i in shuffle(1:problem.nitems)
        if sum + problem.vweights[i] <= problem.capacity
            selection[i] = true
            sum += problem.vweights[i]
        end
    end
    return KnapsackSolution(selection)
end

function random_initial_solution(p_void::Ptr{Nothing})::Ptr{Nothing}
    p = convert(Ptr{KnapsackProblem}, p_void)
    prob = unsafe_load(p)
    solution = random_initial_solution(prob)
    sol_raw_ptr = OptFrame.global_register(solution)
    return Ptr{Nothing}(sol_raw_ptr)
end

function callback_sol_deepcopy_kp(s1::KnapsackSolution)::KnapsackSolution
    return deepcopy(s1)
end

function callback_sol_deepcopy_kp(s1_ptr_void::Ptr{Nothing})::Ptr{Nothing}
    s1_ptr = convert(Ptr{KnapsackSolution}, s1_ptr_void)
    s1 = unsafe_load(s1_ptr)
    s2 = callback_sol_deepcopy_kp(s1)
    sol2_raw_ptr = OptFrame.global_register(s2)
    return Ptr{Nothing}(sol2_raw_ptr)
end

function free_solution_kp(s_ptr_void::Ptr{Nothing})::Int32
    s_ptr = convert(Ptr{KnapsackSolution}, s_ptr_void)
    OptFrame.global_unregister(s_ptr)
    return 0
end

function tostring_callback_julia_kp(sol::Ptr{KnapsackSolution}, buffer::Ptr{Cchar}, size::Csize_t)::Csize_t
    s = "solution as string"
    n = min(sizeof(s), size - 1)
    unsafe_copyto!(buffer, pointer(s), n)
    unsafe_store!(buffer + n, 0)
    return sizeof(s)
end

end # module Knapsack