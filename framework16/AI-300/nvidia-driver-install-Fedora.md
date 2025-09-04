# NVIDIA dGPU Driver Installation for Fedora

Your Framework Laptop 16 with Ryzen AI 300 series CPU includes an option for an optioonal discrete NVIDIA GPU module. On a fresh Fedora installation, the open-source nouveau driver is automatically detected and ready for basic display functionality. However, for gaming performance, hardware video encoding/decoding (NVENC/NVDEC), CUDA compute workloads, and optimal dGPU utilization, you'll need the proprietary NVIDIA driver from RPM Fusion.

## Installing NVIDIA Drivers for Gaming and Intensive Tasks

**Update system and install NVIDIA proprietary drivers with hardware acceleration**

Open up a terminal window, paste in the follow line below followed by the enter key and your Fedora login password when asked.

```sudo dnf update -y && sudo dnf install akmod-nvidia xorg-x11-drv-nvidia-cuda-libs nvtop```

*Once it's completed, reboot the laptop*

**Once booted back into your laptop, verify installation with:**

`modinfo -F version nvidia`

This will tell you your installed NVIDIA driver version.

You're NVIDIA driver is installed and ready for dGPU enabled Steam gaming, compute tasks, NVENC GPU rendering for video editors, etc.

### How to determine if your dGPU is active

[Install and run nvtop](https://github.com/FrameworkComputer/linux-docs/blob/main/framework16/AI-300/graphics-usage-detection.md#discrete-graphics-usage-detection). Your dGPU will be clearly labled at the top of the terminal output. You will only see activitity from nvtop for the dDPU when Steam gaming or when a workload is calling upon the dGPU to run.



### Important
- We recommend using the dnf installation method step listed above under "Installing NVIDIA Drivers for Gaming and Intensive Tasks". Building the driver yourself or deviating from this at all whill yield varied results that are not something we tested agaist for this guide.
- When seeking support from the support team at Framework, we will be verifying you followed these directions. This is the driver handling method the support team has vetted as working and reliable.

## Next Steps - Steam Gaming with NVIDIA
Continue with [Gaming on Steam](https://github.com/FrameworkComputer/linux-docs/blob/main/framework16/AI-300/Gaming-on-Steam-dGPU-Fedora.md#gaming-on-steam)


### Troubleshooting

Q: dGPU is not doing anything or does not seem to be working? 
A: Did you run the modinfo command above to verify your detecting the nvidia driver? You understand that not all applciations use the dGPU, even when pressed into service to do so. Browsers and other applications will not use the dGPU as there is no reason to do so.

Q: The dGPU worked previously, ran updates, now it is not working anymore, what happened?
A: Assuming you used to the NVIDIA driver command provided above, did not try enabling rawhide or building it yourself with other means outside of the instructions provided, we would want you to open a support ticket in case a regression has been introduced in akmod-nvidia.

Q: The NVIDIA module is installed as outlined from the dGPU installation guide, but there is question as to whether it's actually being detected at all?
A: From a temrinal, run the modinfo command listed above under "verify installation with" - also, you can make sure the dGPU is physicaly seen as present with this terminal command:

```sudo dnf install lshw -y && sudo lshw -C display```
(The NVIDIA dGPU should appear as "product: GeForce RTX 5070 Series.")

Q: Still having issues and need help?
A: Please open [a support ticket](https://framework.kustomer.help/contact/support-request-ryon9uAuq). 
