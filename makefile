all: optframe_lib_test

optframe_lib_test:
	git submodule update
	cd thirdparty/optframe-external/ && make optframe_lib_test
	mkdir -p build/
	mv thirdparty/optframe-external/build/*.so build/
	cp build/*.so src/
