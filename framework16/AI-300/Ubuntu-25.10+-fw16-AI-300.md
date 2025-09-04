# Framework Laptop 16 (AMD Ryzen™ AI 300 Series) ONLY
### For Ubuntu 25.10 and greater recommended
(Ubuntu 25.10 is exected in Oct of 2025)

## This will:

- Get your laptop fully updated
- Install NVIDIA CUDA toolkit for machine learning, LLMs, and AI workloads
- Install GPU monitoring tools

&nbsp;
&nbsp;
&nbsp;

### Important: During Ubuntu Installation

When installing Ubuntu, if you followed our guide, you remembered to enable **"Install third-party software for graphics and Wi-Fi hardware"** as this will automatically handled the NVIDIA driver installation for you.

&nbsp;
&nbsp;
&nbsp;

### Step 1: Update System and Install CUDA Support

- Open Terminal
- Copy the code below in the gray box, right click/paste it into the terminal window
- Then press the enter key, enter your user password, press enter key, **reboot**

```
sudo apt update && sudo apt upgrade -y && sudo apt install nvidia-cuda-toolkit nvtop
```

>**Note:** While CUDA (nvidia-cuda-toolkit) is optional, if you are entertaining using local LLMs (AI tools), use the default command which includes nvidia-cuda-toolkit.

**Reboot your system after this completes**

&nbsp;
&nbsp;
&nbsp;

### Step 2: Enable Fractional Scaling on Wayland (Optional)

- Click on the top right corner, select Settings
- Navigate to "Displays"
- Look for "Scale", set it to your preference (125%, 150%, 175%, or 200%), click Apply

&nbsp;
&nbsp;
&nbsp;

### Step 3: Enable "Tap-to-Click" on the Touchpad (Optional)

- Click on the top right corner, select Settings
- Navigate to "Mouse & Touchpad"
- Under "Touchpad" section, toggle on "Tap to Click"

### Bonus Step: Reduce Font Scaling (For Former Mac Users)

For users coming from macOS, installing GNOME Tweaks and adjusting font scaling may provide a more familiar experience:

- Go to Displays, set scaling to 200% (this will look too large initially)
- Install GNOME Tweaks:
  
```
sudo apt update && sudo apt install gnome-tweaks -y
```

- Open Tweaks by pressing the "Super" (Windows) key, search "tweaks", and press enter
- At the top, select "Fonts". Scroll down to find "Scaling Factor"
- Change from 1.00 to 0.80, then close Tweaks

**Note:** This scaling adjustment is optimized for the laptop display only and may not look optimal on external monitors.

&nbsp;

------------------------------------

## Verify NVIDIA driver installation

`modinfo -F version nvidia`

This will tell you your installed NVIDIA driver version.

**Your NVIDIA driver is installed and ready for dGPU enabled Steam gaming, compute tasks, NVENC GPU rendering for video editors, etc.**

### How to determine if your dGPU is active

Run nvtop from the terminal. Your dGPU will be clearly labled at the top of the terminal output. You will only see activitity from nvtop for the dDPU when Steam gaming or when a workload is calling upon the dGPU to run.

`nvtop`



### Important
- We recommend using the installation method step listed under "Install third-party software for graphics and Wi-Fi hardware." Building the driver yourself or deviating from this at all whill yield varied results that are not something we tested agaist for this guide.
- When seeking support from the support team at Framework, we will be verifying you followed these directions. This is the driver handling method the support team has vetted as working and reliable.

## Next Steps - Steam Gaming with NVIDIA

Continue with [Gaming on Steam](https://github.com/FrameworkComputer/linux-docs/blob/main/framework16/AI-300/Gaming-on-Steam-dGPU-Ubuntu.md#gaming-on-steam-on-ubuntu)

-----------------
-----------------
&nbsp;
&nbsp;
