{ pkgs }:
pkgs.stdenv.mkDerivation rec {
  pname = "tsundere";
  version = "v2024-09-18";

  src = builtins.fetchTarball {
     url =
       "https://github.com/shoeb751/tsundere/archive/refs/tags/${version}.zip";
     sha256 = "0k4g1l95d2c3fc1bn21pky8r2jzsd1wznm6n2jss2bn4agpfv8g6";
  };

  libsrc = builtins.fetchTarball {
    url =
      "https://github.com/shoeb751/tsundere_lib/archive/0f194431ba6439ffa2c8d700ee79feaef216ce68.zip";
    sha256 = "16f4ik569mz761s7jkwf80yzlcr0lfa4qw5sy2bj8r4wchk308g8";
  };

  buildInputs = with pkgs; with lua54Packages; [ luasocket luasec cjson ];

  configurePhase = "";

  buildPhase = ''
    sed -i '2 a package.path = package.path .. ";${
      with pkgs;
      with lua54Packages;
      builtins.concatStringsSep ";" (map getLuaPath buildInputs)
    }"' t.lua
    sed -i '2 a package.cpath = package.cpath .. ";${
      with pkgs;
      with lua54Packages;
      builtins.concatStringsSep ";" (map getLuaCPath buildInputs)
    }"' t.lua
  '';

  installPhase = ''
    mkdir -p $out/bin/lib
    cp ./t.lua $out/bin
    ln -s ./t.lua $out/bin/t

    cp $libsrc/*.lua $out/bin/lib
    cd $out
    lua -e 'local f, e = loadfile("${libsrc}/binoverride.lua"); if e then print (e) end; r = f(); for k,v in pairs(r) do print(k) end' | xargs -i ln -s ./t.lua $out/bin/{}
  '';
}
