use NativeCall;

sub LIB { once %*ENV<LIBTCC> // BEGIN %*ENV<LIBTCC> // 'tcc' }

my enum <_ MEM EXE DLL OBJ PRE>;
my constant RELOCATE_AUTO = Pointer.new(1);

class X::TinyCC is Exception {
    has $.message;
}

my class TCCState is repr<CPointer> {
    sub new(--> TCCState)
        is native(&LIB) is symbol<tcc_new> {*}

    method new { new }

    method delete()
        is native(&LIB) is symbol<tcc_delete> {*}

    method set_lib_path(Str)
        is native(&LIB) is symbol<tcc_set_lib_path> {*}

    method set_error_func(Pointer, & (Pointer, Str))
        is native(&LIB) is symbol<tcc_set_error_func> {*}

    method set_options(Str)
        is native(&LIB) is symbol<tcc_set_options> {*}

    method add_include_path(Str --> int32)
        is native(&LIB) is symbol<tcc_add_include_path> {*}

    method add_sysinclude_path(Str --> int32)
        is native(&LIB) is symbol<tcc_add_sysinclude_path> {*}

    method define_symbol(Str, Str)
        is native(&LIB) is symbol<tcc_define_symbol> {*}

    method undefine_symbol(Str)
        is native(&LIB) is symbol<tcc_undefine_symbol> {*}

    method add_file(Str --> int32)
        is native(&LIB) is symbol<tcc_add_file> {*}

    method compile_string(Str --> int32)
        is native(&LIB) is symbol<tcc_compile_string> {*}

    method set_output_type(int32 --> int32)
        is native(&LIB) is symbol<tcc_set_output_type> {*}

    method add_library_path(Str --> int32)
        is native(&LIB) is symbol<tcc_add_library_path> {*}

    method add_library(Str --> int32)
        is native(&LIB) is symbol<tcc_add_library> {*}

    method add_symbol(Str, Pointer --> int32)
        is native(&LIB) is symbol<tcc_add_symbol> {*}

    method output_file(Str --> int32)
        is native(&LIB) is symbol<tcc_output_file> {*}

    method run(int32, CArray[Str] --> int32)
        is native(&LIB) is symbol<tcc_run> {*}

    method relocate(Pointer --> int32)
        is native(&LIB) is symbol<tcc_relocate> {*}

    method get_symbol(Str --> Pointer)
        is native(&LIB) is symbol<tcc_get_symbol> {*}
}

my class TCCBinary {
    has $.state;
    has $.blob;

    proto method lookup($, $?) {*}
    multi method lookup($name) { $!state.get_symbol($name) }
    multi method lookup($name, $type) {
        nativecast $type, $!state.get_symbol($name);
    }

    method close {
        $!state.delete;
        $!state = Nil;
        self;
    }
}

my class TinyCC {
    has @!options;
    has @!code;
    has $!error;

    method !CHECK-ERROR is hidden-from-backtrace {
        if defined $!error {
            LEAVE $!error = Nil;
            X::TinyCC.new(message => $!error).throw;
        }
    }

    method !COMPILE($type) is hidden-from-backtrace {
        my $state := TCCState.new;
        $state.set_error_func(Pointer, -> $, $!error {});

        proto option(|) { {*}; self!CHECK-ERROR }
        multi option(:I($_)!) { $state.add_include_path($_) }
        multi option(:isystem($_)!) { $state.add_sysinclude_path($_) }
        multi option(:L($_)!) { $state.add_library_path($_) }
        multi option(:l($_)!) { $state.add_library($_) }
        multi option(:$nostdinc!) { $state.set_options('-nostdinc') }
        multi option(:$nostdlib!) { $state.set_options('-nostdlib') }

        option |$_ for @!options;
        $state.set_output_type(MEM);
        self!CHECK-ERROR;

        for @!code {
            $state.compile_string($_);
            self!CHECK-ERROR;
        }

        $state;
    }

    method reset {
        @!options = Empty;
        @!code = Empty;
        $!error = Nil;
        self;
    }

    method set(*@_) {
        PRE %_ == 1;
        my $key = %_.keys[0];
        @!options.push($key => $_) for @_;
        self;
    }

    method compile(*@_) {
        @!code.append(@_);
        self;
    }

    method run(*@args) {
        my $state := self!COMPILE(MEM);
        my int $rv = $state.run(+@args, CArray[Str].new(@args>>.Str));
        self!CHECK-ERROR;

        $state.delete;
        $rv;
    }

    method relocate {
        my $state = self!COMPILE(MEM);
        my int $size = $state.relocate(Pointer);
        self!CHECK-ERROR;

        my $blob := buf8.allocate($size);
        $state.relocate(nativecast(Pointer, $blob));
        self!CHECK-ERROR;

        TCCBinary.new(:$state, :$blob);
    }
}

sub EXPORT {
    Map.new((tcc => TinyCC.new));
}
