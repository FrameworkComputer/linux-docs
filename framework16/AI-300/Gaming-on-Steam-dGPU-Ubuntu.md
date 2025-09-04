## Gaming on Steam on Ubuntu

**Prerequisites:** You must first have NVIDIA drivers installed. If you selected **"Install third-party software for graphics and Wi-Fi hardware"** during Ubuntu installation, this is already done. Otherwise, install drivers via Settings → Additional Drivers.

Once the NVIDIA driver is installed, your Framework Laptop 16's NVIDIA dGPU graphics automatically manages GPU usage. The integrated AMD graphics handle desktop tasks and light workloads for optimal battery life, while the discrete NVIDIA GPU automatically activates for demanding applications like games, 3D rendering, and compute tasks. This seamless switching ensures maximum performance when gaming while preserving battery life during regular use.

**Install Steam via Official .deb Package**

1. Download the Steam .deb package from https://store.steampowered.com/about/
2. Click "Install Steam" → "Download Steam for Linux"
3. Open your Downloads folder, double-click the .deb file
4. Ubuntu Software will open, click "Install"
5. Enter your password when prompted


### Storage Configuration

**Single NVMe Drive**  
If using only the main system drive, no additional configuration is needed. Steam will install games to your home directory by default.

### Second NVMe Drive Configuration

**Script-Based Configuration (Recommended)**  
If you used the [Steam Drive Mounter script](https://github.com/FrameworkComputer/steam-drive-mounter/blob/main/README.md#steam-drive-mounter) for automated setup, the drive mounts with your username in the path.

>If using mounter script linked above for secondary drive, skip Advanced Manual Configuration.

**Advanced Manual Configuration**  
For manual setup of your second NVMe drive:

1. Open Disks application, label the drive as `steamgames`, and format to Ext4. Close Disks.

2. Open Terminal and create the mount point:

`cd /media && sudo mkdir steamgames`

3. Set correct ownership and permissions:

```sudo chown $USER:$USER steamgames/ && sudo chmod 700 steamgames/```

4. Verify the setup:

```ls -ld steamgames/```

You should see: `drwx------. 1 youruser youruser 0 Month day 00:00 steamgames/`

5. Find your drive's UUID:

```sudo blkid | grep 'steamgames' | awk '{print $0}'```

Look for the UUID in the output: `UUID="xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"`

6. Backup fstab and edit it:

```sudo cp /etc/fstab /etc/fstab.bak && sudo nano /etc/fstab```

7. Add this line to the bottom (using YOUR UUID):

```UUID=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx   /media/steamgames  ext4  rw,users,exec,auto  0 0```

8. Save with Ctrl+X, then Y, and reboot.

### Mounter script or manual method completion

After reboot, add the drive in Steam:
  - Open Steam → Settings → Storage
  - Click "Local Drive" pulldown menu
  - Click "Add Drive" and navigate to /media/steamgames or /media/YourUser/steamgames
  - Make your selection.

-----------

## Troubleshooting

### Steam Won't Launch or Crashes
**Check NVIDIA driver status:**

`nvidia-smi`

If this fails, go to Settings → Additional Drivers and install the **recommended** NVIDIA driver. It will be _labled as recommended_.

**Reinstall Steam:**

`sudo apt remove steam`

1. Open your Downloads folder, double-click the .deb file
2. Ubuntu Software will open, click "Install"
3. Enter your password when prompted


### Games Using Integrated Graphics Instead of NVIDIA dGPU
**Verify NVIDIA is detected:**

`glxinfo | grep "OpenGL renderer"`

Should show NVIDIA GPU information.


### Steam Can't See Second NVMe Drive
**Verify mount is working:**

`df -h | grep steamgames`

`ls -la /media/steamgames`

**Check permissions:**

`sudo chown -R $USER:$USER /media/steamgames`

**Restart Steam completely:**
Close Steam, then in terminal:

`killall steam`

`steam`

### Poor Game Performance
**Check GPU usage during gaming:**

`nvtop`

GPU usage should be high (70%+) when gaming.

**Install gamemode for optimized performance:**

Run using the best power mode: In GNOME, upper right, pull down menu of your desktop where you would power off your system. Look for "Power Mode", enable it for performance.

### Controller Not Working
**Install controller support:**

`sudo apt install steam-devices`

**Test controller detection:**

`sudo apt install evtest`

`evtest`

Your controller should appear in the list.

**Restart Steam after connecting controller:**
Some controllers require Steam to be restarted after connection.

### Game Won't Start or Black Screen
- **Check Proton compatibility:** Try different Proton versions in Steam → Settings → Compatibility.

- **Clear shader cache:** Steam → Settings → Shader Pre-Caching → Clear Cache

- **Check Wayland compatibility:** Some games work better on X11. Log out and select "GNOME on Xorg" at login.


### Audio Issues in Games
**Check PulseAudio/PipeWire status:**

`systemctl --user status pipewire`

**Restart audio services:**

`systemctl --user restart pipewire pipewire-pulse`

### Need More Help?
1. Generate system info: Steam → Help → Steam Runtime Diagnostics (provide to Framework support)
3. Check game-specific issues on [ProtonDB](https://www.protondb.com/)
5. Visit Framework Community forums with your system info and specific error messages
6. Check for Steam updates: Steam menu → Check for steam client updates.

