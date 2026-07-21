# nix-homelab

A declarative, flake-based NixOS configuration for a single homelab server.

This repository is being developed on macOS and validated with GitHub Actions. The physical server will provide the hardware-specific configuration and the first committed `flake.lock`.

The structure is inspired by the modular approach used in [`notthebee/nix-config`](https://git.notthebe.ee/notthebee/nix-config), but only the homelab-server ideas are being adapted. Machine-specific disk layouts, network identifiers, domains, secrets, and hardware settings are not copied.

## Current status

Implemented:

- one NixOS host named `homelab`;
- NixOS 26.05 from Nixpkgs;
- reusable `homelab.*` options;
- central state, data, and backup paths;
- NetworkManager with the NixOS firewall enabled;
- OpenSSH with root login disabled;
- administrative user `vp`;
- flakes and `nix-command`;
- Nix store optimisation and scheduled garbage collection;
- server administration and diagnostic packages;
- Podman as the OCI-container backend;
- Docker command compatibility through Podman;
- weekly Podman pruning;
- reusable service framework with Homepage disabled by default;
- GitHub Actions validation.

Deliberately not configured yet:

- disk partitioning and filesystems;
- `hardware-configuration.nix`;
- static IP addressing;
- hardware acceleration;
- public DNS and TLS;
- encrypted secrets;
- backups;
- application services;
- automatic system upgrades.

These items will be added after the physical PC and its storage are inspected.

## Repository structure

```text
.
├── .github/
│   └── workflows/
│       └── nix-validate.yml
├── hosts/
│   └── homelab/
│       ├── default.nix
│       └── services.nix
├── modules/
│   ├── homelab/
│   │   └── default.nix
│   ├── services/
│   │   ├── default.nix
│   │   └── homepage.nix
│   ├── base.nix
│   ├── containers.nix
│   ├── networking.nix
│   ├── ssh.nix
│   ├── storage.nix
│   └── users.nix
├── flake.nix
├── LICENSE
└── README.md
```

Files added later on the NixOS PC:

```text
flake.lock
hosts/homelab/hardware-configuration.nix
```

## Configuration model

`flake.nix` defines one NixOS configuration:

```nix
nixosConfigurations.homelab
```

`hosts/homelab/default.nix` selects the modules and contains host-specific values such as:

```nix
networking.hostName = "homelab";
nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
system.stateVersion = "26.05";
```

The reusable homelab module defines:

```text
homelab.enable
homelab.user
homelab.group
homelab.timeZone
homelab.domain
homelab.paths.state
homelab.paths.data
homelab.paths.backups
homelab.containers.enable
homelab.services.enable
homelab.services.homepage.enable
```

Current default paths are:

```text
/srv/homelab   application configuration and state
/srv/data      media and application data
/srv/backups   local backup storage
```

The directories are created declaratively with systemd tmpfiles rules.

## Development workflow on macOS

Nix does not need to be installed on the Mac.

Make changes on the feature branch:

```bash
cd ~/Developer/nix-homelab
git switch feature/homelab-platform
git pull --ff-only
```

Review local changes:

```bash
git status
git diff
git diff --check
```

Commit only the intended files:

```bash
git add path/to/changed-file
git diff --cached
git commit -m "Describe the change"
git push
```

GitHub Actions parses all `.nix` files and evaluates important NixOS options on an Ubuntu runner.

Temporary helper scripts used to create or modify files should be deleted before committing.

## First deployment on the NixOS PC

These steps assume:

- NixOS is installed and booting;
- the repository has been cloned;
- the shell is in the repository root;
- local console access is available.

Do not perform the first activation only over SSH. Keep a local console available in case networking, firewall, user, or SSH settings are incorrect.

### 1. Clone the repository

During development, clone the feature branch:

```bash
git clone \
  --branch feature/homelab-platform \
  https://github.com/VPuljic/nix-homelab.git

cd nix-homelab
```

After the branch is merged, clone the default branch instead.

Confirm the checkout:

```bash
git branch --show-current
git status
```

### 2. Add the hardware configuration

If the NixOS installation already created `/etc/nixos/hardware-configuration.nix`, copy it:

```bash
cp /etc/nixos/hardware-configuration.nix \
  hosts/homelab/hardware-configuration.nix
```

Otherwise, generate it from the running PC:

```bash
sudo nixos-generate-config --show-hardware-config \
  > hosts/homelab/hardware-configuration.nix
```

Confirm that the file is not empty:

```bash
test -s hosts/homelab/hardware-configuration.nix
```

Open `hosts/homelab/default.nix` and uncomment:

```nix
./hardware-configuration.nix
```

Stage the new file because Git-backed flakes do not see untracked files:

```bash
git add hosts/homelab/hardware-configuration.nix
git add hosts/homelab/default.nix
```

### 3. Generate the lock file

`flake.lock` is repository-specific, not hardware-specific. It pins the exact Nixpkgs revision used by the server.

Create it during the first deployment:

```bash
test -f flake.lock || nix flake lock
test -s flake.lock
git add flake.lock
```

Do not run `nix flake update` during the first deployment. That command is for deliberately updating already locked inputs later.

### 4. Review machine-specific settings

Check the architecture:

```bash
uname -m
```

The current configuration expects:

```text
x86_64
```

Review these values in `hosts/homelab/default.nix`:

```nix
networking.hostName = "homelab";
nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
system.stateVersion = "26.05";
```

`system.stateVersion` should represent the release used for the first managed installation. Do not increase it during ordinary upgrades.

Review the administrative user in `modules/users.nix`:

```text
vp
```

Set a local password if required:

```bash
sudo passwd vp
```

Add only a public SSH key to the repository:

```nix
openssh.authorizedKeys.keys = [
  "ssh-ed25519 AAAA... workstation-key"
];
```

Never commit private keys, plaintext passwords, API tokens, recovery codes, or other secrets.

### 5. Inspect networking

The initial configuration uses NetworkManager and DHCP.

Inspect the real machine:

```bash
ip -brief link
ip -brief address
ip route
nmcli device status
nmcli connection show
```

Static addressing, bridges, VLANs, bonds, and server-specific DNS should be configured only after the actual network is known.

### 6. Validate the flake

Inspect the flake:

```bash
nix flake metadata
nix flake show
```

The output should contain:

```text
nixosConfigurations.homelab
```

Run the checks:

```bash
nix flake check
```

Confirm key values:

```bash
nix eval \
  .#nixosConfigurations.homelab.config.networking.hostName \
  --raw
echo

nix eval \
  .#nixosConfigurations.homelab.config.system.stateVersion \
  --raw
echo
```

Expected values:

```text
homelab
26.05
```

### 7. Build without activation

```bash
sudo nixos-rebuild build --flake .#homelab
```

A successful build creates a `result` symlink. It is ignored by Git and must not be committed.

### 8. Test temporarily

```bash
sudo nixos-rebuild test --flake .#homelab
```

Verify the essentials:

```bash
hostnamectl
id vp
nmcli device status
ip -brief address
ip route
systemctl status sshd --no-pager
systemctl --failed
ss -lntup
```

Verify Podman:

```bash
podman version
podman info
docker --version
```

No application containers are defined yet, so `podman ps` should normally show no running containers:

```bash
podman ps
```

From another computer on the same LAN, test SSH while keeping the local console open:

```bash
ssh vp@SERVER_IP_ADDRESS
```

Do not disable password authentication until public-key login has been tested successfully.

### 9. Activate permanently

After the temporary test succeeds:

```bash
sudo nixos-rebuild switch --flake .#homelab
```

Verify:

```bash
nixos-version
hostnamectl
systemctl is-active sshd
systemctl --failed
```

Reboot once:

```bash
sudo reboot
```

After reconnecting:

```bash
hostnamectl
systemctl --failed
```

### 10. Commit the machine configuration

Review the staged files:

```bash
git status
git diff --cached
```

Commit and push:

```bash
git commit -m "Add homelab machine configuration"
git push
```

This commit should include:

```text
flake.lock
hosts/homelab/hardware-configuration.nix
hosts/homelab/default.nix
```

Review the hardware configuration before publishing it.

## Normal update workflow

After changing the configuration on the server:

```bash
git diff
nix flake check
sudo nixos-rebuild build --flake .#homelab
sudo nixos-rebuild test --flake .#homelab
sudo nixos-rebuild switch --flake .#homelab
```

Then commit only the tested change:

```bash
git status
git add path/to/changed-file
git diff --cached
git commit -m "Describe the homelab change"
git push
```

## Deploying changes created on the Mac

On the NixOS server:

```bash
cd /path/to/nix-homelab
git status
git pull --ff-only
nix flake check
sudo nixos-rebuild test --flake .#homelab
sudo nixos-rebuild switch --flake .#homelab
```

`git pull --ff-only` stops instead of creating an unexpected merge commit when histories have diverged.

## Updating Nixpkgs

Once `flake.lock` is committed, updates are deliberate repository changes:

```bash
git status
nix flake update
nix flake check
sudo nixos-rebuild build --flake .#homelab
sudo nixos-rebuild test --flake .#homelab
sudo nixos-rebuild switch --flake .#homelab
```

After testing:

```bash
git add flake.lock
git commit -m "Update flake inputs"
git push
```

Do not change `system.stateVersion` as part of a routine input update.

## Rollback and recovery

Rollback the current system when it is still usable:

```bash
sudo nixos-rebuild switch --rollback
```

List system generations:

```bash
sudo nix-env \
  --list-generations \
  --profile /nix/var/nix/profiles/system
```

If the machine does not boot, choose an earlier NixOS generation in the bootloader menu.

After recovery:

```bash
git status
git log --oneline --decorate -n 10
```

Fix or revert the repository change before deploying again.

## Useful diagnostics

```bash
# Failed units
systemctl --failed

# Current-boot warnings
journalctl -b -p warning

# SSH logs
journalctl -u sshd -b

# Networking
nmcli device status
ip -brief address
ip route

# Podman
podman info
podman ps --all
systemctl status podman-auto-prune.service --no-pager

# Current NixOS generation
readlink -f /run/current-system
nixos-version

# Flake information
nix flake metadata
nix flake show
```

## Planned implementation order

The next phases will be added gradually:

1. encrypted secret management;
2. storage design after inspecting the real disks;
3. backup and restore workflow;
4. LAN and optional Tailscale access;
5. Caddy reverse proxy;
6. first lightweight dashboard and monitoring services;
7. media and document services one at a time.

Services from the reference homelab—such as Jellyfin, Immich, Paperless-ngx, Vaultwarden, Nextcloud, Homepage, and the media automation stack—will be considered individually rather than enabled together.

## References

- [NixOS manual](https://nixos.org/manual/nixos/stable/)
- [Nix language basics](https://nix.dev/tutorials/nix-language.html)
- [Nix flakes](https://nix.dev/concepts/flakes.html)
- [MyNixOS](https://mynixos.com/)
- [Reference homelab configuration](https://git.notthebe.ee/notthebee/nix-config)
