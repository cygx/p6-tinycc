REPO = http://repo.or.cz/tinycc.git
FILES = build/COPYING \
        build/win32/libtcc.dll \
        build/win32/lib \
        build/win32/include

update: build
	git -C build pull --depth 1
	make -C build/win32
	mkdir -p resources/win64
	cp -r $(FILES) resources/win64
	perl6 meta.p6 > META6.json

build:
	git clone -b mob --single-branch --depth 1 $(REPO) build
