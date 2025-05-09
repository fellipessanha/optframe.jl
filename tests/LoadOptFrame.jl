include("../src/Optframe.jl")
using .OptFrame


engine = OptFrame.init_engine(0)
println()
println("testing welcome...")
engine |> welcome
println()

