using Base: unsafe_load_commands

function load_tsp(; path::AbstractString = joinpath(@__DIR__, "data", "berlin52.txt"))
    x_coordinates, y_coordinates = TSP.parse_trp_file(path)

    @test length(x_coordinates) == length(y_coordinates)

    cities = collect(1:length(x_coordinates))

    problem = TSP.initialize_tsp_problem(cities, x_coordinates, y_coordinates)

    b2 = OptFrame.experimental_set_parameter(problem.engine, "COMPONENT_LOG_LEVEL", "-1")

    @show b2

    # Verbosity filter 4 is disabled. Filter -1 is debug.

    #println(problem)

    problem_ptr  = Ptr{TSP.TSPProblem}(pointer_from_objref(problem))
    problem_void = Ptr{Cvoid}(problem_ptr)

    @info("initializing random solution")

    solution     = TSP.generate_random_initial_solution(problem)
    solution_ptr = TSP.generate_random_initial_solution(problem_ptr)

    @info("""
          solutions generated
          from object: $solution
          from pointer: $(unsafe_load(solution_ptr))
          """)

    solution_copy = TSP.callback_deep_copy(solution)

    @info("deep copying solution. got: $solution_copy")

    @info("evaluating solution...")

    evaluation = TSP.evaluate_solution(problem, solution)

    @info("evaluation from object: $evaluation")

    evaluator_pointer = @cfunction(TSP.evaluate_solution, Cdouble, (Ptr{Cvoid}, Ptr{Cvoid}))
    evaluator_index   = OptFrame.add_evaluator(problem.engine, evaluator_pointer, false, problem_void)

    @info("added evaluator with index $evaluator_index")

    initial_solution_pointer  = @cfunction(TSP.generate_random_initial_solution, Ptr{Cvoid}, (Ptr{Cvoid},))
    deepcopy_callback_pointer = @cfunction(TSP.callback_deep_copy, Ptr{Cvoid}, (Ptr{Cvoid},))
    tostring_callback_pointer = @cfunction(TSP.callback_tostring_tsp, Csize_t, (Ptr{Cvoid}, Ptr{Cchar}, Csize_t))
    free_tsp_solution_pointer = @cfunction(TSP.free_tsp_solution, Cint, (Ptr{Cvoid},))

    constructive_index = OptFrame.add_constructive(
        problem.engine,
        initial_solution_pointer,
        problem_void,
        deepcopy_callback_pointer,
        tostring_callback_pointer,
        free_tsp_solution_pointer,
    )

    @info("created component OptFrame:Constructive $constructive_index")

    initial_search_index =
        OptFrame.create_initial_search(problem.engine, evaluator_index, constructive_index)

    @info("created component OptFrame:InitialSearch $initial_search_index")

    swap_move = TSP.generate_random_move_swap(problem, solution)

    @info("""
          generated swap move: $swap_move
          pre-swap solution: $solution
          post-swap solution: $solution
          """)

    random_move_pointer         = @cfunction(TSP.generate_random_move_swap, Ptr{Cvoid}, (Ptr{Cvoid}, Ptr{Cvoid}))
    apply_move_pointer          = @cfunction(TSP.apply_move_swap, Ptr{Cvoid}, (Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}))
    equals_move_pointer         = @cfunction(TSP.move_is_equal_swap, Cint, (Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}))
    can_be_applied_move_pointer = @cfunction(TSP.move_can_be_applied_swap, Cint, (Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}))

    idx_ns = OptFrame.add_ns(
        problem.engine,
        random_move_pointer,
        apply_move_pointer,
        equals_move_pointer,
        can_be_applied_move_pointer,
        problem_void,
        free_tsp_solution_pointer,
    )

    @info("created component OptFrame:NS:FNS $idx_ns")

    iterator_init_ptr    = @cfunction(TSP.nsseq_swap_iterator_init, Ptr{Cvoid}, (Ptr{Cvoid}, Ptr{Cvoid}))
    iterator_first_ptr   = @cfunction(TSP.nsseq_swap_iterator_first, Cint, (Ptr{Cvoid}, Ptr{Cvoid}))
    iterator_next_ptr    = @cfunction(TSP.nsseq_swap_iterator_next, Cint, (Ptr{Cvoid}, Ptr{Cvoid}))
    iterator_is_done_ptr = @cfunction(TSP.nsseq_swap_iterator_is_done, Cint, (Ptr{Cvoid}, Ptr{Cvoid}))
    iterator_current_ptr = @cfunction(TSP.nsseq_swap_iterator_current, Ptr{Cvoid}, (Ptr{Cvoid}, Ptr{Cvoid}))

    nsseq_idx = OptFrame.add_nsseq(
        problem.engine,
        initial_solution_pointer,
        iterator_init_ptr,
        iterator_first_ptr,
        iterator_next_ptr,
        iterator_is_done_ptr,
        iterator_current_ptr,
        apply_move_pointer,
        equals_move_pointer,
        can_be_applied_move_pointer,
        problem_void,
        free_tsp_solution_pointer,
    )

    @info("added nsseq with idx = $nsseq_idx")

    @info("try check (with disabled prints)")

    @test OptFrame.check(problem.engine, 300, 5, false)

    return nothing
end
