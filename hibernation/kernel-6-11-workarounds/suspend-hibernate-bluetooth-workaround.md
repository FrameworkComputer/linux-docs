# Workaround for suspend/hibernate black screen on resume kernel 6.11

- Issue: Bluetooth on kernel 6.11 causes black screen on resume attempt.
- Workaround provides two systemd services. First one rfkills bluetooth when suspend or hibernate is detected. Second service re-activates Bluetooth upon resume.

### Install Curl

Curl should already be installed, but just in case:

### Fedora
```
sudo dnf install curl -y
```

or

### Ubuntu
```
sudo apt install curl -y
```

------------------------------------------------------------------------------------------------------------------------------

## To Install rfkill-suspender Script, simply run:

```
curl -s https://raw.githubusercontent.com/FrameworkComputer/linux-docs/refs/heads/main/hibernation/kernel-6-11-workarounds/rfkill-suspender.sh -o rfkill-suspender.sh && clear && bash rfkill-suspender.sh
```

Running the script in the future
After the install, you can run going forward with the following in the HOME directory. So merely opening a terminal and running this will work if the original script has not been moved.

```
bash rfkill-suspender.sh
```

## To remove the services installed

```
sudo systemctl stop bluetooth-rfkill-suspend.service
```

```
sudo systemctl disable bluetooth-rfkill-suspend.service
```

```
sudo systemctl stop bluetooth-rfkill-resume.service
```

```
sudo systemctl disable bluetooth-rfkill-resume.service
```

```
sudo rm /etc/systemd/system/bluetooth-rfkill-suspend.service
```

```
sudo rm /etc/systemd/system/bluetooth-rfkill-resume.service
```

```
sudo systemctl daemon-reload
```
