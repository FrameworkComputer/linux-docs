## Easy Effects for FW 16 and 13.

### Sourced from [this Arch wiki guide](https://wiki.archlinux.org/title/Framework_Laptop_16#Easy_Effects).
#### fw16-easy-effects.json is based on [amesb's fw16 EE profile.json](https://gist.github.com/amesb/cc5d717472d7e322b5f551b643ff03f4) and fw13-easy-effects.json is based on [Gracefu's Edits.json](https://github.com/cab404/framework-dsp/blob/master/config/output/Gracefu's%20Edits.json).

> It's worth noting, you can load these both up - even running one script after another is fine and will not overwrite anything. So if you want to compare fw13 vs fw16 scripts, you can. I find the fw16 option has more bass whereas the fw13 profile has more clarity. In other words, install both profiles with confidence that this is supported fully. It will attempt to install the flatpak twice, which is totally fine and won't change anything as it will sense the flatpak is already install and move on, installing the second sound profile.

## For Fedora users on their Framework Laptop 16:

### Automated method:

Ensure curl is installed:

```
sudo dnf install curl -y
```

Then paste this and press enter.

```
curl https://raw.githubusercontent.com/FrameworkComputer/linux-docs/main/easy-effects/Fedora-easy-effects-16-installer.sh | bash
```
\
\
\
**IMPORTANT:** Load the profile by clicking the "Presets" pulldown, then "Load profile" option as shown below.

![image](https://raw.githubusercontent.com/FrameworkComputer/linux-docs/main/easy-effects/images/fw16-easyeffects.png)

-----------------------

## For Fedora users on their Framework Laptop 13:

### Automated method:

Ensure curl is installed:

```
sudo dnf install curl -y
```

Then paste this and press enter.

```
curl https://raw.githubusercontent.com/FrameworkComputer/linux-docs/main/easy-effects/Fedora-easy-effects-13-installer.sh | bash
```
\
\
\
**IMPORTANT:** Load the profile by clicking the "Presets" pulldown, then "Load profile" option as shown below.

![image](https://raw.githubusercontent.com/FrameworkComputer/linux-docs/main/easy-effects/images/fw16-easyeffects.png)


--------------------------
## For Ubuntu users on their Framework Laptop 16:

### Automated method:

Ensure curl is installed:

```
sudo apt install curl -y
```

Then paste this and press enter.

```
curl https://raw.githubusercontent.com/FrameworkComputer/linux-docs/main/easy-effects/Ubuntu-easy-effects-16-installer.sh | bash
```

Then just load the profile by clicking the Load profile option as shown below.

![image](https://raw.githubusercontent.com/FrameworkComputer/linux-docs/main/easy-effects/images/ubuntu-easy-effects.png)

--------------------------
## For Ubuntu users on their Framework Laptop 13:

### Automated method:

Ensure curl is installed:

```
sudo apt install curl -y
```

Then paste this and press enter.

```
curl https://raw.githubusercontent.com/FrameworkComputer/linux-docs/main/easy-effects/Ubuntu-easy-effects-13-installer.sh | bash
```

Then just load the profile by clicking the Load profile option as shown below. Yes, the image below shows FW16, but the image is merely a visual aid. It will reflect the appropriate profile.

![image](https://raw.githubusercontent.com/FrameworkComputer/linux-docs/main/easy-effects/images/ubuntu-easy-effects.png)

--------------------------

## FAQ

- Can you run both of these to compare them?
> Yes, you can. Nothing is overwritten, it will just try to install the flatpack twice which is fine and affects nothing.

- Do you need to look for the profile once it's installed?
> Nope, just follow the image. It's browsed for you, just load it.

- I'd rather load this manually. How?
> We're going to recommend the automated method, but if you on our own, wish to do this:
> - Install Easy Effects.
> - Download the json file you wish to use.
> - Browse to it from the present menu.
