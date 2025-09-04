# Framework Laptop 16 (AMD Ryzen™ AI 300 Series) ONLY
### For Ubuntu 25.10 and greater recommended
(Ubuntu 25.10 is exected in Oct of 2025)

## This will:

- Get your laptop fully updated
- Install NVIDIA driver
- Install GPU monitoring tools

&nbsp;
&nbsp;
&nbsp;

### Important: During Ubuntu Installation

When installing Ubuntu, if you followed our guide, you remembered to enable **"Install third-party software for graphics and Wi-Fi hardware"** as this will automatically handle the NVIDIA driver installation for you.

&nbsp;
&nbsp;
&nbsp;

### Step 1: Update System and Install CUDA Support

- Open Terminal
- Copy the code below in the gray box, right click/paste it into the terminal window
- Then press the enter key, enter your user password, press enter key, **reboot**

```
sudo apt update && sudo apt upgrade -y && sudo apt install nvtop
```

>**Note:** ollama, text-generation-webui, vllm, oobabooga images that already bundle CUDA), so nothing needed here once your driver is installed.

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
&nbsp;
&nbsp;

-------------------------

## NVIDIA driver Troubleshooting

> **Q: What if the driver failed to install?**
>
> A: If you didn't install drivers during OS install or if that failed for some reason, [check this upstream documentation](https://documentation.ubuntu.com/server/how-to/graphics/install-nvidia-drivers/) for next steps to correct this.
>
>**Q: dGPU is not doing anything or does not seem to be working?**  
> A: Did you run nvidia-smi to verify you're detecting the nvidia driver? You understand that not all applications use the dGPU, even when pressed into service to do so. Browsers and other applications will not use the dGPU as there is no reason to do so.
>
> **Q: The dGPU worked previously, ran updates, now it is not working anymore, what happened?**  
> A: If you installed the NVIDIA driver through Additional Drivers as recommended, check if a kernel update has occurred. You may need to reboot or reinstall the driver through Additional Drivers. If issues persist, open a support ticket as a regression may have been introduced.
>
> **Q: The NVIDIA module is installed as outlined from the dGPU installation guide, but there is question as to whether it's actually being detected at all?**  
> A: From a terminal, run nvidia-smi to verify the driver is loaded. Also, you can make sure the dGPU is physically seen as present with this terminal command:
> 
> `sudo lshw -C display`
> 
> (The NVIDIA dGPU should appear as "product: GeForce RTX 5070 Series.")
>
> **Q: I'm using Secure Boot and the driver installation failed or isn't working properly. What should I do?**
>
> A: Ubuntu should automatically detect Secure Boot and use pre-signed kernel modules during installation. However, if this fails, follow these fallback steps:
>
> **Step 1: Completely remove all existing NVIDIA packages**
> ```
> # First, identify installed NVIDIA packages and their driver branch numbers
> apt-mark showmanual | grep nvidia
> 
> # Remove all NVIDIA packages (replace XXX with your driver branch number, e.g., 550)
> sudo apt --purge remove '*nvidia*XXX*'
> 
> # Clean up any remaining dependencies
> sudo apt autoremove
> ```
>
> **Step 2: Manually install the driver with Secure Boot support**
>
> For systems with Secure Boot enabled, use the pre-compiled signed kernel modules:
> ```
> # First, check available drivers
> sudo ubuntu-drivers list
> 
> # Install pre-compiled signed modules for your kernel
> # Replace XXX with your driver branch (e.g., 550)
> # Replace 'generic' with your kernel flavour if different
> sudo apt install linux-modules-nvidia-XXX-generic
> 
> # Verify modules were installed for your current kernel
> sudo apt-cache policy linux-modules-nvidia-XXX-$(uname -r)
> 
> # If not installed for current kernel, install specifically
> sudo apt install linux-modules-nvidia-XXX-$(uname -r)
> 
> # Finally, install the driver metapackage
> sudo apt install nvidia-driver-XXX
> 
> # Reboot your system
> sudo reboot
> ```
>
> After reboot, verify the installation with `nvidia-smi` and `modinfo -F version nvidia`.
>
> **Note:** The ubuntu-drivers tool is recommended for Secure Boot systems as it automatically handles signed drivers. Only use the manual method if the automatic installation fails.
>
> **Q: Still having issues and need help?**  
> A: Please open [a support ticket](https://framework.kustomer.help/contact/support-request-ryon9uAuq).
>
> **Q: But I need a simple, reliable, tested method for pushing other applications to the dGPU? Like video track editing for example.**
>
> A: It's ready, migrating from a hidden repo soon. Works flawlessly. Coming soon! RPM installed _compatible_ software, _compatible_ Flatpaks and even wrapper handling for _compatible_ AppImages. Do note however, GPU video rendering is done with the driver (using NVENC) and for this type of function, this application would **not** be needed.

**Coming soon!**
![COMING SOON - NVIDIA GPU Manager application interface showing GPU acceleration controls](https://raw.githubusercontent.com/FrameworkComputer/linux-docs/refs/heads/main/framework16/AI-300/images/NVIDIA-GPU-Manager-Ubuntu.png)

