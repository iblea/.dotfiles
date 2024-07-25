
brew_openssl_prefix=$(brew --prefix openssl)
brew_libnet_prefix=$(brew --prefix libnet)
brew_jsonc_prefix=$(brew --prefix json-c)

export LDFLAGS="-L$brew_openssl_prefix/lib -L$brew_libnet_prefix/lib -L$brew_jsonc_prefix/lib"
export CFLAGS="-I$brew_openssl_prefix/include -I$brew_libnet_prefix/include -I$brew_jsonc_prefix/include"
export CPPFLAGS="-I$brew_openssl_prefix/include -I$brew_libnet_prefix/include -I$brew_jsonc_prefix/include"

unset brew_openssl_prefix
unset brew_libnet_prefix
unset brew_jsonc_prefix
