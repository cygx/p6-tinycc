# Copyright 2017 cygx <cygx@cpan.org>
# Distributed under the Boost Software License, Version 1.0

use TinyCC::Resources::Win64::DLL;
sub EXPORT {
    TinyCC::Resources::Win64::DLL.setenv;
    BEGIN Map.new;
}
