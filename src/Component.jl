struct Component{T}
    index::Integer

    function Component{T}(idx::Integer) where {T}
        @assert(idx >= 0, "Index must be non-negative")
        @assert(T isa Symbol, "Component specification type must be a Symbol")

        return new{T}(idx)
    end

    function Component(component::String, idx::Integer)
        @assert(idx >= 0, "Index must be non-negative")

        if !startswith(component, "OptFrame:")
            component = "OptFrame:" * component
        end

        return new{Symbol(component)}(idx)
    end
end

function Base.show(io::IO, c::T) where {T<:Component}
    print(io, "$(T.parameters[1]) $(c.index)")
end

function get_return_type_from_builder(
    ::Type{T},
)::String where {T<:optcomponent"ComponentBuilder:LocalSearch:FI"}
    return "LocalSearch"
end
function get_return_type_from_builder(
    ::Type{T},
)::String where {T<:optcomponent"ComponentBuilder:LocalSearch:BI"}
    return "LocalSearch"
end

function get_return_type_from_builder(::Type{T})::String where {T<:Component}
    error("caiu onde nao devia")
end