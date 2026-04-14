vm-build:
    nixos-rebuild build-vm --flake .#hawiki-vm

vm-run: vm-build
    ./result/bin/run-hawiki-vm-vm

# Remove the VM state file
vm-clean:
    rm hawiki-vm.qcow2

# Also clean out the default state dir ./hawiki-state
vm-reallyclean: vm-clean
    git clean -fdx hawiki-state
