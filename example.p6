use TinyCC;
use TinyCC::CSub;
use TinyCC::Eval;

say EVAL :lang<C>, :returns(int32), :include<limits.h>, q{
    return INT_MAX;
};

sub add(int32 \a, int32 \b --> int32) {} ==> C(q{
    return a + b;
});

say add(5, 6);

tcc.declare(add => &add.funcptr);
tcc.compile: q{
    #include <stdio.h>
    extern int add(int, int);
    int main(void) {
        printf("%i\n", add(3, 4));
        return 0;
    }
};

tcc.run;
