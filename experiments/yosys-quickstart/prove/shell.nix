(import ../../shell.nix).overrideAttrs (old: {
  shellHook = ''
    ${old.shellHook or ""}
    function build-clash() {
      clash --verilog -outputdir clash-out Demo.hs "$@"
    }
    function run-formal() {
      sby -f prove.sby "$@"
    }
    echo "Available commands:"
    echo " $ build-clash"
    echo " $ run-formal clash"
    echo " $ run-formal sv"
  '';
})
