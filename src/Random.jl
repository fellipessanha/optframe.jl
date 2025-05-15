function optframe_api1d_engine_rand(eng::Ptr{Cvoid})::Cint
    creation_symbol = get_function_symbol(optframe_ptr[], "optframe_api1d_engine_rand")
    return @ccall $creation_symbol(eng::Ptr{Cvoid})::Cint
end

function optframe_api1d_engine_rand_n(eng::Ptr{Cvoid}, ceiling::Cint)::Cint
    creation_symbol = get_function_symbol(optframe_ptr[], "optframe_api1d_engine_rand_n")
    return @ccall $creation_symbol(eng::Ptr{Cvoid}, ceiling::Cint)::Cint
end

function optframe_api1d_engine_rand_n_n(eng::Ptr{Cvoid}, floor::Cint, ceiling::Cint)::Cint
    creation_symbol = get_function_symbol(optframe_ptr[], "optframe_api1d_engine_rand_n_n")
    return @ccall $creation_symbol(eng::Ptr{Cvoid}, floor::Cint, ceiling::Cint)::Cint
end

function optframe_api1d_engine_rand_set_seed(eng::Ptr{Cvoid}, seed::Cuint)::Cvoid
    creation_symbol = get_function_symbol(optframe_ptr[], "optframe_api1d_engine_rand_set_seed")
    return @ccall $creation_symbol(eng::Ptr{Cvoid}, seed::Cuint)::Cint
end

function set_random_seed(engine::Engine, seed::UInt32)::Nothing
    optframe_api1d_engine_rand_set_seed(engine.hf, Cuint(seed))
end

function get_random(engine::Engine)::Cint
    return optframe_api1d_engine_rand(engine.hf)
end

function get_random(engine::Engine, ceiling::T)::T where T<:Integer
    return optframe_api1d_engine_rand_n(engine.hf, Cint(ceiling))
end

function get_random(engine::Engine, floor::T, ceiling::T)::T where T<:Integer
    return optframe_api1d_engine_rand_n_n(engine.hf, Cint(floor), Cint(ceiling))
end

function shuffle(engine::Engine, v::Vector{T})::Vector{T} where T
    n = length(v)
    for i = 1:n
        j = get_random(engine, i, n)
        v[i], v[j] = v[j], v[i]
    end
    return v
end

function shuffle(engine::Engine, range::UnitRange{T})::Vector{T} where T<:Integer
    return shuffle(engine, collect(range))
end




