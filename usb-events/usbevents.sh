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

        # Initialize counters for summary
        for (type in event_types) {
            count[type] = 0
        }
    }

    # Function to print context and reset it
    function print_context() {
        if (context != "") {
            print context
            context = ""
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
    }
    '
} > "$OUTPUT_FILE"

# Display the contents of the file
cat "$OUTPUT_FILE"

echo ""
echo -e "${BLUE}Log file has been saved to: $FULL_PATH${RESET}"
