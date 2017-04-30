use TinyCC::Compiler;
use TinyCC::Typeof;

my role Bytes[$bytes] { method bytes { $bytes } }

sub func($fn is rw, Signature $sig, Str $body) is export {
    PRE $sig.arity == $sig.params;

    my $name = $fn.VAR.name.substr(1);
    my $rtype = typeof $sig.returns;
    my @params = $sig.params.map({ "{typeof .type} {.name}" });
    my $unit = "$rtype $name\({@params.join(', ')}) \{$body}";

    my $bin := TCC.new.compile($unit).relocate;
    LEAVE .close with $bin;

    $fn = $bin.lookup($name, $sig);
    $fn does Bytes[$bin.bytes];
}
