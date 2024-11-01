
# Manual Guide: Configuring Lid Close and Hibernate Settings on Linux

This guide provides manual steps to configure lid-close and hibernate settings, install dependencies, and manage a GNOME extension for hibernation control.

**IMPORTANT:** This assumes you set up your partitions per our [instructions](https://github.com/FrameworkComputer/linux-docs/blob/main/hibernation/hibernate-fedora-automatic.md#access-partition-layout), first!

**NOTE:** - Secure boot needs to be disabled.

**NOTE:** If you feel strongly about using btrfs subvolumes, other approaches that are untested by us, below are some links for community guides on that front:

- [GUIDE] Framework 16 Hibernate (w/ swapfile) Setup on Fedora 40: [Read the full guide here](https://community.frame.work/t/guide-framework-16-hibernate-w-swapfile-setup-on-fedora-40/53080/1)
- [Guide] Fedora 36+: Hibernation with enabled secure boot and full disk encryption (FDE) decrypting over TPM2: [Read the guide here](https://community.frame.work/t/guide-fedora-36-hibernation-with-enabled-secure-boot-and-full-disk-encryption-fde-decrypting-over-tpm2/25474)
- Subvolume Btrfs Hibernate Approach: [Read more about this approach here](https://terminal.space/tech/hibernating-is-easy-now/).

Otherwise, the manual method of doing this is outlined below: [ Prefer an app? See the automatic method here](https://github.com/FrameworkComputer/linux-docs/blob/main/hibernation/hibernate-fedora-automatic.md#fedora-41-hibernation-option-not-fedora-official-beta).

---

## 1. Configure Hibernate using a swap partition

### Step 1: Create `/etc/systemd/sleep.conf` (if it doesn't exist)
   ```bash
   sudo touch /etc/systemd/sleep.conf
   ```

### Step 2: Install Additional Packages (if needed for hibernation)
   ```bash
   sudo dnf install -y audit policycoreutils-python-utils libnotify
   ```

### Step 3: Set Hibernate Parameters in `sleep.conf` (Optional)
   - Edit `/etc/systemd/sleep.conf` directly to add your desired hibernation settings without duplicating entries:
     ```ini
     [Sleep]
     HibernateDelaySec=600  # Adjust delay time in seconds
     ```

---

## 2. Manage GNOME Extension

### Install Extension

1. **Download the Hibernate Extension**:
    ```bash
    wget https://github.com/ctsdownloads/gnome-shell-extension-hibernate-status/archive/refs/heads/master.zip -O hibernate-extension.zip
    ```

2. **Unzip the Extension**:
    ```bash
    unzip hibernate-extension.zip -d ~/gnome-shell-extension-hibernate-status
    ```

3. **Install the Extension**:
    - Locate the `metadata.json` file in the unzipped folder and find the UUID (`hibernate-status@ctsdownloads`).
    - Move the extension to the GNOME extensions directory:
      ```bash
      mkdir -p ~/.local/share/gnome-shell/extensions/hibernate-status@ctsdownloads
      cp -r ~/gnome-shell-extension-hibernate-status/hibernate-status@ctsdownloads/* ~/.local/share/gnome-shell/extensions/hibernate-status@ctsdownloads
      ```

4. **Enable the Extension**:
    ```bash
    gnome-extensions enable hibernate-status@ctsdownloads
    ```

5. **Restart GNOME Shell** (Press **Alt+F2**, type `r`, and press **Enter**; this may not be available on Wayland, so a reboot may be required).

### Uninstall Extension

1. **Disable and Remove the Extension**:
    ```bash
    gnome-extensions disable hibernate-status@ctsdownloads
    rm -rf ~/.local/share/gnome-shell/extensions/hibernate-status@ctsdownloads
    ```

---

## 3. Set Suspend-then-Hibernate Time (Optional)

1. **Edit `sleep.conf` directly** to prevent duplicate entries:
    ```bash
    sudo nano /etc/systemd/sleep.conf
    ```
   Add or modify the following entry:
    ```ini
    [Sleep]
    HibernateDelaySec=600  # Adjust the delay time in seconds
    ```

---

## 4. Set Lid Close Action (Optional)

1. **Edit `logind.conf` manually**:
    ```bash
    sudo nano /etc/systemd/logind.conf
    ```
   Add or modify the following entry:
    ```ini
    [Login]
    HandleLidSwitch=suspend  # Replace `suspend` with `hibernate` if desired
    ```

---

## 5. Check Hibernation Settings

1. **Check Dependency Installation**:
    ```bash
    rpm -q python3-gobject polkit
    ```

2. **Check GNOME Extension Installation**:
    ```bash
    gnome-extensions list | grep hibernate-status
    ```

3. **Verify Suspend-then-Hibernate Time**:
    Check `/etc/systemd/sleep.conf` for the `HibernateDelaySec` entry.

4. **Verify Lid Close Action**:
    Check `/etc/systemd/logind.conf` for the `HandleLidSwitch` entry.

---

## 6. Address SELinux Blocks on Hibernation

If SELinux is preventing hibernation, you can use the following commands to create and apply a custom policy:

1. **Temporarily Set SELinux to Permissive Mode** (Optional, for testing):
    ```bash
    sudo setenforce 0
    ```

2. **Generate a Custom SELinux Policy for Hibernation**:
    ```bash
    sudo ausearch -m avc -ts recent | audit2allow -M hibernate_policy
    ```

3. **Apply the New SELinux Policy**:
    ```bash
    sudo semodule -i hibernate_policy.pp
    ```

4. **Re-enable SELinux Enforcing Mode** (if previously set to permissive):
    ```bash
    sudo setenforce 1
    ```

   Ensure `audit2allow` is installed by running:
   ```bash
   sudo dnf install -y policycoreutils-python-utils
   ```

---

### Note
Please reboot your system after making changes to ensure all configurations take effect.
