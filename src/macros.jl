macro optcomponent_str(str)
    base_string = "OptFrame:"
    @assert(occursin(base_string, str), "OptFrame components must be prefixed with $(base_string)")
    return :(Component{Symbol($str)})
end

@doc raw"""
    @add_evaluator

## Example

```julia
OptFrame.@add_evaluator(
    problem,
    func::Cdouble, # `function_name`::`return_type`
    true,          # is maximization sense?
)
```
"""
macro add_evaluator(problem, expr::Expr, maximize::Bool = false)
    # pedir que expr seja da forma `@add_evaluator fptr::T`
    @assert expr.head === :(::)
    @assert length(expr.args) == 2

    fptr = expr.args[1]
    type = expr.args[2]

    return quote
        let p_ptr = Ptr{Nothing}(pointer_from_objref($(esc(problem))))
            c_ptr = @cfunction($fptr, $type, (Ptr{Cvoid}, Ptr{Cvoid}))
            
            OptFrame.add_evaluator(
                $(esc(problem)).engine,
                c_ptr,
                $(esc(maximize)),
                p_ptr,
            )

        end
    end
end

macro add_constructive(
	problem,
	initial_solution_pointer::Expr,
	deepcopy_callback_pointer::Expr,
	tostring_callback_pointer::Expr,
	free_tsp_solution_pointer::Expr,
)
	return quote
		let initial_solution_pointer  = @cfunction($(initial_solution_pointer), Ptr{Cvoid}, (Ptr{Cvoid},))
			deepcopy_callback_pointer = @cfunction($(deepcopy_callback_pointer), Ptr{Cvoid}, (Ptr{Cvoid},))
			tostring_callback_pointer = @cfunction($(tostring_callback_pointer), Csize_t, (Ptr{Cvoid}, Ptr{Cchar}, Csize_t))
			free_tsp_solution_pointer = @cfunction($(free_tsp_solution_pointer), Cint, (Ptr{Cvoid},))
			problem_ptr               = pointer_from_objref($(esc(problem)))


				idx_ns = OptFrame.add_constructive(
					$(esc(problem)).engine,
					initial_solution_pointer,
					problem_ptr,
					deepcopy_callback_pointer,
					tostring_callback_pointer,
					free_tsp_solution_pointer,
				)
		end
	end
end
