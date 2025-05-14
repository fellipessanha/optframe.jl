all: build/optframe_lib.so

build/optframe_lib.so:
	git submodule update --init --recursive
	git submodule update
	cd thirdparty/optframe-external/ && make optframe_lib_test
	mkdir -p build/
	mv thirdparty/optframe-external/build/*.so build/
	ln -s build/optframe_lib.so test/

test: build/optframe_lib.so test_init test_kp test_tsp

instantiate:
	julia --proj=.                  -e 'import Pkg; Pkg.instantiate()'
	julia --proj=./OptFrameTSP      -e 'import Pkg; Pkg.develop(; path = @__DIR__); Pkg.instantiate()'
	julia --proj=./OptFrameKnapsack -e 'import Pkg; Pkg.develop(; path = @__DIR__); Pkg.instantiate()'
	
	julia --proj=./test -e 'import Pkg; Pkg.develop(; path = joinpath(@__DIR__, "OptFrameTSP")); Pkg.instantiate()'
	julia --proj=./test -e 'import Pkg; Pkg.develop(; path = joinpath(@__DIR__, "OptFrameKnapsack")); Pkg.instantiate()'

test_init:
	echo "test Load Optframe"
	cd tests && julia LoadOptFrame.jl

test_kp: build/optframe_lib.so
	echo "Test kp"
	cd tests && julia LoadKP.jl

test_tsp:
	echo "Test tsp"
	cd tests && julia loadTSP.jl


clean:
	rm -f build/optframe_lib.so
