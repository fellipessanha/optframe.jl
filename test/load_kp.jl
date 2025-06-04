function load_kp()
    weights  = [12.0, 7.0, 11.0, 8.0, 9.0]
    profits  = [6.0, 3.5, 5.5, 4.0, 4.5]
    capacity = 26.0

    n = length(weights)

    problem = KP.knapsack_problem_init(weights, profits, n, capacity)

    @info("Finished!")
    @info(problem.nitems)

    @info(problem)
    #problem_ptr = Ref(problem)
    problem_ptr = Ptr{KP.KnapsackProblem}(pointer_from_objref(problem))


    @info("invoking random_initial_solution")

    sol = KP.random_initial_solution(problem)

    @info(sol)

    @info("invoking callback_sol_deepcopy_utils")

    sol2 = KP.callback_sol_deepcopy_kp(sol)

    @show(sol2)

    @info("testing evaluator")

    e = KP.evaluate_solution(problem, sol)

    @info("evaluation: $e")

    @info("OK")

    @info("will try add_evaluator")


    idx_ev   = OptFrame.@add_evaluator(problem, KP.evaluate_solution::Cdouble)

    @info("created component OptFrame:GeneralEvaluator:Evaluator $idx_ev")

    @info("will try add_constructive")

    idx_c = OptFrame.@add_constructive(
        problem,
        KP.random_initial_solution::KP.KnapsackSolution,
        KP.callback_sol_deepcopy_kp,
    )

    @info("created component OptFrame:Constructive $idx_c")

    @info("loading initial search")

    initial_search_index = OptFrame.create_initial_search(problem.engine, idx_ev, idx_c)

    @info("created component OptFrame:InitialSearch $initial_search_index")

    @info("testing add_ns")

    m = KP.ns_rand_bitflip(problem, sol)

    @info(m)

    @info("will try apply move = $m")

    if KP.move_cba_bitflip(problem, m, sol)
        @info("can be applied!")
        @show(sol)
        m2 = KP.move_apply_bitflip(problem, m, sol)
        @show(sol)
        @show(m)
        @show(m2)
    else
        @warn("cannot be applied!")
    end

    @info("trying move equality")

    if KP.move_eq_bitflip(problem, m, m2)
        @info("moves are equal!")
    else
        @warn("moves are not equal!")
    end

    @info("will try add_constructive")

    f_nsrand_ptr        = @cfunction(KP.ns_rand_bitflip, Ptr{Cvoid}, (Ptr{Cvoid}, Ptr{Cvoid}))
    f_moveapply_ptr     = @cfunction(KP.move_apply_bitflip, Ptr{Cvoid}, (Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}))
    f_moveeq_ptr        = @cfunction(KP.move_eq_bitflip, Cint, (Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}))
    f_movecba_ptr       = @cfunction(KP.move_cba_bitflip, Cint, (Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}))
    decref_callback_ptr = @cfunction(KP.free_solution_kp, Cint, (Ptr{Cvoid},))

    idx_ns = OptFrame.add_ns(
        problem.engine,
        f_nsrand_ptr,
        f_moveapply_ptr,
        f_moveeq_ptr,
        f_movecba_ptr,
        Ptr{Nothing}(problem_ptr),
        decref_callback_ptr,
    )

    @info("created component OptFrame:NS:FNS $idx_ns")

    @info("creating nsseq (neighbor search sequence)")

    iterator_init_ptr    = @cfunction(KP.nsseq_bitflip_iterator_init_c, Ptr{Cvoid}, (Ptr{Cvoid}, Ptr{Cvoid}))
    iterator_first_ptr   = @cfunction(KP.nsseq_bitflip_iterator_first_c, Cint, (Ptr{Cvoid}, Ptr{Cvoid}))
    iterator_next_ptr    = @cfunction(KP.nsseq_bitflip_iterator_next_c, Cint, (Ptr{Cvoid}, Ptr{Cvoid}))
    iterator_is_done_ptr = @cfunction(KP.nsseq_bitflip_iterator_is_done_c, Cint, (Ptr{Cvoid}, Ptr{Cvoid}))
    iterator_current_ptr = @cfunction(KP.nsseq_bitflip_iterator_current_c, Ptr{Cvoid}, (Ptr{Cvoid}, Ptr{Cvoid}))

    nsseq_idx = OptFrame.add_nsseq(
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
        Ptr{Nothing}(problem_ptr),
        decref_callback_ptr,
    )

    @info("added nsseq with idx = $nsseq_idx")


    @info("loading initial search")

    initial_search_index = OptFrame.create_initial_search(problem.engine, idx_ev, idx_c)

    @info("created initial search with index $initial_search_index")

    # # Verbosity filter 4 is disabled. Filter -1 is debug.
    b = OptFrame.experimental_set_parameter(problem.engine, "ENGINE_LOG_LEVEL", "4")

    @show(b)

    component_list_index =
        OptFrame.create_component_list(problem.engine, "[OptFrame:NS 0]", "OptFrame:NS[]")

    @info(component_list_index)

    # list loaded engine components
    OptFrame.list_engine_components(problem.engine)

    @info("""
          engine will list builders
              skipping...

          engine will list builders for :BasicSA
          $(OptFrame.list_builders(problem.engine, ":BasicSA"))
          """)

    @info("testing builder (build_global_search) for SA...")

    gs_idx = OptFrame.build_global_search(
        problem.engine,
        "OptFrame:ComponentBuilder:GlobalSearch:SA:BasicSA",
        "OptFrame:GeneralEvaluator:Evaluator 0 OptFrame:InitialSearch 0  OptFrame:NS[] 0 0.99 100 999",
    )

    @show(gs_idx)

    lout = OptFrame.run_global_search(problem.engine, gs_idx, 4.0)

    @show(lout)

    @info("testing iterator for nsseq")

    it = KP.nsseq_bitflip_iterator_init(problem, sol)

    KP.nsseq_bitflip_iterator_first(problem, it)

    while KP.nsseq_bitflip_iterator_is_done(problem, it) != 0
        mvv = KP.nsseq_bitflip_iterator_current(problem, it)

        @info("move mvv = $mvv")

        KP.nsseq_bitflip_iterator_next(problem, it)
    end

    @info("finished nsseq")

    ls_idx = OptFrame.build_local_search(
        problem.engine,
        "OptFrame:ComponentBuilder:LocalSearch:FI",
        "OptFrame:GeneralEvaluator:Evaluator 0  OptFrame:NS:NSFind:NSSeq 0",
    )

    @show(ls_idx)

    pert_idx = OptFrame.build_component(
        problem.engine,
        "OptFrame:ComponentBuilder:ILS:LevelPert:LPlus2",
        "OptFrame:GeneralEvaluator:Evaluator 0  OptFrame:NS 0",
        "OptFrame:ILS:LevelPert",
    )

    @show(pert_idx)

    OptFrame.list_engine_components(problem.engine, "OptFrame:")

    # # Verbosity filter 4 is disabled. Filter -1 is debug.
    b2 = OptFrame.experimental_set_parameter(problem.engine, "COMPONENT_LOG_LEVEL", "4")

    @show(b2)

    sos_idx = OptFrame.build_single_obj_search(
        problem.engine,
        "OptFrame:ComponentBuilder:SingleObjSearch:ILS:ILSLevels",
        "OptFrame:GeneralEvaluator:Evaluator 0 OptFrame:InitialSearch 0  OptFrame:LocalSearch 0 OptFrame:ILS:LevelPert 0  50  3",
    )

    @show(sos_idx)

    @info("testing execution of SingleObjSearch (run_sos_search) for ILS...")

    lout = OptFrame.run_single_obj_search(problem.engine, sos_idx, 4.5)

    @info("ILS output: $lout")

    lout_sol_ptr = convert(Ptr{KP.KnapsackSolution}, lout.best_s)
    lout_sol     = unsafe_load(lout_sol_ptr)

    @info(lout_sol)
    @info(problem)

    @info("try check")

    @test OptFrame.check(problem.engine, -1, -1, true)

    @info("Finished!")

    return nothing
end
