all: build/optframe_lib.so

build/optframe_lib.so:
	git submodule update --init --recursive
	git submodule update
	cd thirdparty/optframe-external/ && make optframe_lib_test
	mkdir -p build/
	mv thirdparty/optframe-external/build/*.so build/
	ln -s build/optframe_lib.so test/

test_lib: build/optframe_lib.so
	julia --project -e 'import Pkg; Pkg.test()'

instantiate:
	julia --proj=.                  -e 'import Pkg; Pkg.instantiate()'
	julia --proj=./OptFrameTSP      -e 'import Pkg; Pkg.develop(; path = "."); Pkg.instantiate()'
	julia --proj=./OptFrameKnapsack -e 'import Pkg; Pkg.develop(; path = "."); Pkg.instantiate()'
	
	julia --proj=./test -e 'import Pkg; Pkg.develop([Pkg.PackageSpec(; path = "./OptFrameTSP"), Pkg.PackageSpec(; path = "./OptFrameKnapsack")]); Pkg.instantiate();'

clean:
	rm -f build/optframe_lib.so
