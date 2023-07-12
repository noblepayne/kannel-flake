{
  description = "Kannel Gateway";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };
  outputs = { self, nixpkgs, flake-utils }: 
    flake-utils.lib.eachDefaultSystem (system:
    let
      pkgs = import nixpkgs { inherit system; };
      kannel = pkgs.stdenv.mkDerivation rec {
        pname = "kannel";
        version = "1.4.5";

        src = pkgs.fetchurl {
          url = "https://www.kannel.org/download/1.4.5/gateway-1.4.5.tar.bz2";
          sha256 = "r/Q8nGuzcfcygO0HOFMjubQjY1Ac/hPF7O+SXdkmxgw=";
        };

	# Necessary to support modern bison.
	# See TODO
        patches = pkgs.fetchurl {
          url = "https://redmine.kannel.org/attachments/download/327/gateway-1.4.5.patch.gz";
          sha256 = "0GC1mgRsgeHfAJyXrdRYnlLvUd4TEqUgdsVZS0z2jRI=";
        };

        nativeBuildInputs = [
	  pkgs.bison
          pkgs.gettext
        ];

        buildInputs = [
          pkgs.hiredis
          pkgs.libxml2
	  pkgs.pcre
        ];

	CFLAGS="-fcommon";

	configureFlags = [
	  "--disable-docs"
	  "--disable-localtime"
	  "--enable-ssl"
	  "--with-redis-dir=$pkgs.hiredis"
	  "--enable-pcre"
	];
	
	doCheck = true;

        # buildPhase = ''
        #   export CFLAGS="$CFLAGS -fcommon"
        #   ./configure --prefix="$out"
        #   make
        # '';

        # installPhase = ''
        #   make install
        # '';
      };

      dockerImage = pkgs.dockerTools.buildImage {
        name = "kannel";
        tag = "latest";
        copyToRoot = pkgs.buildEnv {
          name = "image-root";
          paths = [ kannel ];
          pathsToLink = [ "/bin" ];
        };
	config = { Cmd = [ "/bin/bearerbox" ]; };
      };

    in
    {
      packages = {
        kannel = kannel;
	docker = dockerImage;
      };
      defaultPackage  = kannel;
    });
}
