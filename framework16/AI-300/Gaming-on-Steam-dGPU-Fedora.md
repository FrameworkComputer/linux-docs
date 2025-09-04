## Gaming on Steam

**Prerequisites:** You must first install the NVIDIA driver following the [NVIDIA dGPU Driver Installation guide](https://github.com/FrameworkComputer/linux-docs/blob/main/framework16/AI-300/nvidia-driver-install-Fedora.md#nvidia-dgpu-driver-installation-for-fedora).

Once the NVIDIA driver is installed, your Framework Laptop 16's NVIDIA dGPU graphics automatically manages GPU usage. The integrated AMD graphics handle desktop tasks and light workloads for optimal battery life, while the discrete NVIDIA GPU automatically activates for demanding applications like games, 3D rendering, and compute tasks. This seamless switching ensures maximum performance when gaming while preserving battery life during regular use.

Flatpak is the tested and recommended installation method for Steam. If you encounter issues using alternative installation methods, the support team will direct you back to this Flatpak approach shown below for troubleshooting.


**Install Steam via Flatpak**
```
flatpak install flathub com.valvesoftware.Steam
```

**Enable game controller support**
```
sudo dnf install steam-devices
```

### Storage Configuration

**Single NVMe Drive**  
If using only the main system drive, no additional configuration is needed. Steam will install games to your home directory by default.

### Second NVMe Drive Configuration

**Script-Based Configuration (Recommended)**  
If you used the [Steam Drive Mounter script](https://github.com/FrameworkComputer/steam-drive-mounter/blob/main/README.md#steam-drive-mounter) for automated setup, the drive mounts with your username in the path. 

Next, replace `YourUserName` with your actual Fedora login name:

```
flatpak override --user --filesystem=/media/YourUserName/steamgames com.valvesoftware.Steam
```

**Advanced Manual Configuration**  
For manual setup of your second NVMe drive:

1. Open Disks program, label the drive as `steamgames`, and format to Ext4. Close Disks.

2. Open Terminal and create the mount point:
```
cd /media && sudo mkdir steamgames
```

3. Set correct ownership and permissions:
```
sudo chown $USER:$USER steamgames/ && sudo chmod 700 steamgames/
```

4. Verify the setup:
```
ls -ld steamgames/
```
You should see: `drwx------. 1 youruser youruser 0 Month day 00:00 steamgames/`

5. Find your drive's UUID:
```
sudo blkid | grep 'steamgames' | awk '{print $0}'
```
Look for the UUID in the output: `UUID="xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"`

6. Backup fstab and edit it:
```
sudo cp /etc/fstab /etc/fstab.bak && sudo nano /etc/fstab
```

7. Add this line to the bottom (using YOUR UUID):
```
UUID=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx   /media/steamgames  ext4  rw,users,exec,auto  0 0
```

8. Save with Ctrl+X, then Y, and reboot.

9. Configure Flatpak permissions:
```
flatpak override --user --filesystem=/media/steamgames com.valvesoftware.Steam
```

### NVIDIA Driver Maintenance

After any NVIDIA driver update, update the Flatpak NVIDIA runtime to maintain compatibility:

```
flatpak update org.freedesktop.Platform.GL.nvidia
```

-----------

## Troubleshooting

### Steam Won't Launch or Crashes
**Check NVIDIA driver status:**
```
nvidia-smi
```
If this fails, reinstall the NVIDIA driver following the prerequisites guide.

**Update Flatpak NVIDIA runtime:**
```
flatpak update org.freedesktop.Platform.GL.nvidia
```

**Reset Steam's Flatpak data:**
```
flatpak uninstall --delete-data com.valvesoftware.Steam
flatpak install flathub com.valvesoftware.Steam
```

### Games Using Integrated Graphics Instead of NVIDIA dGPU
**Verify NVIDIA is detected:**
```
glxinfo | grep "OpenGL renderer"
```
Should show NVIDIA GPU information.

### Steam Can't See Second NVMe Drive
**Verify mount is working:** 
Remember, path will be determined if you did the [secondary NVME setup maunally or not](#second-nvme-drive-configuration).
```
df -h | grep steamgames
ls -la /media/steamgames
```

**Check Flatpak permissions:**
```
flatpak override --user --show com.valvesoftware.Steam
```
Should list your steamgames filesystem path.

**Restart Steam completely:**
```
flatpak kill com.valvesoftware.Steam
```
Then relaunch Steam.

### Poor Game Performance
**Check GPU usage during gaming:**
(Might need to [install it first](https://github.com/FrameworkComputer/linux-docs/blob/main/framework16/AI-300/graphics-usage-detection.md#discrete-graphics-usage-detection))
```
nvtop
```
GPU usage should be high (70%+) when gaming.

**Run using the best power mode:**
In GNOME, upper right, pull down menu of your desktop where you would power off your system. Look for "Power Mode", enable it for performance.

### Controller Not Working
**Check if steam-devices is installed:**
```
rpm -qa | grep steam-devices
```

**Test controller detection:**
You will need to install evtest first: _sudo dnf install evtest_

```
evtest
```
Your controller should appear in the list.

**Restart Steam after connecting controller:**
Some controllers require Steam to be restarted after connection.

### Game Won't Start or Black Screen
- **Check Proton compatibility:**
Try different Proton versions in Steam → Settings → Compatibility.

- **Clear shader cache:**
Steam → Settings → Shader Pre-Caching → Clear Cache

- **Check Wayland compatibility:**
Some games work better on X11. Log out and select "GNOME on Xorg" at login.

### Audio Issues in Games
**Check PipeWire status:**
```
systemctl --user status pipewire
```

**Restart audio services:**
```
systemctl --user restart pipewire pipewire-pulse
```

### Need More Help?
1. Check the [Steam Flatpak FAQ](https://github.com/flathub/com.valvesoftware.Steam/wiki/)
2. Generate system info: Steam → Help → System Information
3. Check game-specific issues on [ProtonDB](https://www.protondb.com/)
4. Updated your drivers recently? Make sure flatpak is also up to date _flatpak update org.freedesktop.Platform.GL.nvidia_
5. Visit Framework Community forums with your system info and specific error messages
6. Check for Steam updates: _flatpak update com.valvesoftware.Steam_
