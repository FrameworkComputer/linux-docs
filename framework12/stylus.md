# Framework 12 - Stylus

The touchscreen and stylus do not need any special drivers on Windows or Linux.
It is an I2C HID device, just like the touchpad and generic drivers can enable full functionality.
On Windows there is a custom driver to enable wake by touch.

## Protocols

The touchscreen supports MPP and USI protocols, which were developed for Windows and ChromeOS, respectively.
In practice, both protocols work on both operating systems. So just enable, whatever your stylus supports.

The Framework Stylus supports both protocols, so the BIOS setting can be set to either.
Both protocols support the same functionality, with the difference that USI supports battery and firmware version reporting. MPP relies on Bluetooth to do the same, which the Framework stylus does not support.

## Stylus functionality

- Pressure Level 0.00 to 1.00
- X and Y tilt 60 degree to any direction
- Tap
  - Usually interpreted as left-click
- Lower Button (Close to the tip)
  - Eraser
- Upper Button (Closer to your hand)
  - `BTN_STYLUS` - Usually interpreted as right-click

Note that application usually interpret the buttons (especially eraser) differently if the stylus is touching the screen versus hovering.
For example, drawing applications will temporarily switch to the eraser tool when hovering and pressing the eraser button, but only erase once the stylus also touches the screen.

### Remapping the buttons

The buttons are sent as described in other sections by the kernel. Applications can interpret them as they wish.

## Testing on Linux

To test, if the stylus works correctly and reports all data as expected, run
`sudo libinput debug-events` and use the stylus in a different window.

The reported data looks the same, no matter what protocol is selected.
However it depends very much on what the stylus reports!
Below data is from the Framework Stylus.


```
                                                                                                                               Stylus enters detection range of the display
                                                                                                                                                |
 event9   TABLET_TOOL_PROXIMITY        +267.547s                247.63*/138.28* tilt: 13.57*/12.67*     pressure: 0.00* pen      (0, id 0x4538) proximity-in    axes:pt btn:SS2


                                                           Y Coordinate
                                                                |
                                                   X Coordinate |       X/Y Tilt (-60 to +60)   Pressure (0.00 to 1.00)
                                                        |       |             |     |                     |
 event9   TABLET_TOOL_AXIS        263  +35.807s         209.39*/105.86* tilt: 6.43 /1.77        pressure: 0.00
 

                                                                                                                               Stylus exits detection range of the display
                                                                                                                                                |
 event9   TABLET_TOOL_PROXIMITY        +267.620s                248.27 /137.19  tilt: 12.87 /9.80       pressure: 0.00  pen      (0, id 0x4538) proximity-out

                                                                                                            Stylus pressed on the screen/Is removed from the screen
                                                                                                                        |
 event9   TABLET_TOOL_TIP              +329.857s                238.76*/144.14* tilt: 12.92 /10.49      pressure: 0.09* down
 event9   TABLET_TOOL_TIP              +330.011s                238.11*/144.17* tilt: 12.02*/10.32*     pressure: 0.00* up


                                                                                                         Lower (eraser) button is pressed
                                                                                                                        |
 event9   TABLET_TOOL_PROXIMITY        +403.162s                240.76 /141.36  tilt: 50.05 /-1.43      pressure: 0.00  pen      (0, id 0x4538) proximity-out
 event9   TABLET_TOOL_PROXIMITY        +403.165s                240.79*/141.21* tilt: 49.95*/-1.30*     pressure: 0.00* eraser   (0, id 0xd278) proximity-in    axes:pt btn:SS2

                                                                                                         Lower (eraser) button is released
                                                                                                                        |
 event9   TABLET_TOOL_PROXIMITY        +403.177s                240.79 /141.03  tilt: 49.95 /-1.30      pressure: 0.00  eraser   (0, id 0xd278) proximity-out
 event9   TABLET_TOOL_PROXIMITY        +403.180s                240.76*/140.86* tilt: 51.11*/-0.83*     pressure: 0.00* pen      (0, id 0x4538) proximity-in    axes:pt btn:SS2

                                                Upper button is pressed
                                                      |
 event9   TABLET_TOOL_BUTTON           +8.646s  s331 (BTN_STYLUS) released, seat count: 0

                                                Upper button is released
                                                      |
 event9   TABLET_TOOL_BUTTON           +8.360s  s331 (BTN_STYLUS) pressed, seat count: 1
```

### Firmware Details with USI

See:

- [Stylus IDs and Firmware Version](https://github.com/FrameworkComputer/framework-system/blob/main/EXAMPLES.md#stylus-framework-12)
- [Stylus Battery Level](https://github.com/FrameworkComputer/framework-system/blob/main/EXAMPLES.md#stylus-framework-12-1)
