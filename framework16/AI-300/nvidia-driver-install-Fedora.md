# NVIDIA dGPU Driver Installation for Fedora

Your Framework Laptop 16 with Ryzen AI 300 series CPU includes an option for an optioonal discrete NVIDIA GPU module. On a fresh Fedora installation, the open-source nouveau driver is automatically detected and ready for basic display functionality. However, for gaming performance, hardware video encoding/decoding (NVENC), CUDA compute workloads, and optimal dGPU utilization, you'll need the proprietary NVIDIA driver from RPM Fusion.

## Installing NVIDIA Drivers for Gaming and Intensive Tasks

**Update system and install NVIDIA proprietary drivers with hardware acceleration**

Open up a terminal window, paste in the follow line below followed by the enter key and your Fedora login password when asked.

```sudo dnf update -y && sudo dnf install akmod-nvidia xorg-x11-drv-nvidia-cuda-libs nvtop```

>**Note:** While CUDA (xorg-x11-drv-nvidia-cuda-libs) is optional, if you are entertaining using local LLMs (AI tools), use the default command which includes xorg-x11-drv-nvidia-cuda-libs. This allows LLMs to work correctly on Fedora.

### IMPORTANT: Secure Boot MOK Enrollment Process

**If your system has Secure Boot enabled (most modern systems do), you MUST complete the following steps:**

During the akmod-nvidia installation:
- Modules are compiled and signed automatically
- You'll be prompted to create a password - **REMEMBER THIS PASSWORD**
- The signing key is staged for enrollment on next boot

**After installation completes, reboot the laptop**

### Blue MOK Management Screen (Appears ONCE)

**This screen appears only ONCE before normal boot - DO NOT SKIP IT:**

1. Press any key when you see "Press any key to perform MOK management"
2. Select **Enroll MOK**
3. Select **Continue**
4. Select **Yes** to enroll the keys
5. Enter the password you created during installation
6. Select **Reboot**

**Once booted back into your laptop, verify installation with:**

`modinfo -F version nvidia`

This will tell you your installed NVIDIA driver version.

**Your NVIDIA driver is installed and ready for dGPU enabled Steam gaming, compute tasks, NVENC GPU rendering for video editors, etc.**

### How to determine if your dGPU is active

[Install and run nvtop](https://github.com/FrameworkComputer/linux-docs/blob/main/framework16/AI-300/graphics-usage-detection.md#discrete-graphics-usage-detection). Your dGPU will be clearly labled at the top of the terminal output. You will only see activitity from nvtop for the dDPU when Steam gaming or when a workload is calling upon the dGPU to run.



### Important
- We recommend using the dnf installation method step listed above under "Installing NVIDIA Drivers for Gaming and Intensive Tasks". Building the driver yourself or deviating from this at all whill yield varied results that are not something we tested agaist for this guide.
- When seeking support from the support team at Framework, we will be verifying you followed these directions. This is the driver handling method the support team has vetted as working and reliable.

## Next Steps - Steam Gaming with NVIDIA

Continue with [Gaming on Steam](https://github.com/FrameworkComputer/linux-docs/blob/main/framework16/AI-300/Gaming-on-Steam-dGPU-Fedora.md#gaming-on-steam)

-----------------
-----------------

## Troubleshooting

> **Q: dGPU is not doing anything or does not seem to be working?**  
> A: Did you run the modinfo command above to verify you're detecting the nvidia driver? You understand that not all applications use the dGPU, even when pressed into service to do so. Browsers and other applications will not use the dGPU as there is no reason to do so.
>
> **Q: The dGPU worked previously, ran updates, now it is not working anymore, what happened?**  
> A: Assuming you used the NVIDIA driver command provided above, did not try enabling rawhide or building it yourself with other means outside of the instructions provided, we would want you to open a support ticket in case a regression has been introduced in akmod-nvidia.
>
> **Q: The NVIDIA module is installed as outlined from the dGPU installation guide, but there is question as to whether it's actually being detected at all?**  
> A: From a terminal, run the modinfo command listed above under "verify installation with" - also, you can make sure the dGPU is physically seen as present with this terminal command:
> ```
> sudo dnf install lshw -y && sudo lshw -C display
> ```
> (The NVIDIA dGPU should appear as "product: GeForce RTX 5070 Series.")
>
> **Q: I missed/skipped the blue MOK enrollment screen and my NVIDIA driver isn't working. What happened and how do I fix it?**
>
> A: If you missed the MOK screen:
> - Your system booted normally using the Nouveau driver (fallback open-source driver)
> - You have a working desktop with basic graphics functionality
> - The NVIDIA driver is installed but WON'T load due to Secure Boot blocking unsigned modules
>
> **To fix a missed MOK enrollment:**
> 1. Open a terminal in your working session (currently using Nouveau)
> 2. Re-stage the signing key for enrollment:
> ```
> sudo mokutil --import /etc/pki/akmods/certs/public_key.der
> ```
> 3. Create a NEW password when prompted (remember this new password!)
> 4. Reboot your system:
> ```
> sudo reboot
> ```
> 5. The blue MOK screen will appear again - **DON'T MISS IT THIS TIME**
> 6. Follow the enrollment steps with your NEW password:
>    - Press any key when prompted
>    - Select **Enroll MOK**
>    - Select **Continue**
>    - Select **Yes**
>    - Enter your NEW password
>    - Select **Reboot**
>
> **After successful enrollment:**
> - System boots with NVIDIA driver working
> - Full GPU acceleration enabled
> - Future driver updates automatically signed with enrolled key
> - No more MOK prompts needed
>
> **Q: Still having issues and need help?**  
> A: Please open [a support ticket](https://framework.kustomer.help/contact/support-request-ryon9uAuq).
>
> **Q: But I need a simple, reliable, tested method for pushing other applications to the dGPU? Like video track editing for example.**
>
> A: It's ready, migrating from a hidden repo soon. Works flawlessly. Coming soon! RPM installed _compatible_ software, _compatible_ Flatpaks and even wrapper handling for _compatible_ AppImages. Do note however, GPU video rendering is done with the driver (using NVENC) and for this type of function, this application would **not** be needed.

**Coming soon!**
![COMING SOON - NVIDIA GPU Manager application interface showing GPU acceleration controls](https://raw.githubusercontent.com/FrameworkComputer/linux-docs/refs/heads/main/framework16/AI-300/images/NVIDIA-GPU-Manager.png)
