{ self, pkgs }:

pkgs.testers.nixosTest {
  name = "hawiki-smoke";

  nodes.machine = { ... }: {
    imports = [ self.nixosModules.hawiki ];

    services.hawiki = {
      enable = true;
      passFile = "/var/lib/hawiki/initial-password";
      # Lets us curl the wiki from inside the vm.
      url = "localhost:8081";
      secure = false;
    };

    systemd.tmpfiles.rules = [
      "f /var/lib/hawiki/initial-password 0644 root root - test-password"
    ];
  };

  testScript = ''
    machine.wait_for_unit("container@hawiki.service")
    output = machine.succeed("curl --follow --fail-with-body http://localhost:8081/")
    assert "HaskellWiki" in output, f"Expected 'HaskellWiki' in the output, got: {output:1000]}"
  '';
}
