use TinyCC::Resources::Win64::DLL;
sub EXPORT {
    TinyCC::Resources::Win64::DLL.setenv;
    BEGIN Map.new;
}
