use TinyCC::Compiler;
use TinyCC::Typeof;

my role CSub[$bytes] is export {
    method bytes { $bytes }
}

sub C($body, &sub, $sig = &sub.signature) is export {
    PRE $sig.arity == $sig.params;

    my $name = &sub.name;
    my $rtype = typeof $sig.returns;
    my @params = $sig.params.map({ "{typeof .type} {.name}" });
    my $code = "$rtype $name\({@params.join(', ')}) \{$body}";

    my $bin := TCC.new.compile($code).relocate;
    LEAVE .close with $bin;

    CALLER::MY::{"\&$name"} := $bin.lookup($name, $sig) does CSub[$bin.bytes];
}
