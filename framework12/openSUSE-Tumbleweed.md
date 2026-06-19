# Tablet Mode and Screen Rotation on openSUSE Tumbleweed (Framework Laptop 12)

This guide enables the full tablet experience on the Framework Laptop 12 running
openSUSE Tumbleweed: automatic screen rotation, keyboard/touchpad disabling when
folded, and an on-screen keyboard.

Tablet mode is made up of three independent pieces:

1. **Tablet-mode switch detection** — folding the screen back fires a
   `SW_TABLET_MODE` event. libinput (and the firmware) then disables the
   keyboard and touchpad.
2. **Automatic screen rotation** — `iio-sensor-proxy` reads the accelerometer
   and passes orientation to the desktop over D-Bus; the compositor rotates the
   display and remaps touch/pen input.
3. **Touch UI / on-screen keyboard** — provided by the desktop environment.

The kernel and sensor plumbing is the same regardless of desktop. The rotation
and on-screen keyboard behaviour differs between GNOME and KDE, and between X11
and Wayland — see the desktop sections below.

> **Short version for KDE users:** install `iio-sensor-proxy` and
> `maliit-keyboard`, **log in to the Plasma (Wayland) session**, select Maliit
> as the virtual keyboard, and set Wayland as your default. X11 will not
> auto-rotate.

---

## 1. Kernel modules

Tablet-mode detection and the accelerometer depend on two modules:

```
lsmod | grep -E 'pinctrl_tigerlake|soc_button_array'
```

Expected output (the counts may differ):

```
soc_button_array       24576  0
pinctrl_tigerlake      28672  5
```

On openSUSE Tumbleweed both are built as loadable modules and autoload, so this
normally needs no action. If `pinctrl_tigerlake` is missing, force it to load:

```
echo pinctrl_tigerlake | sudo tee /etc/modules-load.d/framework12.conf
```

---

## 2. Install iio-sensor-proxy

```
sudo zypper install iio-sensor-proxy
rpm -q iio-sensor-proxy
```

Version **3.7** has a bug that prevents it from delivering accelerometer events
to userspace (GNOME, KDE, …). Tumbleweed currently ships **3.8 or newer**, so
the bug does not affect you and **no workaround is required**.

Only if `monitor-sensor` (next step) shows the proxy appearing but orientation
never changing, apply the udev workaround that comments out the problematic rule:

```
sed 's/.*iio-buffer-accel/#&/' /usr/lib/udev/rules.d/80-iio-sensor-proxy.rules \
  | sudo tee /etc/udev/rules.d/80-iio-sensor-proxy.rules
sudo udevadm trigger --settle
sudo systemctl restart iio-sensor-proxy
```

---

## 3. Verify the accelerometer

```
monitor-sensor --accel
```

Tilt the laptop from side to side. You should see orientation and tilt lines
appear:

```
    Waiting for iio-sensor-proxy to appear
+++ iio-sensor-proxy appeared
=== Has accelerometer (orientation: normal)
    Accelerometer orientation changed: normal
    Tilt changed: vertical
```

If orientation changes as you move the laptop, the sensor stack is working.

---

## 4. Verify the tablet-mode switch

```
sudo libinput debug-events
```

Fold the screen back into tablet posture, then forward again. You should see the
switch toggle on the `gpio-keys` device:

```
 event2   SWITCH_TOGGLE   switch tablet-mode state 1   # folded into tablet
 event2   SWITCH_TOGGLE   switch tablet-mode state 0   # folded back to laptop
```

`state 1` is what triggers keyboard/touchpad disabling and, in tablet-aware
desktops, the touch UI.

---

## 5. Desktop environment

### KDE Plasma

**Use the Wayland session.** Automatic rotation and the tablet UI are
Wayland-only features in Plasma. KWin's X11 backend was feature-frozen years ago
and never gained accelerometer-driven rotation, so on **X11 nothing will rotate**
no matter how healthy the sensor stack is.

Log out and pick **Plasma (Wayland)** at the SDDM session selector. Rotation then
follows the accelerometer automatically and the touchscreen/stylus are remapped
to match. Rotation options live in **System Settings → Display & Monitor**,
including "rotate only in tablet mode", which uses the switch from step 4.

#### On-screen keyboard (Plasma Wayland)

Plasma ships with no virtual-keyboard backend selected, so nothing pops up by
default. Install Maliit:

```
sudo zypper install maliit-keyboard
```

Then **System Settings → Keyboard → Virtual Keyboard** (labelled "Screen
keyboard" on Plasma 6.6+) → select **Maliit Keyboard**. Log out and back in.

Notes:

- The keyboard only auto-appears when a text field is focused **and** the device
  is in tablet posture (`tablet-mode state 1`). In laptop mode it stays hidden.
- There is also a manual toggle in the system tray.
- If the dropdown is empty after installing Maliit, relog (or reboot) so the
  input-method plugin registers.
- Plasma 6.6+ also has a native "Plasma Keyboard" option in the same dropdown;
  Maliit remains the more battle-tested choice on convertibles.

#### Stylus / pen (Plasma Wayland)

The Framework 12's built-in stylus is configured in the native Wayland Drawing
Tablet module: **System Settings → Drawing Tablet (Zeichentablett) → Pen
(Stift)**. (This is a Wayland-only KCM; on X11 you'd need the older
`wacomtablet` module instead — another reason to stay on Wayland.)

Useful options on the **Pen/Stift** page:

- **Button mapping** — reassign each stylus button to a mouse click
  (right/middle), a key combination or modifier, or disable it entirely.
- **Pressure curve** — adjust the curve that maps physical pen pressure to
  logical pressure, for apps like Krita; you can also limit the usable pressure
  range.
- **Tap to execute** — when enabled, a button action only fires while the pen
  tip is touching the screen; disable it to allow actions while hovering.

Related controls live alongside the Pen page in the same module:

- **Tablet tester** — shows live pressure and tilt so you can confirm the pen
  is working as expected.
- **Calibration** — corrects parallax on the built-in display; worth running
  once on the Framework 12 so the cursor lands exactly under the pen tip.
- **Screen mapping / orientation** — keep the pen mapped to the internal
  display; orientation follows auto-rotate, so you normally leave this alone.

Power users can script the same settings from the command line with
`ktabletconfig`.

### GNOME

GNOME on Wayland auto-rotates and shows its on-screen keyboard once
`iio-sensor-proxy` is delivering events — no extra packages needed.

---

## 6. Make Wayland the default session

openSUSE ships patches that bias the default/auto-login session toward Plasma
**X11** (the `default.desktop` symlink under `/usr/share/xsessions/` points at an
X11 session). SDDM otherwise remembers the **last session you logged into, per
user**, so simply logging into Wayland usually makes it your default going
forward.

Confirm which session you are in:

```
echo $XDG_SESSION_TYPE   # should print: wayland
```

If you use **autologin** and it keeps reverting to X11, pin the session. First
check the exact session file names (they vary by packaging):

```
ls /usr/share/wayland-sessions/ /usr/share/xsessions/
```

On current Tumbleweed the Wayland session is `plasmawayland.desktop`. Set it via
the GUI — **System Settings → Startup and Shutdown → Login Screen (SDDM) →
Behavior** → "Automatically log in" → session = **Plasma (Wayland)** — or with a
config file `/etc/sddm.conf.d/10-session.conf`:

```
[Autologin]
User=YOUR_USERNAME
Session=plasmawayland.desktop
```

Avoid repointing the `default.desktop` symlink by hand; package updates will
overwrite it.

---

## Known issues

- **Keyboard/touchpad not re-enabling when leaving tablet mode.** Some Framework
  12 units do not restore the keyboard and touchpad after folding back to laptop
  posture. Keep the BIOS current via `fwupd`/LVFS, as this has been partly
  addressed in firmware.
- **X11 + KDE will not auto-rotate.** This is by design (KWin X11 is
  feature-frozen) and cannot be fixed in configuration. Use Wayland, or a
  third-party rotation daemon such as `rot8` if you must stay on X11.

---

## Quick reference

| Component            | Package / location                       | Check                                   |
|----------------------|------------------------------------------|-----------------------------------------|
| Kernel modules       | `pinctrl_tigerlake`, `soc_button_array`  | `lsmod \| grep -E 'pinctrl_tigerlake\|soc_button_array'` |
| Accelerometer daemon | `iio-sensor-proxy` (≥ 3.8)               | `monitor-sensor --accel`                |
| Tablet switch        | kernel / `gpio-keys`                     | `sudo libinput debug-events`            |
| Rotation             | Plasma **Wayland** / GNOME Wayland       | rotate the device                       |
| On-screen keyboard   | `maliit-keyboard`                        | focus a text field in tablet mode       |
| Stylus / pen         | Drawing Tablet KCM (**Wayland**)         | System Settings → Zeichentablett → Stift |
| Default session      | SDDM last-session / autologin config     | `echo $XDG_SESSION_TYPE`                |
