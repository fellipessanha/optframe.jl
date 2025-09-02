module OptFrameTSP

import OptFrame
import Random: randperm

include("Utils.jl")
include("Types.jl")
include("Move2Opt.jl")
include("MoveSwap.jl")

function initialize_tsp_problem(
    cities::Vector{Cint},
    x_coordinates::Vector{T},
    y_coordinates::Vector{T},
    log_level::Cint,
)::TSPProblem where {T}
    n_cities  = Cint(length(cities))
    distances = Vector{T}[]

    for i = 1:n_cities
        row = [
            euclidean_distance(
                x_coordinates[i],
                y_coordinates[i],
                x_coordinates[j],
                y_coordinates[j],
            ) for j = 1:n_cities
        ]

        push!(distances, row)
    end

    return TSPProblem(
        OptFrame.Engine(log_level),
        n_cities,
        x_coordinates,
        y_coordinates,
        distances,
    )
end

function initialize_tsp_problem(
    cities::Vector{U},
    x_coordinates::Vector{T},
    y_coordinates::Vector{T},
)::TSPProblem where {T,U<:Integer}
    cint_cities = Cint.(cities)
    return initialize_tsp_problem(cint_cities, x_coordinates, y_coordinates, Cint(4))
end

function generate_random_initial_solution(problem::TSPProblem)::TSPSolution
    initial_solution = randperm(problem.number_of_cities)
    return TSPSolution(problem.number_of_cities, initial_solution)
end

function generate_random_initial_solution(problem_ptr::Ptr{TSPProblem})::Ptr{TSPSolution}
    problem = unsafe_load(problem_ptr)
    solution = generate_random_initial_solution(problem)
    return OptFrame.global_register(solution)
end

function generate_random_initial_solution(problem_void::Ptr{Cvoid})::Ptr{Nothing}
    problem_ptr = convert(Ptr{TSPProblem}, problem_void)
    solution = generate_random_initial_solution(problem_ptr)
    return Ptr{Nothing}(solution)
end

function callback_deep_copy(solution::TSPSolution)::TSPSolution
    return deepcopy(solution)
end

function callback_deep_copy(solution_void::Ptr{Cvoid})::Ptr{Cvoid}
    solution = load_void_into_obj(solution_void, TSPSolution)
    copy_solution = callback_deep_copy(solution)
    copy_pointer = OptFrame.global_register(copy_solution)
    return Ptr{Cvoid}(copy_pointer)
end

function evaluate_solution(problem::TSPProblem, solution::TSPSolution)::Float64
    evaluation = 0.0
    for i = 1:solution.path_size
        city1, city2 =
            solution.cities_path[i], solution.cities_path[(i+1)%solution.path_size+1]
        evaluation += problem.distances[city1][city2]
    end
    return evaluation
end

function evaluate_solution(
    problem_ptr::Ptr{TSPProblem},
    solution_ptr::Ptr{TSPSolution},
)::Float64
    problem = unsafe_load(problem_ptr)
    solution = unsafe_load(solution_ptr)
    return evaluate_solution(problem, solution)
end


function evaluate_solution(problem_ptr::Ptr{Cvoid}, solution_ptr::Ptr{Cvoid})::Float64
    problem = load_void_into_obj(problem_ptr, TSPProblem)
    solution = load_void_into_obj(solution_ptr, TSPSolution)
    return evaluate_solution(problem, solution)
end

function callback_tostring_tsp(_::Ptr{Cvoid}, buffer::Ptr{Cchar}, size::Csize_t)::Csize_t
    s = "solution as string"
    n = min(sizeof(s), size - 1)
    unsafe_copyto!(buffer, pointer(s), n)
    unsafe_store!(buffer + n, 0)
    return sizeof(s)
end

function free_tsp_solution(s_ptr_void::Ptr{Nothing})::Int32
    s_ptr = convert(Ptr{TSPSolution}, s_ptr_void)
    OptFrame.global_unregister(s_ptr)
    return 0
end

function get_simulated_annealing_builder_strings(
    id_evaluator::Integer,
    id_initial_search::Integer,
    id_ns::Integer,
)
    return "OptFrame:ComponentBuilder:GlobalSearch:SA:BasicSA",
    "OptFrame:GeneralEvaluator:Evaluator $id_evaluator OptFrame:InitialSearch $id_initial_search OptFrame:NS $id_ns 0.995 1000 10000"
end

function get_simulated_annealing_builder_strings(
    evaluator::OptFrame.optcomponent"GeneralEvaluator:Evaluator",
    initial_search::OptFrame.optcomponent"InitialSearch",
    ns::OptFrame.optcomponent"NS[]",
)
    return "OptFrame:ComponentBuilder:GlobalSearch:SA:BasicSA",
    "$evaluator $initial_search $ns 0.995 1000 10000"
end

function build_global_search_simulated_annealing(
    engine::OptFrame.Engine,
    id_evaluator::Integer,
    id_initial_search::Integer,
    id_ns::Integer,
)::Integer
    constructor, build_string =
        get_simulated_annealing_builder_strings(id_evaluator, id_initial_search, id_ns)
    return OptFrame.build_global_search(engine, constructor, build_string)
end

function build_global_search_simulated_annealing(
    engine::OptFrame.Engine,
    build_string::String,
)
    constructor, _ = get_simulated_annealing_builder_strings(1, 1, 1)
    return OptFrame.build_global_search(engine, constructor, build_string)
end

function build_local_search(
    engine::OptFrame.Engine,
    id_evaluator::Integer,
    id_nsseq::Integer,
    is_best_improvement::Bool,
)::OptFrame.Component
    improvement_strategy = is_best_improvement ? "BI" : "FI"
    return OptFrame.build_local_search(
        engine,
        "OptFrame:ComponentBuilder:LocalSearch:$improvement_strategy",
        "OptFrame:GeneralEvaluator:Evaluator $id_evaluator  OptFrame:NS:NSFind:NSSeq $id_nsseq",
    )
end


function build_vnd_local_search(
    engine::OptFrame.Engine,
    evaluator::OptFrame.optcomponent"GeneralEvaluator",
    local_search_list::OptFrame.optcomponent"LocalSearch[]",
)::OptFrame.Component
    return OptFrame.build_component(
        engine,
        "OptFrame:ComponentBuilder:LocalSearch:VND",
        "$evaluator $local_search_list",
        "OptFrame:LocalSearch",
    )
end

function build_ils_basic_perturbation(
    engine::OptFrame.Engine,
    evaluator_index::Integer,
    ns_list_index::Integer,
)::OptFrame.Component
    return OptFrame.build_component(
        engine,
        "OptFrame:ComponentBuilder:ILS:LevelPert:LPlus2",
        "OptFrame:GeneralEvaluator:Evaluator $evaluator_index  " *
        "OptFrame:NS $ns_list_index",
        "OptFrame:ILS:LevelPert",
    )
end


function build_ils_basic_perturbation(
    engine::OptFrame.Engine,
    evaluator::OptFrame.optcomponent"GeneralEvaluator",
    ns::OptFrame.optcomponent"NS",
)::OptFrame.Component
    return OptFrame.build_component(
        engine,
        "OptFrame:ComponentBuilder:ILS:LevelPert:LPlus2",
        "$evaluator $ns",
        "OptFrame:ILS:LevelPert",
    )
end


function get_ils_builder_string(
    evaluator_index::Integer,
    initial_search_index::Integer,
    local_search_index::Integer,
    ils_perturbation_index::Integer,
    max_iterations::Integer,
    max_perturbation_level::Integer,
)
    return "OptFrame:ComponentBuilder:SingleObjSearch:ILS:ILSLevels",
    "OptFrame:GeneralEvaluator:Evaluator $evaluator_index " *
    "OptFrame:InitialSearch $initial_search_index " *
    "OptFrame:LocalSearch $local_search_index " *
    "OptFrame:ILS:LevelPert $ils_perturbation_index " *
    "$max_iterations $max_perturbation_level"
end

function get_ils_builder_string(
    evaluator::OptFrame.optcomponent"GeneralEvaluator",
    initial_search::OptFrame.optcomponent"InitialSearch",
    local_search::OptFrame.Component,
    ils_perturbation::OptFrame.optcomponent"ILS:LevelPert",
    max_iterations::Integer,
    max_perturbation_level::Integer,
)
    return "OptFrame:ComponentBuilder:SingleObjSearch:ILS:ILSLevels",
    "$evaluator $initial_search $local_search $ils_perturbation " *
    "$max_iterations $max_perturbation_level"
end


function build_ils_single_obj_search(engine::OptFrame.Engine, builder::String)::Integer
    constructor, _ = get_ils_builder_string(0, 0, 0, 0, 0, 0)
    return OptFrame.build_single_obj_search(engine, constructor, builder)
end

function build_ils_single_obj_search(
    engine::OptFrame.Engine,
    evaluator::OptFrame.optcomponent"GeneralEvaluator",
    initial_search::OptFrame.optcomponent"InitialSearch",
    local_search::OptFrame.optcomponent"LocalSearch",
    ils_perturbation::OptFrame.optcomponent"ILS:LevelPert",
    max_iterations::Integer,
    max_perturbation_level::Integer,
)::Integer
    constructor, builder = get_ils_builder_string(
        evaluator,
        initial_search,
        local_search,
        ils_perturbation,
        max_iterations,
        max_perturbation_level,
    )
    return OptFrame.build_single_obj_search(engine, constructor, builder)
end

end # module TSP
