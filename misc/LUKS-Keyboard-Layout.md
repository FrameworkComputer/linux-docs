# ⚠️ Known Limitation: LUKS Keyboard Layout

> ⚠️ **Important for non-US keyboard users:**  
> The keyboard layout selected during installation is not used for the LUKS unlock screen. Regardless of your selection during the installation process, the keyboard layout available for the LUKS unlock screen will default to `en-US` (English - United States of America).  
>  
> This means characters on your keyboard may produce different letters than expected when typing your passphrase at boot time.

---

## During Installation

To avoid problems unlocking your system after installation:
- Consider setting a disk encryption passphrase that only uses characters that are in the same position on both your keyboard layout and the US layout
- Avoid special characters that may be in different positions across keyboard layouts

> 💡 **Simplest solution:**  
> - **Use a passphrase made only of numbers and/or letters A–Z.**  
> - These characters are almost always in the same position across all keyboard layouts and will work reliably at the unlock screen.

---

## After Installation – First Boot

> ✅ **You can skip this section if:**  
> You used the **simplest passphrase** — only **letters A–Z and/or numbers 0–9**,  
> and you are able to unlock your encrypted disk without any issues.  
>  
> 🎉 You're all set — **no further changes are necessary.**

---

> ⚠️ **Follow the instructions below if:**  
> - You use **special characters** in your passphrase, **or**  
> - Your keyboard layout is **not en-US**, and  
> - You **cannot reliably enter your passphrase** at the LUKS unlock screen.

Follow the steps below based on your Linux distribution to permanently apply your keyboard layout during early boot:

---

### ✅ For Atomic desktops (Silverblue, Kinoite, Bazzite, Bluefin):

```bash
# 1. Set your desired keymap in /etc/vconsole.conf
# Replace 'de' with your actual layout (e.g., fr, uk, colemak)
echo 'KEYMAP=de' | sudo tee /etc/vconsole.conf

# 2. Track the file so it gets included in future initramfs builds
sudo rpm-ostree initramfs-etc --track=/etc/vconsole.conf

# 3. Regenerate the initramfs now so the change applies immediately
sudo dracut -f

# 4. Reboot to apply the updated initramfs and keyboard layout
sudo reboot
```

---

### ✅ For Fedora Workstation and other traditional RPM-based systems:

```bash
# 1. Set your desired keymap in /etc/vconsole.conf
sudo nano /etc/vconsole.conf
# Example content:
# KEYMAP=de

# 2. Rebuild the initramfs
sudo dracut -f

# 3. Reboot to apply the updated layout
sudo reboot
```

---

### ✅ For Ubuntu and Ubuntu-based systems:

```bash
# 1. Edit the keyboard configuration file
sudo nano /etc/default/keyboard
# Example: XKBLAYOUT="de"

# 2. Optionally reconfigure to regenerate supporting files
sudo dpkg-reconfigure keyboard-configuration

# 3. Rebuild the initramfs
sudo update-initramfs -u

# 4. Reboot to apply the changes
sudo reboot
```

Once your system reboots, your chosen keymap will be applied during the early boot process and at the LUKS unlock screen. You can then safely change your disk encryption passphrase using GNOME Disks or a terminal tool like `cryptsetup` if desired.

---

## 🛠️ If You Can't Boot (Emergency Recovery)

If you're unable to enter your passphrase correctly at the LUKS unlock screen due to the wrong keymap, you can temporarily set the correct layout from the GRUB menu:

---

### ✅ For Fedora-based systems (Atomic or traditional):

1. At the GRUB boot menu, press `e` to edit the boot entry  
2. Find the line starting with `linux` (the longest line)  
3. Add this to the end of the line:
   ```
   rd.vconsole.keymap=de
   ```
   Replace `de` with your desired layout  
4. Press `Ctrl+X` or `F10` to boot  
5. After logging in, follow the permanent fix steps above to make it persist

---

### ✅ For Ubuntu-based systems:

1. Boot into **Recovery Mode** from the GRUB menu  
2. Select **"Drop to root shell prompt"**  
3. Remount the filesystem with write permissions:
   ```bash
   mount -o remount,rw /
   ```
4. Edit the keyboard layout:
   ```bash
   nano /etc/default/keyboard
   ```
5. (Optional) Reconfigure the keyboard:
   ```bash
   dpkg-reconfigure keyboard-configuration
   ```
6. Rebuild the initramfs:
   ```bash
   update-initramfs -u
   ```
7. Reboot:
   ```bash
   reboot
   ```

---

## 📘 Additional Notes

- To list available keymaps:
  ```bash
  localectl list-keymaps | grep -i <lang>
  ```

- These changes affect the **initramfs environment** (LUKS unlock screen and early boot TTYs). Once your desktop session starts, it will follow the layout defined in your user settings.

---

This guide ensures your keymap is fully and correctly applied across all boot stages and system variants.
