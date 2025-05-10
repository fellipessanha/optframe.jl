module OptFrame

using Libdl
export Engine, init_engine, welcome, arena_count, register, unregister, global_arena_count, global_register, global_unregister
export add_constructive, add_evaluator, check

# global arena, instead of local Engine one
const _global_gc_arena = IdDict{Ptr{Cvoid}, Any}()

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

function optframe_api0d_engine_welcome(eng::Ptr{Cvoid})
    creation_symbol = get_function_symbol(optframe_ptr, "optframe_api0d_engine_welcome")
    return @ccall $creation_symbol(eng::Ptr{Cvoid})::Cvoid
end

function init_engine(ll_int::Int64)::Engine
    return init_engine(Int32(ll_int))
end

function init_engine(ll_int::Int32)::Engine
    e = Engine(IdDict{Ptr{Cvoid},Any}(), ll_int, create_engine_by_symbol(ll_int))
    optframe_api0d_engine_welcome(e.hf)
    return e
end

# ==================================


function arena_count(e::Engine)
    return length(e.gc_arena)
end

function register(e::Engine, obj::T)::Ptr{T} where T
    ptr = Ptr{Cvoid}(pointer_from_objref(obj))
    e.gc_arena[ptr] = obj               
    return Ptr{T}(ptr)          
end

function unregister(e::Engine, ptr::Ptr{T}) where T
    key = Ptr{Cvoid}(ptr)
    if haskey(e.gc_arena, key)
        delete!(e.gc_arena, key)
    else
        @warn "Ptr not found in gc_arena!"
    end
    return nothing
end

function global_arena_count()
    return length(_global_gc_arena)
end

function global_register(obj::T)::Ptr{T} where T
    ptr = Ptr{Cvoid}(pointer_from_objref(obj))
    _global_gc_arena[ptr] = obj               
    return Ptr{T}(ptr)          
end

function global_unregister(ptr::Ptr{T}) where T
    key = Ptr{Cvoid}(ptr)
    if haskey(_global_gc_arena, key)
        delete!(_global_gc_arena, key)
    else
        @warn "Ptr not found in gc_arena!"
    end
    return nothing
end


# =================================

function optframe_api1d_add_constructive(e_ptr::Ptr{Cvoid}, constructive_callback_ptr, problemCtx::Ptr, deepcopy_callback_ptr, to_string_callback_ptr, decref_callback_ptr)
    creation_symbol = get_function_symbol(optframe_ptr, "optframe_api1d_add_constructive")
    return  @ccall $creation_symbol(
        e_ptr::Ptr{Cvoid}, 
        constructive_callback_ptr::Ptr{Cvoid},
        problemCtx::Ptr{Cvoid},
        deepcopy_callback_ptr::Ptr{Cvoid},
        to_string_callback_ptr::Ptr{Cvoid},
        decref_callback_ptr::Ptr{Cvoid}
        )::Cint
end

function add_constructive(e::Engine, constructive_callback_ptr, problemCtx::Ptr, deepcopy_callback_ptr, to_string_callback_ptr, decref_callback_ptr)
    # constructive_callback_ptr = FUNC_FCONSTRUCTIVE(constructive_callback_julia)
    # const constructive_callback_ptr = @cfunction(constructive_callback_julia, Ptr{Cvoid}, (Ptr{Cvoid},))

    # pendura pointer!!!
    # self.register_callback(constructive_callback_ptr)
    #
    idx_c = optframe_api1d_add_constructive(e.hf, 
    constructive_callback_ptr, problemCtx, deepcopy_callback_ptr, 
    to_string_callback_ptr, decref_callback_ptr)

    return idx_c #IdConstructive(idx_c)
end

function optframe_api1d_add_evaluator(e_ptr::Ptr{Cvoid}, ev_callback_ptr, min_or_max::Cint, problemCtx::Ptr)
    creation_symbol = get_function_symbol(optframe_ptr, "optframe_api1d_add_evaluator")
    return  @ccall $creation_symbol(
        e_ptr::Ptr{Cvoid}, 
        ev_callback_ptr::Ptr{Cvoid},
        min_or_max::Cint,
        problemCtx::Ptr{Cvoid},
        )::Cint
end

function add_evaluator(e::Engine, ev_callback_ptr, min_or_max::Bool, problemCtx::Ptr)
    # constructive_callback_ptr = FUNC_FCONSTRUCTIVE(constructive_callback_julia)
    # const constructive_callback_ptr = @cfunction(constructive_callback_julia, Ptr{Cvoid}, (Ptr{Cvoid},))

    # pendura pointer!!!
    # self.register_callback(constructive_callback_ptr)
    #
    idx_ev = optframe_api1d_add_evaluator(e.hf, 
    ev_callback_ptr, Int32(min_or_max), problemCtx)

    return idx_ev
end

function onfail(code::Cint)::Cint
    println("Error code=",code)
    return false 
end

default_onfail_ptr = @cfunction(onfail, Cint, (Cint,))

function optframe_api1d_engine_check(e_ptr::Ptr{Cvoid}, p1::Cint, p2::Cint, verbose::Cint, onfail_callback_ptr)
    creation_symbol = get_function_symbol(optframe_ptr, "optframe_api1d_engine_check")
    return  @ccall $creation_symbol(
        e_ptr::Ptr{Cvoid}, 
        p1::Cint,
        p2::Cint,
        verbose::Cint,
        onfail_callback_ptr::Ptr{Cvoid},
        )::Cint
end

function check(e::Engine, p1::Int64, p2::Int64, verbose::Bool)::Bool
    # constructive_callback_ptr = FUNC_FCONSTRUCTIVE(constructive_callback_julia)
    # const constructive_callback_ptr = @cfunction(constructive_callback_julia, Ptr{Cvoid}, (Ptr{Cvoid},))

    # pendura pointer!!!
    # self.register_callback(constructive_callback_ptr)
    #
    res = optframe_api1d_engine_check(e.hf, Int32(p1), Int32(p2), Int32(verbose), default_onfail_ptr)
    return res
end


# =================================

function welcome(e::Engine)
    optframe_api0d_engine_welcome(e.hf)
end

end # module Optframe
