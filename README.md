This issue tracker is for bugs and feature requests for the
[Haskell Wiki][1].  This is just for issues with the
installation/maintenance of the wiki software itself (which is an
installation of [MediaWiki][2]). It also includes the customized wiki skin and some customizations to the configuration.

For issues with the *content* of the wiki, just edit the wiki! 😃

[1]: https://wiki.haskell.org/
[2]: https://www.mediawiki.org/

# Development

There is a test vm setup in the nix flake. The test vm uses the environment variable `$HAWIKI_CONFIG` to pass in the configuration for the test vm. You can either manually set the variable `export HAWIKI_CONFIG=/absolute/path/to/hawiki-config` or use `nix develop` to set it the `hawiki-config` directory in this project.

You will need a dump of the db and to setup a test password in `${HAWIKI_CONFIG}/hawiki-pass`

You can build the test vm with

```bash
nixos-rebuild build-vm --flake .#hawiki-vm
```

You can start the vm with
```bash
./result/bin/run-hawiki-vm-vm
```

To setup the db with the dump inside the vm
```bash
nixos-container root-login hawiki
cat /var/lib/mediawiki/hawiki-dump.sql | mysql mediawiki
exit
nixos-container restart hawiki
```

To cleanup the vm state
```bash
./result/bin/run-hawiki-vm-vm
```
