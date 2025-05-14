function load_optframe()
    engine = OptFrame.init_engine(0)::OptFrame.Engine

    @info("testing welcome...")

    engine |> OptFrame.welcome

    @test true # TODO: Exchange for something more meaningful

    return nothing
end