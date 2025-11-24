# Sops-Nix Cheat Sheet

This guide covers the essential commands for managing secrets in this NixOS configuration.

## Prerequisites

Ensure you have the necessary keys.

- **User Key (Master):** `~/.config/sops/age/keys.txt` (Back this up!)
- **System Key:** `/var/lib/sops-nix/key.txt` (Generated on install)

## Editing Secrets

To view or edit the encrypted `secrets/secrets.yaml` file:

```bash
sops secrets/secrets.yaml
```

This will open the decrypted file in your default editor (`$EDITOR`). When you save and quit, `sops` will automatically re-encrypt the file.

## Key Management

### Adding a New Machine

1.  **Get the new machine's public key:**
    On the new machine:

    ```bash
    sudo cat /var/lib/sops-nix/key.txt | age-keygen -y
    ```

    _(Or locate the public key in the generated output)_

2.  **Update configuration:**
    Add the new public key to the `.sops.yaml` file in this repository.

3.  **Rotate Keys:**
    Re-encrypt the secrets file to include the new key:
    ```bash
    sops updatekeys secrets/secrets.yaml
    ```

### Recovering/Restoring

If you are on a new machine and need to edit secrets:

1.  Place your backup **User Key** at `~/.config/sops/age/keys.txt`.
2.  Run `sops secrets/secrets.yaml`.

## NixOS Integration

### Accessing Secrets in Config

In `configuration.nix`:

```nix
sops.secrets.my_secret = {
  # Optional: owner, permissions, etc.
  # owner = "tbusby";
};
```

The secret will be available at `/run/secrets/my_secret`.

### Using Templates (NetworkManager, etc.)

To inject secrets into configuration files:

```nix
sops.templates."config-file" = {
  content = ''
    password=${config.sops.placeholder.my_secret}
  '';
  path = "/etc/some/config/file";
};
```

## Troubleshooting

**"Failed to get the data key"**

- Check if your key file exists: `ls -l ~/.config/sops/age/keys.txt`
- Check permissions: `chown tbusby:users ~/.config/sops/age/keys.txt`

**Secret not updating?**

- Did you run `sudo nixos-rebuild switch`?
- If it's a service config (like NetworkManager), did you reload the service?
