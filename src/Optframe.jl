module OptFrame

export Engine, init_engine, welcome

mutable struct Engine
        gc_arena::IdDict{Ptr{Cvoid},Any}
        ll_int::Int
        hf::Ptr{Cvoid}
end

# =========================

const libpath = "./optframe_lib.so"

function optframe_api1d_create_engine(n::Int32)
        @ccall libpath.optframe_api1d_create_engine(n::Cint)::Ptr{Cvoid}
end

function optframe_api0d_engine_welcome(eng::Ptr{Cvoid})
        @ccall libpath.optframe_api0d_engine_welcome(eng::Ptr{Cvoid})::Cvoid
end

function init_engine(ll_int::Int64)::Engine
        init_engine(Int32(ll_int))
end

function init_engine(ll_int::Int32)::Engine
        e = Engine(IdDict{Ptr{Cvoid},Any}(), ll_int, optframe_api1d_create_engine(ll_int))
        optframe_api0d_engine_welcome(e.hf)
        return e
end

function welcome(e::Engine)
        optframe_api0d_engine_welcome(e.hf)
end

end # module Optframe
