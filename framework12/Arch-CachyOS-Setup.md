# This is for Framework Laptop 12 (Intel Core Series 3) ONLY
## Arch and CachyOS

### This assumes KDE Plasma is your selected desktop
### This assumes an Arch-based distro running KDE Plasma (e.g. CachyOS or Arch)

## This will:

- Get your laptop fully updated.
- Enable tablet rotation mode.
- Install and enable the on-screen (touch) keyboard.

---

### Step 1 — Update your software packages

- Open a terminal and run:

```
sudo pacman -Syu
```

- Let it finish completely. **Never interrupt an update partway through.**
- **If the update installed a new kernel, reboot now** before moving on.

---

### Step 2 — Enable tablet rotation mode

Tablet rotation needs two things: the **sensor daemon** (`iio-sensor-proxy`) that reads the accelerometer, and a **module load-order fix** so the tablet-mode switch is detected.

#### 2a. Install the sensor daemon

**This is where Arch and CachyOS differ. Follow the section for your distro.**

**If you are on Arch:**

- `iio-sensor-proxy` is **not** installed by default. Install it:

```
sudo pacman -S iio-sensor-proxy
```

**If you are on CachyOS:**

- It may already be present. Check first:

```
pacman -Qs iio-sensor-proxy
```

- If that returns a result, it's installed — move on to 2b.
- If it returns nothing, install it:

```
sudo pacman -S iio-sensor-proxy
```

> Without this package, KDE's auto-rotate option stays greyed out — the module fix below is not enough on its own.

#### 2b. Create the modprobe file

*(Same for both Arch and CachyOS.)*

```
sudo nano /etc/modprobe.d/99-fw-tabletmode.conf
```

Paste in:

```
softdep soc_button_array pre: pinctrl_intel_platform
```

- Save and exit: press **Ctrl+O**, then **Enter**, then **Ctrl+X**.

#### 2c. Edit the mkinitcpio config

```
sudo nano /etc/mkinitcpio.conf
```

- Find the line that starts with `MODULES=()`.
- Add `pinctrl_intel_platform` inside the parentheses:
  - If the line is **empty**, make it exactly:

```
MODULES=(pinctrl_intel_platform)
```

  - If it **already has modules listed**, add ours to the end, space-separated. Example:

```
MODULES=(existing_module pinctrl_intel_platform)
```

- Save and exit: press **Ctrl+O**, then **Enter**, then **Ctrl+X**.

#### 2d. Rebuild the initramfs

```
sudo mkinitcpio -P
```

#### 2e. Reboot

- **Tablet rotation will not work until you reboot.**

#### 2f. Verify the sensor is detected

- After rebooting, run:

```
monitor-sensor --accel
```

- If it's working, you'll see a line confirming an accelerometer was found, and the readings change as you tilt the laptop. Press **Ctrl+C** to stop.
- Screen rotation should now work when you flip into tablet mode.

---

### Step 3 — Install and enable the on-screen keyboard

The touch keyboard for KDE Plasma is **Plasma Keyboard**.

**1. Check whether it's already installed:**

```
pacman -Qs plasma-keyboard
```

- If it lists a result, it's already installed — skip to enabling it below.

**2. If it's not installed, install it:**

```
sudo pacman -S plasma-keyboard
```

**3. Enable it in KDE:**

- Open **System Settings**.
- Go to **Keyboard → Virtual Keyboard**.
- Select **Plasma Keyboard**.
- Click **Apply**.

**4. Log out and back in** (or reboot) so KDE picks up the keyboard.

---

### Good to know

- **Future updates won't undo this.** Your edits live in `/etc/mkinitcpio.conf` and `/etc/modprobe.d/`, which updates don't overwrite. New kernels automatically rebuild the initramfs using your settings — you do **not** need to redo these steps.
- You only need to re-run `sudo mkinitcpio -P` if **you** change one of these config files yourself.
- `iio-sensor-proxy` and the keyboard selection also persist across updates — no need to reinstall or re-enable them.

---
---
---

# This is for Framework Laptop 12 (13th Gen Intel Core) ONLY
## Arch and CachyOS

### This assumes KDE Plasma is your selected desktop
### This assumes an Arch-based distro running KDE Plasma (e.g. CachyOS or Arch)

## This will:

- Get your laptop fully updated.
- Enable tablet rotation mode.
- Install and enable the on-screen (touch) keyboard.

---

### Step 1 — Update your software packages

- Open a terminal and run:

```
sudo pacman -Syu
```

- Let it finish completely. **Never interrupt an update partway through.**
- **If the update installed a new kernel, reboot now** before moving on.

---

### Step 2 — Enable tablet rotation mode

Tablet rotation needs two things: the **sensor daemon** (`iio-sensor-proxy`) that reads the accelerometer, and a **module load-order fix** so the tablet-mode switch is detected.

#### 2a. Install the sensor daemon

**This is where Arch and CachyOS differ. Follow the section for your distro.**

**If you are on Arch:**

- `iio-sensor-proxy` is **not** installed by default. Install it:

```
sudo pacman -S iio-sensor-proxy
```

**If you are on CachyOS:**

- It may already be present. Check first:

```
pacman -Qs iio-sensor-proxy
```

- If that returns a result, it's installed — move on to 2b.
- If it returns nothing, install it:

```
sudo pacman -S iio-sensor-proxy
```

> Without this package, KDE's auto-rotate option stays greyed out — the module fix below is not enough on its own.

#### 2b. Create the modprobe file

*(Same for both Arch and CachyOS.)*

```
sudo nano /etc/modprobe.d/99-fw-tabletmode.conf
```

Paste in:

```
softdep soc_button_array pre: pinctrl_tigerlake
```

- Save and exit: press **Ctrl+O**, then **Enter**, then **Ctrl+X**.

#### 2c. Edit the mkinitcpio config

```
sudo nano /etc/mkinitcpio.conf
```

- Find the line that starts with `MODULES=()`.
- Add `pinctrl_tigerlake` inside the parentheses:
  - If the line is **empty**, make it exactly:

```
MODULES=(pinctrl_tigerlake)
```

  - If it **already has modules listed**, add ours to the end, space-separated. Example:

```
MODULES=(existing_module pinctrl_tigerlake)
```

- Save and exit: press **Ctrl+O**, then **Enter**, then **Ctrl+X**.

#### 2d. Rebuild the initramfs

```
sudo mkinitcpio -P
```

#### 2e. Reboot

- **Tablet rotation will not work until you reboot.**

#### 2f. Verify the sensor is detected

- After rebooting, run:

```
monitor-sensor --accel
```

- If it's working, you'll see a line confirming an accelerometer was found, and the readings change as you tilt the laptop. Press **Ctrl+C** to stop.
- Screen rotation should now work when you flip into tablet mode.

---

### Step 3 — Install and enable the on-screen keyboard

The touch keyboard for KDE Plasma is **Plasma Keyboard**.

**1. Check whether it's already installed:**

```
pacman -Qs plasma-keyboard
```

- If it lists a result, it's already installed — skip to enabling it below.

**2. If it's not installed, install it:**

```
sudo pacman -S plasma-keyboard
```

**3. Enable it in KDE:**

- Open **System Settings**.
- Go to **Keyboard → Virtual Keyboard**.
- Select **Plasma Keyboard**.
- Click **Apply**.

**4. Log out and back in** (or reboot) so KDE picks up the keyboard.

---

### Good to know

- **Future updates won't undo this.** Your edits live in `/etc/mkinitcpio.conf` and `/etc/modprobe.d/`, which updates don't overwrite. New kernels automatically rebuild the initramfs using your settings — you do **not** need to redo these steps.
- You only need to re-run `sudo mkinitcpio -P` if **you** change one of these config files yourself.
- `iio-sensor-proxy` and the keyboard selection also persist across updates — no need to reinstall or re-enable them.
