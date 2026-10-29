compile:
	hetu compile src/plugin.ht build/plugin.out; cp build/plugin.out example/assets/bytecode/

archive:
	mkdir -p build/archive; \
	cp plugin.json build/plugin.out assets/logo.png build/archive/; \
	cd build/archive; \
	zip -r plugin.zip ./; \
	cd ../..; \
	mv build/archive/plugin.zip build/plugin.smplug

test: compile
	cd example && flutter test
