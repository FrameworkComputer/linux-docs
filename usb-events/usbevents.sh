#!/bin/bash

# Define the output file
OUTPUT_FILE="usb_events.txt"

# Get the full path of the output file
FULL_PATH=$(realpath "$OUTPUT_FILE")

# Define color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
RESET='\033[0m'

# Clear the screen and output the results to usb_events.txt
{
    echo -e "${BLUE}USB Events Log${RESET}"
    echo -e "${BLUE}Location: $FULL_PATH${RESET}"
    echo -e "${BLUE}Generated on: $(date)${RESET}"
    echo -e "${BLUE}=======================================${RESET}"
    echo

    # Use journalctl to get today's logs, then filter and process with awk
    journalctl --since today -o short-precise | awk -v red="$RED" -v green="$GREEN" -v yellow="$YELLOW" -v blue="$BLUE" -v magenta="$MAGENTA" -v cyan="$CYAN" -v reset="$RESET" '
    # Skip lines that are part of the file type list
    /where FILE_TYPE is one of the following:/ { skip = 1; next }
    /End of USB Events/ { skip = 0; next }
    skip == 1 { next }

    BEGIN {
        # Define event types and their headers with colors
        event_types["new"] = green "New USB Connections:" reset
        event_types["disconnect"] = red "USB Disconnections:" reset
        event_types["fail"] = yellow "USB Failures:" reset
        event_types["error"] = red "USB Errors:" reset
        event_types["reset"] = yellow "USB Resets:" reset
        event_types["attached"] = green "USB Attachments:" reset
        event_types["enumerate"] = cyan "USB Enumerations:" reset
        event_types["info"] = blue "USB Device Information:" reset
        event_types["other"] = magenta "Other USB Events:" reset
        
        last = ""
        context = ""
        contextCount = 0

        # Initialize counters and arrays for summary and pattern detection
        for (type in event_types) {
            count[type] = 0
        }
        device_connects = 0
        device_disconnects = 0
        split("", devices)
        split("", error_messages)
        split("", error_counts)
        split("", failure_messages)
        split("", failure_counts)
    }

    # Function to print context and reset it
    function print_context() {
        if (context != "") {
            print context
            context = ""
        }
    }

    # Function to interpret USB errors
    function interpret_error(error_msg) {
        if (error_msg ~ /device descriptor read\/64, error -32/) {
            return "Device is not responding correctly. This could be due to a faulty device, cable, or USB port."
        } else if (error_msg ~ /device not accepting address/) {
            return "The device is not accepting the address assigned by the USB controller. This could indicate a hardware problem with the device or compatibility issues."
        } else if (error_msg ~ /unable to enumerate USB device/) {
            return "The system cannot communicate with the device. This could be due to a driver issue, hardware problem, or incompatible device."
        } else if (error_msg ~ /cannot enable. Maybe the USB cable is bad?/) {
            return "The device cannot be enabled. This is often due to a faulty USB cable, but could also indicate issues with the device or USB port."
        } else if (error_msg ~ /Device not responding/) {
            return "The device is not responding to the USB controller. This could be due to a hardware failure, power issues, or a problem with the USB cable."
        } else if (error_msg ~ /cros-usbpd-charger.*probe.*failed with error -71/) {
            return "The Chrome OS USB Power Delivery charger driver failed to initialize. Error -71 typically indicates that no device was found. This could mean the charger is not properly connected, not compatible, or there\"s an issue with the USB-C port."
        } else if (error_msg ~ /usb [0-9]-[0-9]: device descriptor read\/8, error -71/) {
            return "Failed to read the device descriptor. Error -71 suggests a device protocol error, possibly due to a disconnect during enumeration. Check if the device is properly connected and try reconnecting it."
        } else if (error_msg ~ /usb [0-9]-[0-9]: device not accepting address [0-9], error -71/) {
            return "The device is not accepting the address assigned by the USB host. This could indicate a problem with the device itself, or it might be drawing too much power. Try a different USB port or a powered USB hub."
        } else if (error_msg ~ /cros-dwc3-otg cros-dwc3-otg.0.auto: Failed to get dr_mode from DT/) {
            return "The Chrome OS USB On-The-Go \\(OTG\\) driver failed to get the dual-role mode from the Device Tree. This is likely a firmware or kernel configuration issue and may affect USB functionality."
        } else if (error_msg ~ /cros-ec-typec cros-ec-typec.0.auto: failed to get device tree data: -19/) {
            return "The Chrome OS Embedded Controller \\(EC\\) USB Type-C driver failed to get data from the Device Tree. This could affect USB-C and Power Delivery functionality. It may be a firmware or kernel configuration issue."
        } else {
            return "Unrecognized error. This error is not in our current database of known issues. It may require further investigation or consultation with system logs and documentation."
        }
    }

    # Main processing
    {
        if ($0 ~ /usb/ && $0 ~ /(disconnect|connect|new|fail|error|reset|attached|enumerate|Product:|Manufacturer:)/) {
            if (contextCount > 0) {
                context = context $0 "\n"
                contextCount--
                if (contextCount == 0) {
                    print_context()
                }
            } else {
                event_type = "other"
                for (type in event_types) {
                    if ($0 ~ type) {
                        event_type = type
                        break
                    }
                }
                
                if (last != event_type) {
                    print_context()
                    print "\n\n" event_types[event_type] "\n"
                    last = event_type
                }
                
                context = context "    " $0 "\n"
                contextCount = 10
                count[event_type]++

                # Pattern detection logic
                if ($0 ~ /new|attached/) {
                    device_connects++
                    if ($0 ~ /Product:/) {
                        device = $0
                        if (!(device in devices)) {
                            devices[device] = 1
                        } else {
                            devices[device]++
                        }
                    }
                } else if ($0 ~ /disconnect/) {
                    device_disconnects++
                } else if ($0 ~ /error/) {
                    error_messages[count["error"]] = $0
                    if ($0 in error_counts) {
                        error_counts[$0]++
                    } else {
                        error_counts[$0] = 1
                    }
                } else if ($0 ~ /fail/) {
                    failure_messages[count["fail"]] = $0
                    if ($0 in failure_counts) {
                        failure_counts[$0]++
                    } else {
                        failure_counts[$0] = 1
                    }
                }
            }
        } else if (contextCount > 0) {
            context = context "    " $0 "\n"
            contextCount--
            if (contextCount == 0) {
                print_context()
            }
        }
    }

    END {
        print_context()
        print "\n\n" blue "End of USB Events" reset

        # Print summary
        print "\n\n" cyan "Summary of USB Events:" reset
        for (type in event_types) {
            if (count[type] > 0) {
                print "  " event_types[type], count[type]
            }
        }
        
        # Calculate total events
        total = 0
        for (type in count) {
            total += count[type]
        }
        print "\n" cyan "Total USB events:" reset, total

        # Print pattern detection summary
        print "\n\n" cyan "Pattern Detection Summary:" reset
        print yellow "  • Total device connections:" reset, device_connects
        print yellow "  • Total device disconnections:" reset, device_disconnects
        print yellow "  • Unique devices detected:" reset, length(devices)
        
        if (device_connects > device_disconnects) {
            diff = device_connects - device_disconnects
            print red "  • Warning: " diff " more connections than disconnections. Check for devices left connected:" reset
            for (device in devices) {
                if (devices[device] > 1) {
                    print "    - " device " \\(connected " devices[device] " times\\)"
                }
            }
        } else if (device_disconnects > device_connects) {
            diff = device_disconnects - device_connects
            print red "  • Warning: " diff " more disconnections than connections. Possible abrupt removals." reset
        }
        
        if (count["fail"] > 0 || count["error"] > 0) {
            print red "  • Alert: USB failures or errors detected:" reset
            print yellow "    Note: Errors that occur only once are likely non-issues. Repeated errors throughout the day may be worth investigating." reset
            for (error in error_counts) {
                print "    - Error \\(occurred " error_counts[error] " time\\(s\\)\\): " error
                print "      Interpretation: " interpret_error(error)
                if (error_counts[error] == 1) {
                    print "      This error occurred only once and is likely a non-issue."
                } else {
                    print "      This error occurred multiple times and may warrant further investigation."
                }
            }
            for (failure in failure_counts) {
                print "    - Failure \\(occurred " failure_counts[failure] " time\\(s\\)\\): " failure
                print "      Interpretation: " interpret_error(failure)
                if (failure_counts[failure] == 1) {
                    print "      This failure occurred only once and is likely a non-issue."
                } else {
                    print "      This failure occurred multiple times and may warrant further investigation."
                }
            }
        }
        
        if (count["reset"] > 0) {
            print yellow "  • Note: " count["reset"] " USB resets detected. This might indicate device or driver issues." reset
        }
        
        if (length(devices) > 5) {
            print green "  • Multiple unique devices detected \\(" length(devices) "\\). Diverse USB activity observed:" reset
            for (device in devices) {
                print "    - " device
            }
        }

        print "\n" magenta "Remember: System logs tend to be cautious and may report minor issues. Don\"t panic if you see errors - many are temporary and resolve on their own. Focus on repeated errors or those that affect your device functionality." reset
        print magenta "This summary provides an overview of USB activity patterns and interprets common errors. For unrecognized errors or more details, please review the full log." reset
    }
    '
} > "$OUTPUT_FILE"

# Display the contents of the file
cat "$OUTPUT_FILE"

echo ""
echo -e "${BLUE}Log file has been saved to: $FULL_PATH${RESET}"
