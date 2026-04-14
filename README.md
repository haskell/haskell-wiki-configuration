This issue tracker is for bugs and feature requests for the
[Haskell Wiki][1].  This is just for issues with the
installation/maintenance of the wiki software itself (which is an
installation of [MediaWiki][2]). It also includes the customized wiki skin and some customizations to the configuration.

For issues with the *content* of the wiki, just edit the wiki! 😃

[1]: https://wiki.haskell.org/
[2]: https://www.mediawiki.org/

# Development

There is a test vm setup in the nix flake. The test vm uses the environment variable `$HAWIKI_STATE` to pass in the state dir for the test vm. You can either manually set the variable `export HAWIKI_STATE=/absolute/path/to/hawiki-state` or use `nix develop` to set it the `hawiki-state` directory in this project.

You will need a dump of the db and to setup a test password in `${HAWIKI_STATE}/hawiki-pass`

## Build the VM

You can build the test vm with

```bash
nixos-rebuild build-vm --flake .#hawiki-vm
```

## Run (and stop) the VM
You can start the vm with
```bash
./result/bin/run-hawiki-vm-vm
```

To exit, press `C-a x`. That's the QEMU escape sequence.

## Use the dev wiki

Log in as admin with the password you've placed in hawiki-pass.

### Editing

In order to edit pages, the admin user needs to have their email validated.

1. Run the VM
2. Inside the VM, enter the container with `nixos-container root-login hawiki`
3. Get a timestamp with `date +%Y%m%d%H%M`
4. Connect to the database with `mysql mediawiki`
5. Run the sql:
   ```
   update user
   set user_email = admin@example.com, user_email_authenticated = '$timestamp'
   where user_name = 'Admin';
   ```

   Replace `$timestamp` with the output from step 3.

Log out (of the wiki) and log in again for the change to take effect.
