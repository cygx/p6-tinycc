use NativeCall;
use TinyCC::State;
use TinyCC::Binary;

my enum <_ MEM EXE DLL OBJ PRE>;
my constant RELOCATE_AUTO = Pointer.new(1);

class X::TCC is Exception {
    has $.message;
}

my class TCC is export {
    has @!options;
    has @!code;
    has @!defines;
    has @!undefs;
    has @!symbols;
    has $!error;

    method !CHECK-ERROR is hidden-from-backtrace {
        if defined $!error {
            LEAVE $!error = Nil;
            X::TCC.new(message => $!error).throw;
        }
    }

    method !COMPILE($type) is hidden-from-backtrace {
        my $state := TCCState.new;
        UNDO .delete with $state;

        $state.set_error_func(Pointer, -> $, $!error {});

        proto option(|) { {*}; self!CHECK-ERROR }
        multi option(:I($_)!) { $state.add_include_path($_) }
        multi option(:isystem($_)!) { $state.add_sysinclude_path($_) }
        multi option(:L($_)!) { $state.add_library_path($_) }
        multi option(:l($_)!) { $state.add_library($_) }
        multi option(:$nostdinc!) { $state.set_options('-nostdinc') }
        multi option(:$nostdlib!) { $state.set_options('-nostdlib') }

        option |$_ for @!options;
        $state.set_output_type($type);
        self!CHECK-ERROR;

        for @!undefs {
            $state.undefine_symbol($_);
            self!CHECK-ERROR;
        }

        for @!defines {
            $state.define_symbol(.key, .value);
            self!CHECK-ERROR;
        }

        for @!symbols {
            $state.add_symbol(.key, nativecast(Pointer, .value));
            self!CHECK-ERROR;
        }

        for @!code {
            $state.compile_string($_);
            self!CHECK-ERROR;
        }

        @!code = Empty;

        $state;
    }

    method reset {
        @!options = Empty;
        @!code = Empty;
        @!defines = Empty;
        @!undefs = Empty;
        @!symbols = Empty;
        $!error = Nil;
        self;
    }

    method set(*@_) {
        PRE %_ == 1;
        my $key = %_.keys[0];
        @!options.push($key => $_) for @_;
        self;
    }

    method define(*%_) {
        @!defines.append(%_.pairs.map: {
            .key => do given .value {
                when Bool { Str }
                default { .Str }
            }
        });

        self;
    }

    method undef(*%_) {
        @!undefs.append(%_.keys);
        self;
    }

    method declare(*%_) {
        @!symbols.append(%_.pairs);
        self;
    }

    method compile(*@_) {
        @!code.append(@_);
        self;
    }

    method run(*@args) {
        my $state := self!COMPILE(MEM);
        LEAVE .delete with $state;

        my int $rv = $state.run(+@args, CArray[Str].new(@args>>.Str));
        self!CHECK-ERROR;

        $rv;
    }

    multi method relocate(:$auto!) {
        my $state = self!COMPILE(MEM);
        UNDO .delete with $state;

        $state.relocate(RELOCATE_AUTO);
        self!CHECK-ERROR;

        TCCBinary.new(:$state);
    }

    multi method relocate {
        my $state = self!COMPILE(MEM);
        UNDO .delete with $state;

        my int $size = $state.relocate(Pointer);
        self!CHECK-ERROR;

        my $bytes := buf8.allocate($size);
        $state.relocate(nativecast(Pointer, $bytes));
        self!CHECK-ERROR;

        TCCBinary.new(:$state, :$bytes);
    }
}
