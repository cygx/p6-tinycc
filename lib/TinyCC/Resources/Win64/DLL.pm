sub EXPORT {
    %*ENV<LIBTCC> = ~%?RESOURCES<win64/libtcc.dll>;
    BEGIN Map.new;
}
