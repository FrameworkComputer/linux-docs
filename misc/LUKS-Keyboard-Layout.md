
# ⚠️ Known Limitation — LUKS Keyboard Layout

> ⚠️ **Important for non‑US keyboard users:**  
> The keyboard layout selected during installation is **not** used for the LUKS unlock screen. The early‑boot environment defaults to **`en‑US`**.  
> As a result, the keys you press may produce different characters when you enter your passphrase at boot.

---

## During Installation
- Choose a passphrase you can type on **both** US‑QWERTY *and* your local layout, **or**  
- Use only **A–Z** and **0–9** (keys that do not change position).

> 💡 **Simplest solution:** use a passphrase made **only** of letters A–Z and/or numbers 0–9. These keys map the same on nearly every layout and will always work at the unlock prompt.

---

## After Installation (first boot)

> ✅ **Skip the entire section below** if you used only A–Z/0‑9 **and** you can already unlock successfully.

### ✅ Fedora Atomic desktops  
*(Silverblue / Kinoite / Bazzite / Bluefin …)*

    # 1 Write your keymap
    echo 'KEYMAP=de' | sudo tee /etc/vconsole.conf

    # 2 Track that file so every future deployment includes it
    sudo rpm-ostree initramfs-etc --track=/etc/vconsole.conf

    # 3 Rebuild the initramfs now *and* enable automatic rebuilds
    sudo rpm-ostree initramfs --enable

    # 4 (Optional but harmless) force a dracut run on the current deployment
    sudo dracut -f

    # 5 Reboot
    sudo reboot

---

### ✅ Fedora Workstation / Server (traditional RPM systems)

    sudo nano /etc/vconsole.conf          # add or edit: KEYMAP=de
    sudo dracut -fv --regenerate-all      # rebuild every installed kernel
    sudo reboot

---

### ✅ Ubuntu & Debian‑based systems

    sudo nano /etc/default/keyboard       # e.g. XKBLAYOUT="de"
    sudo dpkg-reconfigure keyboard-configuration   # interactive; rebuilds current initrd
    sudo update-initramfs -u -k all                 # rebuild all other initrds
    sudo reboot

---

### ✅ Arch Linux & derivatives

    echo 'KEYMAP=de' | sudo tee /etc/vconsole.conf
    sudo sed -i 's/^HOOKS=.*/HOOKS=(base udev autodetect modconf kms keyboard keymap encrypt filesystems)/' /etc/mkinitcpio.conf
    sudo mkinitcpio -P                       # rebuild every preset
    sudo reboot

---

## 🛠️ Emergency Unlock (if the keymap is wrong)

### Fedora / Atomic
1. At the GRUB menu press **e**.  
2. Append `rd.vconsole.keymap=de` to the end of the `linux` line.  
3. Boot with **Ctrl + X** or **F10**.  
4. After login, apply the permanent fix above.

### Ubuntu family

    # At GRUB choose “Recovery Mode → root shell”
    mount -o remount,rw /
    nano /etc/default/keyboard            # set XKBLAYOUT="de"
    update-initramfs -u -k all
    reboot

---

## 📘 Helpful Commands

    # List available keymaps
    localectl list-keymaps | grep -i <lang>

    # Verify your map is embedded in the current initrd
    lsinitramfs /boot/initrd.img-$(uname -r) | grep kmap

Once these steps are complete, your chosen layout is active at the LUKS prompt, early TTYs, and Plymouth. Your desktop environment continues to use the layout configured in GNOME, KDE, etc.
