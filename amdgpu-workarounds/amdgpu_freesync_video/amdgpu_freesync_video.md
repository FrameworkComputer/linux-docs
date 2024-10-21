## amdgpu.freesync_video=1 parameter workaround Franework Laptop 16 ONLY
### For Framework Laptop 16 not providing all of the expected refresh rates in kernels 6.9 and up.

Note: Once this is resolved, we'll keep this posted but mark it resolved.
Please ONLY run this if you were told to by support or, you meet the following criteria:

- Ubuntu 24.10 or Fedora 40/41, kernels 6.9.x and HIGHER.
- Only run if you find the refresh rates that should be available are limited to 60 and 160.

**Example Before:**

![image](https://raw.githubusercontent.com/FrameworkComputer/linux-docs/refs/heads/main/amdgpu-workarounds/images/before.png)

**Example After the workaround:**

![image](https://raw.githubusercontent.com/FrameworkComputer/linux-docs/refs/heads/main/amdgpu-workarounds/images/after.png)




- **Ubuntu 24.10 Or for Ubuntu users on 6.9+ kernels - script grub workaround (most users)**
```
curl -s https://raw.githubusercontent.com/FrameworkComputer/linux-docs/refs/heads/main/amdgpu-workarounds/amdgpu_freesync_video/Ubuntu_amdgpu.freesync_video_workaround.sh -o Ubuntu_amdgpu.freesync_video_workaround.sh && clear && bash Ubuntu_amdgpu.freesync_video_workaround.sh
```

- Copy and paste the above into a terminal. Press return, user password, then once complete, reboot.

## Or if you prefer to do this manually on Ubuntu 24.10

**Ubuntu 24.10 manual method, no script for Ubuntu users on 6.9+ kernels - (advanced users)**

```
GRUB_CMDLINE_LINUX_DEFAULT="..........existing entries....amdgpu.freesync_video=1"
```

```
sudo update-grub
```

- Run the above, reboot.


**Fedora 40/41 grub workaround**

```
sudo grubby --update-kernel=ALL --args="amdgpu.freesync_video=1"
```

- Copy and paste the above into a terminal. Press return, user password, then once complete, reboot.
