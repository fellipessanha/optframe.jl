all: build/optframe_lib.so

build/optframe_lib.so:
	git submodule update --init --recursive
	git submodule update
	cd thirdparty/optframe-external/ && make optframe_lib_test
	mkdir -p build/
	mv thirdparty/optframe-external/build/*.so build/

test: build/optframe_lib.so
	cp build/*.so tests/
	echo "Test 1"
	cd tests && julia LoadOptFrame.jl
	echo "Test 2"
	cd tests && julia LoadKP.jl

clean:
	rm -f build/optframe_lib.so
