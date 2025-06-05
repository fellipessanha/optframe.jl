struct Component{T}
    index::Integer

    function Component{T}(idx::Integer) where {T}
        @assert(idx >= 0, "Index must be non-negative")
        @assert(T isa Symbol, "Component specification type must be a Symbol")

        return new{Symbol(T)}(idx)
    end
end

function Base.show(io::IO, c::T) where {T<:Component}
    print(io, "$(T.parameters[1]) $(c.index)")
end
