compile:
	hetu compile src/plugin.ht build/plugin.out; cp build/plugin.out example/assets/bytecode/

archive:
	mkdir -p build/archive; \
	cp plugin.json build/plugin.out build/archive/; \
	pushd build/archive; \
	zip -r plugin.zip ./; \
	popd; \
	mv build/archive/plugin.zip build/plugin.smplug
