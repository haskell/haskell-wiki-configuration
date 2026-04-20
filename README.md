This issue tracker is for bugs and feature requests for the
[Haskell Wiki][1].  This is just for issues with the
installation/maintenance of the wiki software itself (which is an
installation of [MediaWiki][2]). It also includes the customized wiki skin and some customizations to the configuration.

For issues with the *content* of the wiki, just edit the wiki! 😃

[1]: https://wiki.haskell.org/
[2]: https://www.mediawiki.org/

# Development

There is a test vm setup in the nix flake. The test vm uses the environment variable `$HAWIKI_STATE` to pass in the state dir for the test vm. You can either manually set the variable `export HAWIKI_STATE=/absolute/path/to/hawiki-state` or use `nix develop` to set it the `hawiki-state` directory in this project.

You will need a dump of the db and to setup a test password in `${HAWIKI_STATE}/initial-password`

## Using `just`

Commands below will use [just](https://just.systems/man/en/). If you can't or
don't want to use just, look in ./justfile to see the expanded commands.

just is included in the Nix shell.

## Build the VM

You can build the test vm with

```bash
just vm-build
```

## Run (and stop) the VM
You can start the vm with
```bash
just vm-run
```

Once inside the vm, press `C-a x`. That's the QEMU escape sequence.

> [!NOTE]
> You can't exit the vm by exiting the shell. Use the escape sequence instead.

> [!TIP]
> Tired of your test wiki data or stuck with unwanted persistent state? Delete
> it with `just vm-clean` or `just vm-reallyclean`.

## Use the dev wiki

Run the VM. Access the dev wiki at http://localhost:18888

Log in as admin. The initial password in the default hawiki-state is
`coolpassword`.

### Editing

In order to edit pages, the admin user needs to have their email validated.

1. Run the VM
2. Inside the VM, enter the container with `machinectl shell hawiki`.
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
