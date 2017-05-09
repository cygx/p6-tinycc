my $*SPEC = IO::Spec::Unix;
print qq:to/EOF/;
\{
    "name"          : "TinyCC",
    "version"       : "0.1",
    "perl"          : "6.c",
    "author"        : "github:cygx",
    "license"       : "BSL-1.0",
    "description"   : "Bindings for the Tiny C Compiler",
    "repo-type"     : "git",
    "source-url"    : "git://github.com/cygx/p6-tinycc.git",
    "support"       : \{
        "bugtracker"    : "https://github.com/cygx/p6-tinycc/issues",
        "source"        : "https://github.com/cygx/p6-tinycc
    },
    "depends"       : [ ],
    "provides"      : \{
        { join ",\n        ", do gather 'lib'.IO.&(sub recur($_) {
            when .basename eq '.precomp' {}
            when .f {
                my $path = ~$_;
                my $mod = $path.subst(/^lib\/|\.pm$/, '', :g).subst('/', '::', :g);
                take "{$mod.perl} : {$path.perl}";
            }
            when .d { .&recur for .dir }
        }) }
    },
    "resources"     : [
        { join ",\n        ", do gather 'resources'.IO.&(sub recur($_) {
            when .f { take .substr(10).perl }
            when .d { .&recur for .dir }
        }) }
    ]
}
EOF
