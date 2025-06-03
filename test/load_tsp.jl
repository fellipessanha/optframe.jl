import OptFrameTSP as TSP

function load_tsp(; path::AbstractString = joinpath(@__DIR__, "data", "berlin52.txt"))
    x_coordinates, y_coordinates = TSP.parse_trp_file(path)

    @test length(x_coordinates) == length(y_coordinates)

    cities = collect(1:length(x_coordinates))

    problem = TSP.initialize_tsp_problem(cities, x_coordinates, y_coordinates)

    OptFrame.list_builders(problem.engine, "OptFrame:SingleObjSearch")

    b2 = OptFrame.experimental_set_parameter(problem.engine, "COMPONENT_LOG_LEVEL", "4")

    @show b2

    # Verbosity filter 4 is disabled. Filter -1 is debug.

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

    evaluator = OptFrame.@add_evaluator(problem, TSP.evaluate_solution::Cdouble)
    evaluator_index = evaluator.index

    @info("added evaluator $evaluator")

    initial_solution_pointer  = @cfunction(TSP.generate_random_initial_solution, Ptr{Cvoid}, (Ptr{Cvoid},))
    deepcopy_callback_pointer = @cfunction(TSP.callback_deep_copy, Ptr{Cvoid}, (Ptr{Cvoid},))
    tostring_callback_pointer = @cfunction(TSP.callback_tostring_tsp, Csize_t, (Ptr{Cvoid}, Ptr{Cchar}, Csize_t))
    free_tsp_solution_pointer = @cfunction(TSP.free_tsp_solution, Cint, (Ptr{Cvoid},))

    constructive = OptFrame.@add_constructive(
        problem,
        TSP.generate_random_initial_solution,
        TSP.callback_deep_copy,
        TSP.free_tsp_solution
    )
    constructive_index = constructive.index

    @info("created component $constructive")

    initial_search = OptFrame.create_initial_search(problem.engine, evaluator, constructive)
    initial_search_index = initial_search.index

    @info("created component $initial_search")

    swap_move = TSP.generate_random_move_swap(problem, solution)
    swap_move = TSP.generate_random_move_2opt(problem, solution)

    @info("""
          generated swap move: $swap_move
          generated 2opt move: $swap_move
          """)

    random_move_pointer_swap         = @cfunction(TSP.generate_random_move_swap, Ptr{Cvoid}, (Ptr{Cvoid}, Ptr{Cvoid}))
    apply_move_pointer_swap          = @cfunction(TSP.apply_move_swap, Ptr{Cvoid}, (Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}))
    equals_move_pointer_swap         = @cfunction(TSP.move_is_equal_swap, Cint, (Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}))
    can_be_applied_move_pointer_swap = @cfunction(TSP.move_can_be_applied_swap, Cint, (Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}))

    ns_swap = OptFrame.add_ns(
        problem.engine,
        random_move_pointer_swap,
        apply_move_pointer_swap,
        equals_move_pointer_swap,
        can_be_applied_move_pointer_swap,
        problem_void,
        free_tsp_solution_pointer,
    )
    idx_ns_swap = ns_swap.index

    random_move_pointer_2opt         = @cfunction(TSP.generate_random_move_2opt, Ptr{Cvoid}, (Ptr{Cvoid}, Ptr{Cvoid}))
    apply_move_pointer_2opt          = @cfunction(TSP.apply_move_2opt, Ptr{Cvoid}, (Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}))
    equals_move_pointer_2opt         = @cfunction(TSP.move_is_equal_2opt, Cint, (Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}))
    can_be_applied_move_pointer_2opt = @cfunction(TSP.move_can_be_applied_2opt, Cint, (Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}))

    ns_2opt = OptFrame.add_ns(
        problem.engine,
        random_move_pointer_2opt,
        apply_move_pointer_2opt,
        equals_move_pointer_2opt,
        can_be_applied_move_pointer_2opt,
        problem_void,
        free_tsp_solution_pointer,
    )
    idx_ns_2opt = ns_2opt.index

    @info("created component $ns_swap")
    @info("created component $ns_2opt")

    iterator_init_ptr_swap    = @cfunction(TSP.nsseq_swap_iterator_init, Ptr{Cvoid}, (Ptr{Cvoid}, Ptr{Cvoid}))
    iterator_first_ptr_swap   = @cfunction(TSP.nsseq_swap_iterator_first, Cint, (Ptr{Cvoid}, Ptr{Cvoid}))
    iterator_next_ptr_swap    = @cfunction(TSP.nsseq_swap_iterator_next, Cint, (Ptr{Cvoid}, Ptr{Cvoid}))
    iterator_is_done_ptr_swap = @cfunction(TSP.nsseq_swap_iterator_is_done, Cint, (Ptr{Cvoid}, Ptr{Cvoid}))
    iterator_current_ptr_swap = @cfunction(TSP.nsseq_swap_iterator_current, Ptr{Cvoid}, (Ptr{Cvoid}, Ptr{Cvoid}))

    nsseq_idx_swap = OptFrame.add_nsseq(
        problem.engine,
        random_move_pointer_swap,
        iterator_init_ptr_swap,
        iterator_first_ptr_swap,
        iterator_next_ptr_swap,
        iterator_is_done_ptr_swap,
        iterator_current_ptr_swap,
        apply_move_pointer_swap,
        equals_move_pointer_swap,
        can_be_applied_move_pointer_swap,
        problem_void,
        free_tsp_solution_pointer,
    )
    @info("added nsseq with idx = $nsseq_idx_swap")

    iterator_init_ptr_2opt    = @cfunction(TSP.nsseq_2opt_iterator_init, Ptr{Cvoid}, (Ptr{Cvoid}, Ptr{Cvoid}))
    iterator_first_ptr_2opt   = @cfunction(TSP.nsseq_2opt_iterator_first, Cint, (Ptr{Cvoid}, Ptr{Cvoid}))
    iterator_next_ptr_2opt    = @cfunction(TSP.nsseq_2opt_iterator_next, Cint, (Ptr{Cvoid}, Ptr{Cvoid}))
    iterator_is_done_ptr_2opt = @cfunction(TSP.nsseq_2opt_iterator_is_done, Cint, (Ptr{Cvoid}, Ptr{Cvoid}))
    iterator_current_ptr_2opt = @cfunction(TSP.nsseq_2opt_iterator_current, Ptr{Cvoid}, (Ptr{Cvoid}, Ptr{Cvoid}))

    nsseq_idx_2opt = OptFrame.add_nsseq(
        problem.engine,
        random_move_pointer_2opt,
        iterator_init_ptr_2opt,
        iterator_first_ptr_2opt,
        iterator_next_ptr_2opt,
        iterator_is_done_ptr_2opt,
        iterator_current_ptr_2opt,
        apply_move_pointer_2opt,
        equals_move_pointer_2opt,
        can_be_applied_move_pointer_2opt,
        problem_void,
        free_tsp_solution_pointer,
    )
    @info("added nsseq with idx = $nsseq_idx_2opt")

    component_list_swap = OptFrame.create_component_list(
        problem.engine,
        "[ OptFrame:NS $idx_ns_swap ]",
        "OptFrame:NS[]",
    )
    component_list_2opt = OptFrame.create_component_list(
        problem.engine,
        "[ OptFrame:NS $idx_ns_2opt ]",
        "OptFrame:NS[]",
    )

    ns_component_list = OptFrame.create_component_list(
        problem.engine,
        "[ OptFrame:NS $idx_ns_swap OptFrame:NS $idx_ns_2opt]",
        "OptFrame:NS[]",
    )


    @info("created ns component lists $component_list_swap and $component_list_2opt")
    @info("created ns component list $ns_component_list")

    simulated_annealing_constructor, simulated_annealing_string =
        TSP.get_simulated_annealing_builder_strings(
            evaluator_index,
            initial_search_index,
            ns_component_list,
        )

    simulated_annealing_idx = TSP.build_global_search_simulated_annealing(
        problem.engine,
        simulated_annealing_string,
    )
    @info("$simulated_annealing_string generated $simulated_annealing_idx")

    local_search_swap =
        TSP.build_local_search(problem.engine, evaluator_index, idx_ns_swap, false)
    local_search_2opt =
        TSP.build_local_search(problem.engine, evaluator_index, idx_ns_2opt, false)

    local_search_list = OptFrame.create_component_list(
        problem.engine,
        "[ OptFrame:LocalSearch $local_search_2opt OptFrame:LocalSearch $local_search_swap ]",
        "OptFrame:LocalSearch[]",
    )

    @info("created component OptFrame:LocalSearch[] $local_search_list")

    vnd_idx = TSP.build_vnd_local_search(problem.engine, evaluator_index, local_search_list)
    @info("created component OptFrame:LocalSearch:VND $vnd_idx")

    ils_perturbation_idx =
        TSP.build_ils_basic_perturbation(problem.engine, evaluator_index, idx_ns_swap)
    @info("created component OptFrame:ILS:basic_pert $ils_perturbation_idx")


    n = problem.number_of_cities * 100
    pert = Integer(floor(problem.number_of_cities / 5.0))
    @info("number of cities: $n")
    ils_constructor, ils_builder_string = TSP.get_ils_builder_string(
        evaluator_index,
        initial_search_index,
        vnd_idx,
        ils_perturbation_idx,
        n,
        pert
    )

    exps = OptFrame.run_experiments(
        problem.engine,
        1,
        "$simulated_annealing_constructor $simulated_annealing_string\n" *
        "$ils_constructor $ils_builder_string",
        0,
        "",
        problem.number_of_cities / 5.0,
        4,
    )


    # ils_idx = build_ils_single_obj_search(problem.engine, ils_builder_string)
    #
    # @info("created component OptFrame:ILS $ils_idx")
    #
    # lout = OptFrame.run_single_obj_search(problem.engine, ils_idx, 4.5)
    #
    # best_solution = TSP.load_void_into_obj(lout.best_s, TSP.TSPSolution)
    # @info("ILS with VND finished! results: $(lout.best_e)")
    # @show best_solution
    #
    # @info("try check (with disabled prints)")
    #
    # @test OptFrame.check(problem.engine, 100, 5, false)
    #
    return nothing
end
