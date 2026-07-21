# nix-homelab
<!-- BEGIN: NIXOS HOMELAB POST-INSTALL -->

## NixOS homelab: first deployment after installation

These steps assume that:

- NixOS is already installed and booting on the homelab PC.
- This repository has already been cloned from GitHub.
- The shell is currently inside the repository root, where `flake.nix` is located.
- The target flake configuration is named `homelab`.

> Keep local console access available during the first activation. Do not perform the first switch only through SSH, because an incorrect network, user, firewall, or SSH setting could disconnect the machine.

### 1. Enter the repository and inspect it

```bash
cd /path/to/nix-homelab
pwd
git status
find hosts modules -maxdepth 3 -type f | sort
```

The repository should contain at least:

```text
flake.nix
hosts/homelab/default.nix
modules/base.nix
modules/networking.nix
modules/ssh.nix
modules/users.nix
modules/storage.nix
modules/containers.nix
modules/homelab/default.nix
modules/services/default.nix
```

`flake.lock` may be absent before the first deployment. It will be generated
on the NixOS homelab PC and then committed to this repository.

Do not run the old repository-bootstrap scripts. Their only purpose was to create these files before they were committed to Git.

### 2. Add the real hardware configuration

The repository deliberately does not contain a generic `hardware-configuration.nix`. This file must describe the actual homelab PC, including its file systems, disk UUIDs, boot-related modules, and detected hardware.

If the normal NixOS installation created `/etc/nixos/hardware-configuration.nix`, copy it into the host directory:

```bash
cp /etc/nixos/hardware-configuration.nix \
  hosts/homelab/hardware-configuration.nix
```

If that file does not exist, generate it from the running machine:

```bash
sudo nixos-generate-config --show-hardware-config \
  > hosts/homelab/hardware-configuration.nix
```

Confirm that the file is not empty:

```bash
test -s hosts/homelab/hardware-configuration.nix
grep -nE 'fileSystems|boot.initrd|nixpkgs.hostPlatform' \
  hosts/homelab/hardware-configuration.nix
```

### 3. Enable the hardware import

Open the host configuration:

```bash
nvim hosts/homelab/default.nix
```

Inside the `imports` list, change:

```nix
# ./hardware-configuration.nix
```

to:

```nix
./hardware-configuration.nix
```

The beginning of the file should resemble:

```nix
{ lib, ... }:

{
  imports = [
    ./hardware-configuration.nix

    ../../modules/base.nix
    ../../modules/networking.nix
    ../../modules/ssh.nix
    ../../modules/users.nix
    ../../modules/storage.nix
    ../../modules/containers.nix
    ../../modules/homelab
    ../../modules/services
  ];
```

In a NixOS module, `imports` combines the listed modules into one system configuration. It is not the same as the Nix-language `import` function.

### 4. Review machine-specific settings before activation

#### Hostname

The intended hostname is currently:

```nix
networking.hostName = "homelab";
```

Keep it or change it in `hosts/homelab/default.nix` before the first activation.

#### Platform

The configuration currently targets a normal 64-bit Intel or AMD PC:

```nix
nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
```

Check the installed machine:

```bash
uname -m
```

Expected output for this configuration:

```text
x86_64
```

#### State version

The repository currently contains:

```nix
system.stateVersion = "26.05";
```

This value should represent the NixOS release used for the machine's first managed installation. Do not increase it merely because NixOS or Nixpkgs is upgraded later. Change it now only if the initial installation was performed with a different release and you have deliberately chosen that release as the machine's state version.

#### Administrative user

The configuration currently declares the user `vp` in `modules/users.nix`.

Check the current account and groups:

```bash
whoami
id vp
```

Before relying on remote login, confirm that `vp` has a working password or an SSH public key. To set or replace the local password:

```bash
sudo passwd vp
```

For SSH-key authentication, add only the **public** key to `modules/users.nix`, for example:

```nix
openssh.authorizedKeys.keys = [
  "ssh-ed25519 AAAA... workstation-key"
];
```

Never commit private SSH keys, plaintext passwords, API tokens, recovery codes, or other secrets to this repository.

#### Network

The current module enables NetworkManager. Inspect the detected interfaces and current connection before switching:

```bash
ip -brief address
nmcli device status
nmcli connection show
ip route
```

The current configuration is suitable for DHCP through NetworkManager. A static address, bridge, VLAN, bond, or server-specific DNS configuration should be added only after the actual network design is known.

#### SSH and firewall

The repository enables OpenSSH and the NixOS firewall. Before using the machine without a monitor, verify the final SSH configuration and test login from another computer on the local network.

Do not disable SSH password authentication until public-key login has been tested successfully in a separate terminal.

### 5. Stage the hardware file before evaluating the flake

A flake loaded from a Git repository normally sees files that are tracked or staged by Git. Stage the new hardware file and the edited host configuration before checking the flake:

```bash
git add hosts/homelab/hardware-configuration.nix
git add hosts/homelab/default.nix
git status
```

This does not create a commit yet. It makes the files visible to Git-based flake evaluation.

### 6. Create or use the locked input

`flake.lock` pins the exact Nixpkgs revision used by the repository. Unlike
`hardware-configuration.nix`, it is repository-specific rather than
hardware-specific.

If it does not exist during the first deployment, generate it on the NixOS
homelab PC:

```bash
test -f flake.lock || nix flake lock
```

Confirm that it exists and stage it:

```bash
test -s flake.lock
git add flake.lock
git status --short flake.lock
```

If `flake.lock` was already committed, use it unchanged for the first build.
Do not run `nix flake update` merely to make the initial deployment work,
because that deliberately selects newer input revisions.

Inspect the flake:

```bash
nix flake metadata
nix flake show
```

The output should include:

```text
nixosConfigurations.homelab
```
### 7. Evaluate and check the configuration

Check the flake:

```bash
nix flake check
```

Confirm the configured hostname:

```bash
nix eval \
  .#nixosConfigurations.homelab.config.networking.hostName \
  --raw

echo
```

Expected output:

```text
homelab
```

Confirm the state version:

```bash
nix eval \
  .#nixosConfigurations.homelab.config.system.stateVersion \
  --raw

echo
```

Build the complete NixOS system without activating it:

```bash
sudo nixos-rebuild build --flake .#homelab
```

A successful build creates a `result` symlink in the repository. That symlink is a build result and should not be committed.

### 8. Test the new system temporarily

Activate the configuration without making it the default boot generation:

```bash
sudo nixos-rebuild test --flake .#homelab
```

Immediately verify the essential functions:

```bash
hostnamectl
id vp
nmcli device status
ip -brief address
ip route
systemctl status sshd --no-pager
ss -lntup
```

From another machine on the same network, test SSH:

```bash
ssh vp@homelab
```

If local DNS does not yet resolve `homelab`, use the server's IP address:

```bash
ssh vp@SERVER_IP_ADDRESS
```

Keep the local console session open while performing this test.

### 9. Make the configuration permanent

After the temporary activation works correctly:

```bash
sudo nixos-rebuild switch --flake .#homelab
```

Verify the active system:

```bash
nixos-version
hostnamectl
systemctl is-active sshd
systemctl --failed
```

Reboot once and confirm that the machine returns with networking and SSH working:

```bash
sudo reboot
```

After reconnecting:

```bash
hostnamectl
systemctl --failed
```

### 10. Commit the machine-specific configuration

Review exactly what will be committed:

```bash
git diff --cached
git status
```

Stage the generated lock file, hardware configuration, and edited host
module:

```bash
git add flake.lock
git add hosts/homelab/hardware-configuration.nix
git add hosts/homelab/default.nix
```

Then commit and push:

```bash
git commit -m "Add homelab machine configuration"
git push
```

`hardware-configuration.nix` describes the physical machine and is normally
committed so that the same computer can be rebuilt. `flake.lock` pins the
exact Nixpkgs revision used for the deployment. Review both before publishing
the repository.
### 11. Normal workflow for later configuration changes

After editing one or more `.nix` files:

```bash
git diff
nix flake check
sudo nixos-rebuild build --flake .#homelab
sudo nixos-rebuild test --flake .#homelab
sudo nixos-rebuild switch --flake .#homelab
```

Then record the tested change:

```bash
git add flake.nix flake.lock hosts modules README.md
git status
git commit -m "Describe the homelab change"
git push
```

Do not use `git add .` blindly after services begin storing local data near the repository. Always inspect `git status` first.

### 12. Pulling changes made on another computer

Before deploying changes created and pushed from the laptop:

```bash
cd /path/to/nix-homelab
git status
git pull --ff-only
nix flake check
sudo nixos-rebuild test --flake .#homelab
sudo nixos-rebuild switch --flake .#homelab
```

Use `git pull --ff-only` so that Git stops instead of creating an unexpected merge commit when local and remote history have diverged.

### 13. Updating Nixpkgs deliberately

The `flake.lock` file pins the exact Nixpkgs revision. Updating the operating system packages is therefore a deliberate repository change:

```bash
cd /path/to/nix-homelab
git status
nix flake update
nix flake check
sudo nixos-rebuild build --flake .#homelab
sudo nixos-rebuild test --flake .#homelab
sudo nixos-rebuild switch --flake .#homelab
```

After the updated system has been tested:

```bash
git add flake.lock
git commit -m "Update flake inputs"
git push
```

Do not change `system.stateVersion` as part of a routine flake update.

### 14. Recovery and rollback

If a newly switched configuration is faulty but the system is still usable:

```bash
sudo nixos-rebuild switch --rollback
```

If the machine does not boot normally, select an earlier NixOS generation from the bootloader menu.

Inspect available system generations with:

```bash
sudo nix-env --list-generations --profile /nix/var/nix/profiles/system
```

After recovering, fix or revert the Git change before attempting another deployment:

```bash
git status
git log --oneline --decorate -n 10
```

### 15. Useful diagnostics

```bash
# Failed systemd units
systemctl --failed

# Logs for the current boot
journalctl -b -p warning

# SSH service logs
journalctl -u sshd -b

# Network status
nmcli device status
ip -brief address
ip route

# NixOS generation and version
readlink -f /run/current-system
nixos-version

# Flake information
nix flake metadata
nix flake show
```

### References

- [NixOS manual](https://nixos.org/manual/nixos/stable/)
- [MyNixOS option: `system.stateVersion`](https://mynixos.com/nixpkgs/option/system.stateVersion)
- [MyNixOS option: `networking.networkmanager.enable`](https://mynixos.com/nixpkgs/option/networking.networkmanager.enable)
- [MyNixOS option: `services.openssh.openFirewall`](https://mynixos.com/nixpkgs/option/services.openssh.openFirewall)

<!-- END: NIXOS HOMELAB POST-INSTALL -->
