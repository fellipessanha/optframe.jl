module OptFrame

using Libdl
export Engine, init_engine, welcome, arena_count, register, unregister, global_arena_count, global_register, global_unregister

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

# function add_constructive(e::Engine, problemCtx::Ptr{Cvoid}, constructive_callback_ptr)
#     # constructive_callback_ptr = FUNC_FCONSTRUCTIVE(constructive_callback_julia)
#     # const constructive_callback_ptr = @cfunction(constructive_callback_julia, Ptr{Cvoid}, (Ptr{Cvoid},))

#     # pendura pointer!!!
#     # self.register_callback(constructive_callback_ptr)
#     #
#     creation_symbol = get_function_symbol(optframe_ptr, "optframe_api1d_add_constructive")
#     idx_c = @ccall $creation_symbol(Ptr{Cvoid}, n::Cint)::Ptr{Cvoid}

#     idx_c = optframe_lib.optframe_api1d_add_constructive(
#         e.hf, constructive_callback_ptr, problemCtx,
#         self.callback_sol_deepcopy_ptr,
#         self.callback_sol_tostring_ptr,
#         self.callback_utils_decref_ptr)
#     return IdConstructive(idx_c)
# end

# =================================

function welcome(e::Engine)
    optframe_api0d_engine_welcome(e.hf)
end

end # module Optframe
