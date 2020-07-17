(import ../../shell.nix).overrideAttrs (old: {
  shellHook = ''
    ${old.shellHook or ""}
    function build-clash() {
      clash --systemverilog -outputdir clash-out Counter.hs "$@"
    }
    function run-formal() {
      sby -f demo.sby "$@"
    }
    echo "Available commands:"
    echo " $ build-clash"
    echo " $ run-formal clash"
    echo " $ run-formal sv"
  '';
})
