module OptFrame

using Libdl
export Engine, init_engine, welcome

mutable struct Engine
    gc_arena::IdDict{Ptr{Cvoid},Any}
    ll_int::Int
    hf::Ptr{Cvoid}
end

const libpath = "./optframe_lib.so"

const optframe_ptr = Libdl.dlopen(libpath)

function get_function_symbol(module_pointer::Ptr{Nothing}, function_name::String)
    return Libdl.dlsym(module_pointer, function_name)
end

function create_engine_by_symbol(n::Int32)
    creation_symbol = get_function_symbol(optframe_ptr, "optframe_api1d_create_engine")
    return @ccall $creation_symbol(n::Cint)::Ptr{Cvoid}
end

function optframe_api1d_create_engine(n::Int32)
    return @ccall libpath.optframe_api1d_create_engine(n::Cint)::Ptr{Cvoid}
end

function optframe_api0d_engine_welcome(eng::Ptr{Cvoid})
    return @ccall libpath.optframe_api0d_engine_welcome(eng::Ptr{Cvoid})::Cvoid
end

function init_engine(ll_int::Int64)::Engine
    return init_engine(Int32(ll_int))
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
