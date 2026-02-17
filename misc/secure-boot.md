# Secure Boot explained

## New install? *Unless directed otherwise*, just go to this link: [Two options are available](#two-options-are-available) for what to do next.



---------------------------------------
A quick run down about Secure Boot
---------------------------------------
### Secure Boot is a feature of modern UEFI firmware that ensures only trusted software, signed by a recognized authority, can execute during the boot process. This is particularly useful for preventing certain types of attacks, such as bootkits and rootkits, which can compromise a system at the firmware or bootloader level.

> If you are unsure, leave it enabled as it is defaulted to in the BIOS. It's a method of securing the boot process that can be left as is unless you have the need to disable it.



### On the other side of the coin, secure Boot can block unsigned kernels from running during the boot process, which may include:

**1.Custom Kernels and Bootloaders:**

- If you build your own kernel or use a custom bootloader like GRUB, it must be signed with a key that Secure Boot recognizes, or it won't boot.

**2.Third-Party Drivers:**

- Some proprietary drivers might not work unless they are signed and compatible with Secure Boot.

**3. Live USB keys with Linux ISOs:**

-_Some_ live Linux USB ISOs, especially custom-built ones, may fail to boot unless Secure Boot is disabled or the bootloader is properly signed.

**4. Kernel Modules:**

- Unsigned kernel modules or modules not signed with a key recognized by Secure Boot will not load. This can affect hardware drivers or custom software that relies on kernel extensions.

**5. Alternative Boot Methods:**

- Secure Boot may interfere with hibernate resuming from cold boot (unsigned kernels for example), and with certain alternative boot methods (e.g., PXE boot) or older bootloaders.
Hibernation behavior with Secure Boot varies by distribution. Kernel lockdown mode, which is enforced when Secure Boot is enabled, can interfere with hibernate/resume on some setups. 

> Remember. We advise leaving Secure Boot enabled — disabling it may affect unsigned kernel modules, third-party drivers, and certain alternative boot methods. If you dual-boot Windows, do not disable Secure Boot.

### How to disable it if you choose to.
(Remember, this is a choice - if you are going to be dual-booting Windows, do not disable secure boot - just go to this link instead to get your distro setup: [Two options are available](#two-options-are-available) for what to do next instead of disabling unless support has suggested you do so for testing.)

**On AMD Ryzen 7040 Series / Intel Core Ultra:**

- Boot into BIOS by tapping F2 just before the Framework splash screen.

- Arrow down to Administer Secure Boot. Press enter.

- Arrow down to Enforce Secure Boot. Press enter, select Disabled, press enter.

- Press F10 to save and reboot. With Yes selected, press Enter.

**On 13th Gen:**

- Boot into BIOS by tapping F2 just before the Framework splash screen.

- Arrow down to Administer Secure Boot. Press enter.

- Arrow down to Enforce Secure Boot. Press enter, select Disabled, press enter.

- Press F10 to save and reboot. With Yes selected, press Enter.

**On 12th Gen:**

- Boot into BIOS by tapping F2 just before the Framework splash screen.

- Left arrow over to Security. 

- Arrow all the way down to Secure Boot. Press enter.

- Select Enforce Secure Boot, press enter, select Disable, press enter.

- Press F10 to save and reboot. With Yes selected, press Enter.

**On 11th Gen:**

- Boot into BIOS by tapping F2 just before the Framework splash screen.

- Left arrow over to Security. 

- Arrow all the way down to Secure Boot. Press enter.

- Select Enforce Secure Boot, press enter, select Disable, press enter.

- Press F10 to save and reboot. With Yes selected, press Enter.

--------------

## Machine Owner Key Enrollment (MOK)

MOK is part of the Secure Boot mechanism that ensures only trusted code can run during the boot process.

- Purpose: Secure Boot authentication
- What it does: Allows the system to load signed kernel modules and drivers when Secure Boot is enabled
- When you use it: When installing third-party drivers (like NVIDIA) or custom kernel modules on a system with Secure Boot enabled
- Level of operation: Boot process (firmware/UEFI level)
- User interaction: Usually only when installing drivers or enrolling new keys

If you have secure boot enabled, you will see something asking you to enroll MOK. 

## Two options are available:

- If this is a new install and you can choose Continue Boot - that's it!

![Enroll MOK](https://raw.githubusercontent.com/FrameworkComputer/linux-docs/refs/heads/main/misc/images/MOK.jpeg)

- Enroll MOK (You are looking at something involving proprietary modules, VirtualBox built with DKMS for example)

  -   [Enrolling MOK with Fedora](https://docs.fedoraproject.org/en-US/quick-docs/mok-enrollment/)
  -   [Enrolling MOK with Bazzite](https://docs.bazzite.gg/General/Installation_Guide/secure_boot/)
  -   [Enrolling MOK with Ubuntu](https://wiki.ubuntu.com/UEFI/SecureBoot)
