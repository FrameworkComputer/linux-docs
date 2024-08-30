
## Framework Laptop Fingerprint Readers with 01000320 Firmware Update Guide
### A step by step guide 
#### This assumes you are on a disro such as Ubuntu LTS or Fedora, and have libfprint version of **at least** v1.92.0 or newer. 

- Verify that this is in fact, firmare version 01000320.
- You must use a distro that is has a libfprint version of **at least** v1.92.0 or **newer**. Fully package updated Ubuntu LTS and Fedora Workstation will meet this requirement. Other distros, even based on these distros, may or may not. 
- You will need to open a terminal from your launcher, then paste in the provided lines of code to get validcation of firmware version, update it and so forth.
- The tiny icons on the right side of each code box allow you to easily click it, to copy the code. Then you can right click paste the code into the terminal. If it errors out, try Ctrl Shift V instead to paste.

- Let's check your firmware version, verify it's 01000320.

```
fwupdmgr get-devices | awk '/Fingerprint Sensor:/{flag=1} flag; /Device Flags:/{flag=0}'
```

- If it comes back with "Current version:    01000320", then continue with this guide.

- Making sure we are using the correct **GUID** from the output above:

- To verify you have the correct GUI, you can run this to verify it's correct with the output from this code:

```
fwupdmgr get-devices | awk '/Fingerprint Sensor:/{flag=1} flag; /Device Flags:/{flag=0}' | grep 'GUID:' | awk -F'GUID: ' '{print $2}' | awk '{print $1}'
```

The GUI should return with: 1e8c8470-a49c-571a-82fd-19c9fa32b8c3. With the GUID verified:

```
fwupdmgr get-devices 1e8c8470-a49c-571a-82fd-19c9fa32b8c3
```

- Let's try to update the firmeware now.

```
fwupdmgr update 1e8c8470-a49c-571a-82fd-19c9fa32b8c3      	 
```

You will likely see something like this:

```
╔════════════════════════════════════════════════════════════════════════════╗
║ Upgrade Fingerprint Sensor from 01000320 to 01000334?                      ║
╠════════════════════════════════════════════════════════════════════════════╣                           
║ Fix physical MITM vulnerability that was found from blackwinghq - a touch  ║
║ of pwn part 1.                                                             ║
║                                                                            ║
║ Fingerprint Sensor and all connected devices may not be usable while       ║
║ updating.                                                                  ║
╚════════════════════════════════════════════════════════════════════════════╝                     
Perform operation? [Y|n]:                        
Writing…             	[************************************   ]          
failed to write: failed to reply: transfer timed out  

> fwupdmgr get-devices 1e8c8470-a49c-571a-82fd-19c9fa32b8c3        
Selected device: Fingerprint Sensor                                                                                                                                                
Framework Laptop (12th Gen Intel Core)                        
│                                  
└─Fingerprint Sensor:                                                                  
  	Device ID:      	d432baa2162a32c1554ef24bd8281953b9d07c11                                                                                              
  	Summary:        	Match-On-Chip fingerprint sensor                                                                                                                                   
  	Current version:	01000320
  	Vendor:         	Goodix (USB:0x27C6)
  	Install Duration:   10 seconds
  	Serial Number:  	UIDXXXXXXXX_XXXX_MOC_B0
  	Update State:   	Failed
  	Problems:       	• An update is in progress
  	Last modified:  	2024-08-30 08:20
  	GUID:           	1e8c8470-a49c-571a-82fd-19c9fa32b8c3 ← USB\VID_27C6&PID_609C
  	Device Flags:   	• Supported on remote server
                      	• Device stages updates
                      	• Device can recover flash failures
                      	• Updatable
                      	• Signed Payload
```

- Note the update **status of failed**. We can verify again this with:

```
fwupdmgr get-devices 1e8c8470-a49c-571a-82fd-19c9fa32b8c3
```

This will likely **still reflect the old 01000320 firmware**.

- At this stage, **reboot** your laptop.

- Now run this again:

```
fwupdmgr get-devices 1e8c8470-a49c-571a-82fd-19c9fa32b8c3
```

- At this point, you should be looking at Current version:	01000334

- From here, we can enroll fingerprints from GNOME on Ubuntu LTS or Fedora Workstation. 
