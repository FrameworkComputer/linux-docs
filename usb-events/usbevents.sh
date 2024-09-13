#!/bin/bash

# Define the output file
OUTPUT_FILE="usb_events.txt"

# Get the full path of the output file
FULL_PATH=$(realpath "$OUTPUT_FILE")

# Clear the screen and output the results to usb_events.txt
{
    echo "USB Events Log"
    echo "Location: $FULL_PATH"
    echo "Generated on: $(date)"
    echo "======================================="
    echo

    # Use journalctl to get today's logs, then process with awk
    journalctl --since today -o short-precise | awk '
    BEGIN {
        # Define event types and their headers
        event_types["new"] = "New USB Connections:"
        event_types["disconnect"] = "USB Disconnections:"
        event_types["fail"] = "USB Failures:"
        event_types["error"] = "USB Errors:"
        event_types["reset"] = "USB Resets:"
        event_types["attached"] = "USB Attachments:"
        event_types["enumerate"] = "USB Enumerations:"
        event_types["info"] = "USB Device Information:"
        event_types["other"] = "Other USB Events:"
        
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
        print "\n\nEnd of USB Events"
        
        # Print summary
        print "\n\nSummary of USB Events:"
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
        print "\nTotal USB events:", total
    }
    '
} > "$OUTPUT_FILE"

# Display the contents of the file
cat "$OUTPUT_FILE"

echo ""
echo "Log file has been saved to: $FULL_PATH"
