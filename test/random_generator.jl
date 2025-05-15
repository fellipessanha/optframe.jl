
function random_generator()
    @info("testing OptFrame random generator")
    engine = OptFrame.init_engine(4)

    @show UInt32(9999)
    OptFrame.set_random_seed(engine, UInt32(9999))
    
    first_rand = engine |> OptFrame.get_random

    @show first_rand
    @test first_rand % 100 == 5

    random_upper_bound  = 100
    random_with_ceiling = OptFrame.get_random(engine, random_upper_bound)

    @test 0 <= random_with_ceiling < random_upper_bound
    @info "generated random in range [0, $random_upper_bound): $random_with_ceiling"

    random_lower_bound = 10
    random_in_bounds   = OptFrame.get_random(engine, random_lower_bound, random_upper_bound)

    @test 10 <= random_in_bounds < 10000
    @info "generated random in range [$random_lower_bound, $random_upper_bound): $random_in_bounds"
end