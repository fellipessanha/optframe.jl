module OptFrameKnapsack

import Random: randperm # Instead of `Random.shuffle`
import OptFrame

mutable struct KnapsackProblem
    vweights::Vector{Float64}
    vprofits::Vector{Float64}
    nitems::Cint
    capacity::Float64
    engine::OptFrame.Engine
end

function knapsack_problem_init(
    vweights::Vector{Float64},
    vprofits::Vector{Float64},
    nitems::Int64,
    capacity::Float64,
    ll::Int64 = 0,
)
    prob = KnapsackProblem(
        vweights,
        vprofits,
        Cint(nitems),
        capacity,
        OptFrame.init_engine(ll),
    )
    return prob
end

mutable struct KnapsackSolution
    selected::Vector{Bool}
end

function evaluate_solution(problem::KnapsackProblem, solution::KnapsackSolution)
    total_weight = 0.0
    profit = 0.0
    for i = 1:problem.nitems
        if solution.selected[i]
            total_weight += problem.vweights[i]
            profit += problem.vprofits[i]
        end
    end
    if total_weight > problem.capacity
        profit += 1000.0 * (problem.capacity - total_weight)
    end
    return profit
end

function evaluate_solution(
    p_ptr::Ptr{KnapsackProblem},
    s_ptr::Ptr{KnapsackSolution},
)::Float64
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
    for i in randperm(problem.nitems)
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

function tostring_callback_julia_kp(
    sol::Ptr{KnapsackSolution},
    buffer::Ptr{Cchar},
    size::Csize_t,
)::Csize_t
    s = "solution as string"
    n = min(sizeof(s), size - 1)
    unsafe_copyto!(buffer, pointer(s), n)
    unsafe_store!(buffer + n, 0)
    return sizeof(s)
end

# =======================

mutable struct MoveBitFlip
    k::Cint
end

# TODO: remove this function! Arena should be Ptr{Nothing}!!!
function free_move_kp(m_ptr_void::Ptr{Nothing})::Int32
    m_ptr = convert(Ptr{MoveBitFlip}, m_ptr_void)
    OptFrame.global_unregister(m_ptr)
    return 0
end

# function random_initial_solution(problem::KnapsackProblem)::KnapsackSolution
#     selection = falses(problem.nitems)
#     sum = 0.0
#     for i in randperm(problem.nitems)
#         if sum + problem.vweights[i] <= problem.capacity
#             selection[i] = true
#             sum += problem.vweights[i]
#         end
#     end
#     return KnapsackSolution(selection)
# end

function ns_rand_bitflip(problem::KnapsackProblem, solution::KnapsackSolution)::MoveBitFlip
    k = rand(1:problem.nitems)
    mv = MoveBitFlip(Int32(k))
    return mv
end

function ns_rand_bitflip(p_void::Ptr{Nothing}, s_void::Ptr{Nothing})::Ptr{Nothing}
    p = convert(Ptr{KnapsackProblem}, p_void)
    problem = unsafe_load(p)
    s = convert(Ptr{KnapsackSolution}, s_void)
    solution = unsafe_load(s)
    m = ns_rand_bitflip(problem, solution)
    m_raw_ptr = OptFrame.global_register(m)
    return Ptr{Nothing}(m_raw_ptr)
end

function move_apply_bitflip(
    problem::KnapsackProblem,
    m::MoveBitFlip,
    solution::KnapsackSolution,
)::MoveBitFlip
    solution.selected[m.k] = 1 - solution.selected[m.k]
    return MoveBitFlip(m.k)
end

function move_apply_bitflip(
    p_void::Ptr{Nothing},
    m_void::Ptr{Nothing},
    s_void::Ptr{Nothing},
)::Ptr{Nothing}
    p = convert(Ptr{KnapsackProblem}, p_void)
    problem = unsafe_load(p)
    s = convert(Ptr{KnapsackSolution}, s_void)
    solution = unsafe_load(s)
    m = convert(Ptr{MoveBitFlip}, m_void)
    m1 = unsafe_load(m)
    m2 = move_apply_bitflip(problem, m1, solution)
    m2_raw_ptr = OptFrame.global_register(m2)
    return Ptr{Nothing}(m2_raw_ptr)
end

function move_cba_bitflip(
    problem::KnapsackProblem,
    m::MoveBitFlip,
    solution::KnapsackSolution,
)::Bool
    return true
end

function move_cba_bitflip(
    p_void::Ptr{Nothing},
    m_void::Ptr{Nothing},
    s_void::Ptr{Nothing},
)::Int32
    p = convert(Ptr{KnapsackProblem}, p_void)
    problem = unsafe_load(p)
    s = convert(Ptr{KnapsackSolution}, s_void)
    solution = unsafe_load(s)
    m = convert(Ptr{MoveBitFlip}, m_void)
    m1 = unsafe_load(m)
    return Int32(move_cba_bitflip(problem, m1, solution))
end


function move_eq_bitflip(problem::KnapsackProblem, m1::MoveBitFlip, m2::MoveBitFlip)::Bool
    return m1.k == m2.k
end

function move_eq_bitflip(
    p_void::Ptr{Nothing},
    m1_void::Ptr{Nothing},
    m2_void::Ptr{Nothing},
)::Int32
    p_ptr = convert(Ptr{KnapsackProblem}, p_void)
    problem = unsafe_load(p_ptr)
    m1_ptr = convert(Ptr{MoveBitFlip}, m1_void)
    m1 = unsafe_load(m1_ptr)
    m2_ptr = convert(Ptr{MoveBitFlip}, m2_void)
    m2 = unsafe_load(m2_ptr)
    return Int32(move_eq_bitflip(problem, m1, m2))
end

function nsseq_bitflip_iterator_init(
    problem::KnapsackProblem,
    solution::KnapsackSolution,
)::MoveBitFlip
    return MoveBitFlip(Int32(-1))
end

function nsseq_bitflip_iterator_init_c(
    p_void::Ptr{Nothing},
    s_void::Ptr{Nothing},
)::Ptr{Nothing}
    p = convert(Ptr{KnapsackProblem}, p_void)
    problem = unsafe_load(p)
    s = convert(Ptr{KnapsackSolution}, s_void)
    solution = unsafe_load(s)
    m = nsseq_bitflip_iterator_init(problem, solution)
    m_raw_ptr = OptFrame.global_register(m)
    return Ptr{Nothing}(m_raw_ptr)
end


function nsseq_bitflip_iterator_first(problem::KnapsackProblem, iterator::MoveBitFlip)
    iterator.k = Int32(1)
end

function nsseq_bitflip_iterator_first_c(p_void::Ptr{Nothing}, it_void::Ptr{Nothing})::Cint
    p = convert(Ptr{KnapsackProblem}, p_void)
    problem = unsafe_load(p)
    x = Int32(0)
    it = convert(Ptr{MoveBitFlip}, it_void)
    it2 = unsafe_pointer_to_objref(it)
    it2.k = 1
    #iterator = unsafe_load(it)   # COPY
    #nsseq_bitflip_iterator_first(problem, iterator)
    #unsafe_store!(it, iterator)
    return x # workaround on GC to prevent collection... this is Cvoid!
end

function nsseq_bitflip_iterator_next(problem::KnapsackProblem, iterator::MoveBitFlip)
    iterator.k += Int32(1)
end

function nsseq_bitflip_iterator_next_c(p_void::Ptr{Nothing}, it_void::Ptr{Nothing})::Cint
    p = convert(Ptr{KnapsackProblem}, p_void)
    problem = unsafe_load(p)
    it = convert(Ptr{MoveBitFlip}, it_void)
    iterator = unsafe_load(it)
    nsseq_bitflip_iterator_next(problem, iterator)
    unsafe_store!(it, iterator)
    #println("iterator after next it=", iterator)
    return iterator.k # workaround on GC to prevent collection... this is Cvoid!
end

function nsseq_bitflip_iterator_is_done(
    problem::KnapsackProblem,
    iterator::MoveBitFlip,
)::Bool
    return iterator.k > problem.nitems
end

function nsseq_bitflip_iterator_is_done_c(p_void::Ptr{Nothing}, it_void::Ptr{Nothing})::Cint
    p = convert(Ptr{KnapsackProblem}, p_void)
    problem = unsafe_load(p)
    it = convert(Ptr{MoveBitFlip}, it_void)
    iterator = unsafe_load(it)
    b = nsseq_bitflip_iterator_is_done(problem, iterator)
    if b
        return Int32(1)
    else
        return Int32(0)
    end
end

function nsseq_bitflip_iterator_current(
    problem::KnapsackProblem,
    iterator::MoveBitFlip,
)::MoveBitFlip
    return deepcopy(iterator)
end

function nsseq_bitflip_iterator_current_c(
    p_void::Ptr{Nothing},
    it_void::Ptr{Nothing},
)::Ptr{Nothing}
    p = convert(Ptr{KnapsackProblem}, p_void)
    problem = unsafe_load(p)
    it = convert(Ptr{MoveBitFlip}, it_void)
    iterator = unsafe_load(it)
    m = nsseq_bitflip_iterator_current(problem, iterator)
    m_raw_ptr = OptFrame.global_register(m)
    return Ptr{Nothing}(m_raw_ptr)
end

end # module OptFrameKnapsack
