module OptFrame

using Libdl
export Engine, init_engine, welcome, arena_count, register, unregister, global_arena_count, global_register, global_unregister
export add_constructive, add_evaluator, check
export add_ns, create_component_list
export list_builders

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
# function global_unregister(ptr::Ptr{Nothing})::Bool
    key = Ptr{Cvoid}(ptr)
    if haskey(_global_gc_arena, key)
        delete!(_global_gc_arena, key)
    else
        @warn "Ptr not found in gc_arena!"
    end
    # return nothing
    return false
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

function add_constructive(e::Engine, constructive_callback_ptr::Ptr{Nothing}, problemCtx::Ptr{Nothing}, deepcopy_callback_ptr::Ptr{Nothing}, to_string_callback_ptr::Ptr{Nothing}, decref_callback_ptr::Ptr{Nothing})
    # TODO: keep function pointers?
    idx_c = optframe_api1d_add_constructive(e.hf, 
    constructive_callback_ptr, problemCtx, deepcopy_callback_ptr, 
    to_string_callback_ptr, decref_callback_ptr)
    return idx_c
end

function optframe_api1d_add_evaluator(e_ptr::Ptr{Cvoid}, ev_callback_ptr::Ptr{Cvoid}, min_or_max::Cint, problemCtx::Ptr{Cvoid})
    creation_symbol = get_function_symbol(optframe_ptr, "optframe_api1d_add_evaluator")
    return  @ccall $creation_symbol(
        e_ptr::Ptr{Cvoid}, 
        ev_callback_ptr::Ptr{Cvoid},
        min_or_max::Cint,
        problemCtx::Ptr{Cvoid},
        )::Cint
end

function add_evaluator(e::Engine, ev_callback_ptr::Ptr{Nothing}, min_or_max::Bool, problemCtx::Ptr{Nothing})
    # TODO: keep function 'ev_callback_ptr'?
    idx_ev = optframe_api1d_add_evaluator(e.hf, 
    ev_callback_ptr, Int32(min_or_max), problemCtx)
    return idx_ev
end

function optframe_api1d_add_ns(e_ptr::Ptr{Cvoid}, fns_rand, fmove_apply, fmove_eq, fmove_cba, problemCtx::Ptr, decref_callback_ptr)
    creation_symbol = get_function_symbol(optframe_ptr, "optframe_api1d_add_ns")
    return  @ccall $creation_symbol(
        e_ptr::Ptr{Cvoid}, 
        fns_rand::Ptr{Cvoid},
        fmove_apply::Ptr{Cvoid},
        fmove_eq::Ptr{Cvoid},
        fmove_cba::Ptr{Cvoid},
        problemCtx::Ptr{Cvoid},
        decref_callback_ptr::Ptr{Cvoid}
        )::Cint
end

function add_ns(e::Engine, fns_rand::Ptr{Nothing}, 
    fmove_apply::Ptr{Nothing}, fmove_eq::Ptr{Nothing}, fmove_cba::Ptr{Nothing},
    problemCtx::Ptr{Nothing}, decref_callback_ptr::Ptr{Nothing})
    # TODO: keep function pointers?
    idx_ns = optframe_api1d_add_ns(e.hf, 
    fns_rand, fmove_apply, fmove_eq, fmove_cba,  problemCtx, decref_callback_ptr)
    return idx_ns
end

function optframe_api1d_create_component_list(engine::Ptr{Cvoid}, char_list::Cstring, list_type::Cstring)
    creation_symbol = get_function_symbol(optframe_ptr, "optframe_api1d_create_component_list")
	return  @ccall $creation_symbol(engine::Ptr{Cvoid}, char_list::Cstring, list_type::Cstring)::Cint
end

function create_component_list(engine::Engine, string_list::String, list_type::String)
	factory = engine.hf
	char_list = Cstring(pointer(string_list))
	char_type = Cstring(pointer(list_type))
	return optframe_api1d_create_component_list(
		factory::Ptr{Cvoid},
		char_list::Cstring,
		char_type::Cstring,
	)::Cint
end

# =====================================

function optframe_api1d_engine_list_builders(engine::Ptr{Cvoid}, list_type::Cstring)
    creation_symbol = get_function_symbol(optframe_ptr, "optframe_api1d_engine_list_builders")
	return  @ccall $creation_symbol(engine::Ptr{Cvoid}, list_type::Cstring)::Cint
end

function list_builders(engine::Engine, list_type::String)
	factory = engine.hf
	char_type = Cstring(pointer(list_type))
	return optframe_api1d_engine_list_builders(
		factory::Ptr{Cvoid},
		char_type::Cstring,
	)::Cint
end

# =========================================

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
    # TODO: keep function 'default_onfail_ptr'?
    res = optframe_api1d_engine_check(e.hf, Int32(p1), Int32(p2), Int32(verbose), default_onfail_ptr)
    return res
end


# =================================

function welcome(e::Engine)
    optframe_api0d_engine_welcome(e.hf)
end

end # module Optframe
