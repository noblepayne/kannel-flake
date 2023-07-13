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
      # oldbison = pkgs.bison.overrideAttrs {
      #   version = "3.3.1";
      # };
      kannel = pkgs.stdenv.mkDerivation rec {
        pname = "kannel";
        version = "1.4.5";

        src = pkgs.fetchurl {
          url = "https://www.kannel.org/download/1.4.5/gateway-1.4.5.tar.bz2";
          sha256 = "r/Q8nGuzcfcygO0HOFMjubQjY1Ac/hPF7O+SXdkmxgw=";
        };

	patches = [
	  ./skip_bison.patch
	];

	# Necessary to support modern bison.
	# See TODO
        # patches = pkgs.fetchurl {
        #   url = "https://redmine.kannel.org/attachments/download/327/gateway-1.4.5.patch.gz";
        #   sha256 = "0GC1mgRsgeHfAJyXrdRYnlLvUd4TEqUgdsVZS0z2jRI=";
        # };

        nativeBuildInputs = [
	  # pkgs.bison  - Only needed if making updates to wmlscript/wsgram.y.
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

	# Use provided wsgram.c and wsgram.h.
	# Must apply above patch or use SVN version of kannel if you wish to build via bison 3.
	# TODO: turn into an actual patch to apply?
	# preBuild = ''
	#   rm wmlscript/wsgram.y
	# '';
	
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
