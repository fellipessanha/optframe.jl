# O que queremos fazer:
# f_ev_ptr = @cfunction(KP.evaluate_solution, Cdouble, (Ptr{Cvoid}, Ptr{Cvoid}))
# idx_ev   = OptFrame.add_evaluator(problem.engine, f_ev_ptr, false, Ptr{Nothing}(problem_ptr))

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
