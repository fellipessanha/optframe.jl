include("../src/OptFrame.jl")
using .OptFrame

engine::Engine = OptFrame.init_engine(0)
println()
println("testing welcome...")
engine |> welcome
println()
