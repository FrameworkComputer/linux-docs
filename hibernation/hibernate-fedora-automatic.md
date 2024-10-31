# Fedora 41 hibernation option (NOT Fedora official) (BETA)
(Suspends to disk/powered off with saved state to partition)

**THIS GUIDE IS NOT COMPLETE, STILL ADDING MORE, LIKE THE RPM PACKAGE/SOURCE**

**Tested successfully on:**

- Framework Laptop 13 AMD Ryzen 7040 Series
- Framework Laptop 13 Intel® Core™ Ultra Series 1
- Framework laptop 16 AMD Ryzen 7040 Series

**Guide Sections:**

- [Partition Layout](#access-partition-layout)
- [Lid Close and Hibernate Settings Installation and Usage Guide](#lid-close-and-hibernate-settings-installation-and-usage-guide)

Hibernation to disk in Linux using a swap partition is a valuable feature for preserving your system's state while completely powering off the machine. 
It works by saving the contents of RAM to the swap partition and restoring it upon reboot. On modern laptops equipped with NVMe SSDs, hibernation and resume processes are significantly faster due to the high-speed read/write capabilities of NVMe drives. 
This enhanced performance makes hibernation a practical and efficient option for energy conservation and session continuity without compromising user experience.

**Note:** This is being released as a beta for user testing:

- While tested working great internally, users may have improvements and tweaks to make it better.
- COPR is coming for the released version. This is designed with Framework Laptops in mind, but, should work with any compatible laptop.
- If you are comfortable adjusting the partition settings suggested below, go for it - do understand if something fails to and you deviate fromt the layout, you will be asked to redo the partitions as suggested by support to verify your settings.
- As you enter partition sizes as stated below, the actual size allotted will differ as that is how partitioning works. This is fine. 



## Setting Up Partition Layout for Fedora Installation
<a id="access-partition-layout"></a>
### Partition Layout

1. During Fedora installation, access **System, Install Destination**.
2. Choose **Custom** partitioning and click **Done**.
3. Ignore the **Encrypt my Data** checkbox since we will handle encryption separately.


**NOTE:** If this is a drive without any partitions on it, you will see something like this:
[![Fresh Installation](https://raw.githubusercontent.com/FrameworkComputer/linux-docs/refs/heads/main/hibernation/images/1.png)](https://raw.githubusercontent.com/FrameworkComputer/linux-docs/refs/heads/main/hibernation/images/1.png)

If you have existing partitions, you will need to delete them. 

**Note:** Removing partitions means you are removing your data, make backups BEFORE making new partitions.

### Delete Existing Partitions

1. **Delete All Partitions** (except `sda`):
   - Select each partition and delete it, but be careful not to delete any partitions on `sda`.
2. **Expand Fedora Linux for x86_64**:
   - Click the `>` indicator next to Fedora Linux to expand the default layout.
   - You will see default partitions such as:
     - `/boot/efi` (600 MB)
     - `/boot` (1 GB)
     - `/` (rest of the drive)


### Reclaim Space from Root Partition

1. **Delete the Root Partition**:
   - Select `/` and click the `-` button to delete it.
   - Choose to delete all filesystems used by Fedora.

### Define New Partitions

1. **EFI System Partition** (Existing):
   - Identify the **EFI System Partition** in the list (usually on the NVMe drive).
   - Set the mount point to `/boot/efi`.
   - Click **Update Settings**.

2. **Create New Partitions**:

   - **/boot Partition**:
     - Click `+` to add a new partition.
     - Set the **Mount Point** to `/boot`.
     - Set the size to **1.2 GB**.
     - Click **Add mount point**.

   - **Swap Partition**:
     - Click `+` to add a swap partition.
     - Set **Device Type** to `Standard Partition`.
     - Set the **Mount Point** to `swap`.
     - Check the box to **Encrypt** the partition.
     - Set the size as **RAM x 1.5** (e.g., for 32 GB of RAM, use 48 GB, use Google to help - RAM x 1.5 =).
     - Click **Update Settings**.

   - **Root Partition (/)**:
     - Click `+` to add the root partition.
     - Set the **Mount Point** to `/`.
     - Set the **Size** to `1000000` (Shortcut. Using a large number ensures it will use the rest of the drive).
     - Click **Modify** and check the box to **Encrypt** the partition.
     - Click **Save**.


[![New Partition Layout](https://raw.githubusercontent.com/FrameworkComputer/linux-docs/refs/heads/main/hibernation/images/2.png)](https://raw.githubusercontent.com/FrameworkComputer/linux-docs/refs/heads/main/hibernation/images/2.png)

### Finalize Partitions

1. **Confirm Encryption Settings**:
   - After configuring the partitions, ensure that the device type shows `-` for encrypted partitions.
   - This can later be verified with `lsblk -o NAME,FSTYPE,MOUNTPOINT`.

2. **Finish Setup**:
   - Click **Done** upper right corner.
   - Set an **encryption password** when prompted.
   - Accept the **Summary of Changes** to apply the partition layout.



[![Enter Desired LUKS encryption passphrase](https://raw.githubusercontent.com/FrameworkComputer/linux-docs/refs/heads/main/hibernation/images/3.png)](https://raw.githubusercontent.com/FrameworkComputer/linux-docs/refs/heads/main/hibernation/images/3.png)



### Finish your install process


[![Begin Installation](https://raw.githubusercontent.com/FrameworkComputer/linux-docs/refs/heads/main/hibernation/images/installrun3.png)](https://raw.githubusercontent.com/FrameworkComputer/linux-docs/refs/heads/main/hibernation/images/installrun3.png)

1. **Click on Begin installation.**

[![Installation Continues](https://raw.githubusercontent.com/FrameworkComputer/linux-docs/refs/heads/main/hibernation/images/installrun4.png)](https://raw.githubusercontent.com/FrameworkComputer/linux-docs/refs/heads/main/hibernation/images/installrun4.png)

-----------------------------------------------
<a id="lid-close-and-hibernate-settings-installation-and-usage-guide"></a>
## Lid Close and Hibernate Settings Installation and Usage Guide


This guide provides step-by-step instructions to install and use the **Lid Close and Hibernate Settings** application, allowing you to configure lid-close actions, hibernation settings, and manage GNOME extensions on your system.

---

### Installation Steps

1. **Download the RPM Package**  
   [Download the latest RPM](https://github.com/FrameworkComputer/linux-docs/blob/main/hibernation/kernel-6-11-workarounds/suspend-hibernate-bluetooth-workaround.md#workaround-for-suspendhibernate-black-screen-on-resume-kernel-611)

   View the [release page](https://github.com/FrameworkComputer/suspend-then-hibernate-settings/releases/tag/Python) for more information.

2. **Install Using GNOME Software Center**  
   Double-click the downloaded RPM file. This will open the GNOME Software Center for installation.
   Follow the prompts in the Software Center to complete the installation.

[![Install Using GNOME Software Center](https://raw.githubusercontent.com/FrameworkComputer/linux-docs/refs/heads/main/hibernation/images/software-center.png)](https://raw.githubusercontent.com/FrameworkComputer/linux-docs/refs/heads/main/hibernation/images/software-center.png)


---

### Using Lid Close and Hibernate Settings

**NOTE:** If you suspsend or hibernate with Bluetooth enable and happen to be on kernel 6.11 or greater, Please use this [workaround](https://github.com/FrameworkComputer/linux-docs/blob/main/hibernation/kernel-6-11-workarounds/suspend-hibernate-bluetooth-workaround.md#workaround-for-suspendhibernate-black-screen-on-resume-kernel-611) (open in a new tab), then return to this step.

After installation, you can launch the application from your applications menu.

[![Launch from applications menu](https://raw.githubusercontent.com/FrameworkComputer/linux-docs/refs/heads/main/hibernation/images/installed1.png)](https://raw.githubusercontent.com/FrameworkComputer/linux-docs/refs/heads/main/hibernation/images/installed1.png)

### Available Features and Buttons

Each button in the **Lid Close and Hibernate Settings** application provides specific functions for managing your system’s suspend and hibernate settings.

[![Lid Close and Hibernate Settings](https://raw.githubusercontent.com/FrameworkComputer/linux-docs/refs/heads/main/hibernation/images/running1.png)](https://raw.githubusercontent.com/FrameworkComputer/linux-docs/refs/heads/main/hibernation/images/running1.png)


1. **Install Dependencies**  
   (**NOTE:** This is already installed, but this is offered just in case and as the software progresses, new stuff will be added.)
   Click **Install Dependencies** to ensure all necessary packages are installed. This will check and install any missing dependencies for hibernation functionality.

3. **Configure Hibernate**  
   Press **Configure Hibernate** to set up hibernation on your system. This button will handle configuration settings needed for hibernation support.

4. **Manage Hibernate Extension**  
   - **Step 1**: Click **Manage Hibernate Extension** and choose **Install Extension** to add the Hibernate Status extension to GNOME.
   - **Step 2**: After installation, **reboot your system**.
   - **Step 3**: Launch **Lid Close and Hibernate Settings** _again_ (not a typo, just a bug), click **Manage Hibernate Extension**, and choose **Install Extension** once more.  
   This double installation process ensures the extension is fully integrated into your GNOME desktop.
   NOTE: This a forked version of the gnome-shell-extension-hibernate-status GNOME extension. It is [hosted at this GitHub account](https://github.com/ctsdownloads/gnome-shell-extension-hibernate-status?tab=readme-ov-file#gnome-shell-extension-hibernate-status)
 while the application here is in beta and was forked to remove functions that were not needed for this process and to meet compatibility with GNOME 47 - at the time of the fork, it stopped at GNOME 46, which this fork addressed for 47.

[![Manage Hibernate Extension](https://raw.githubusercontent.com/FrameworkComputer/linux-docs/refs/heads/main/hibernation/images/hibernate-extension.png)](https://raw.githubusercontent.com/FrameworkComputer/linux-docs/refs/heads/main/hibernation/images/hibernate-extension.png)



5. **(Optional) Set Suspend-then-Hibernate Time**  
   Use this button to set a custom delay time in seconds for your system to transition from suspend to hibernate mode.

6. **(Optional) Set Lid Close Action**  
   Configure the action (Suspend or Hibernate) that occurs when your laptop lid is closed.

7. **(Optional) Check Hibernation Settings**  
   Press this button to review your current hibernation settings, dependency status, and the state of the Hibernate extension.

---

**Note:** No system reboot is required after using the application, except when prompted as part of the extension installation process.



