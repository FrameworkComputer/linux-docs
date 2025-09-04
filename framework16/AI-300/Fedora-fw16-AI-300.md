# Framework Laptop 16 (AMD Ryzen™ AI 300 Series) ONLY

## This will:

- Get your laptop fully updated
- Enable improved fractional scaling support in Fedora's GNOME environment using Wayland
- Enable tap to click on the touchpad
- Prepare your system for gaming with hardware dGPU support as the next step (end of this article)

&nbsp;
&nbsp;
&nbsp;

### Step 1: Update Your Software Packages

- Browse to the horizontal line in the upper left corner, click to open it
- Type out the word "terminal", click to open it  
- Copy the code below in the gray box, right click/paste it into the terminal window
- Then press the enter key, enter your user password, press enter key, **reboot**

```
sudo dnf upgrade -y
```
> **TIP:** You can use the little clipboard icon to the right of the code to copy to your clipboard.

**Reboot your system after this completes**

&nbsp;
&nbsp;
&nbsp;

### Step 2: Enable Fractional Scaling on Wayland (Optional)

- Browse to the horizontal line in the upper left corner, click to open it
- Type out the word "Displays"
- Look for "Scale", set it to your preference, click Apply

&nbsp;
&nbsp;
&nbsp;

### Step 3: Enable "Tap-to-Click" on the Touchpad (Optional)

- Browse to the horizontal line in the upper left corner, click to open it
- Type out the word "mouse", look for "Mouse and Touchpad", click to open it
- Click the touchpad option at the top
- Under "Clicking", select "Tap to Click" and enable it
  
&nbsp;
&nbsp;
&nbsp;

### Bonus Step: Reduce Font Scaling (For Former Mac Users)

For users coming from macOS, installing GNOME Tweaks and adjusting font scaling may provide a more familiar experience:

- Go to Displays, set scaling to 200% (this will look too large initially)
- Install GNOME Tweaks:
  
```
sudo dnf install gnome-tweaks -y
```

- Open Tweaks by pressing the "Super" (Windows) key, search "tweaks", and press enter
- At the top, select "Fonts". Scroll down to find "Scaling Factor"
- Change from 1.00 to 0.80, then close Tweaks

**Note:** This scaling adjustment is optimized for the laptop display only and may not look optimal on external monitors.

&nbsp;
&nbsp;
&nbsp;

## Next Steps - NVIDIA drivers

Continue with [installing NVIDIA drivers for Fedora](https://github.com/FrameworkComputer/linux-docs/blob/main/framework16/AI-300/nvidia-driver-install-Fedora.md#nvidia-dgpu-driver-installation-for-fedora).

&nbsp;
&nbsp;

----------------------------------------
----------------------------------------
