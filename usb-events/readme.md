# USB Event Logger script

This is designed to collect, organize, and summarize USB-related events from your system logs. Here's an overview of its main functions:

- Log Collection: It uses the journalctl command to retrieve today's system logs.
- Event Filtering: The script filters these logs to focus on USB-related events, including connections, disconnections, errors, resets, and device information.
- Event Categorization: It categorizes these events into different types such as new connections, disconnections, failures, errors, resets, attachments, enumerations, and device information.
- Context Preservation: For each event, it includes 10 lines of context (5 before and 5 after) to provide more detailed information.
- Formatted Output: The script organizes the events by category, making the log easy to read and navigate.
- Event Summary: At the end of the log, it provides a summary that counts the occurrences of each event type and calculates the total number of USB events.
- Log File Creation: All this information is saved to a text file (default name: usb_events.txt).
- File Location: The script records and displays the full path of the log file, making it easy to locate for future reference.
- Timestamp: It includes the date and time when the log was generated.
- Display: After processing, the script displays the entire log content in the terminal.

This tool is useful for troubleshooting USB-related issues. It provides a comprehensive yet easy-to-read overview of all USB activity on the system for the current day.


### This provides the output as follows:

  - Other USB Events: 
  - New USB Connections: 
  - USB Errors: 
  - USB Resets:


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

## To Install USB Event Logger script, simply run:


```
curl -s https://raw.githubusercontent.com/FrameworkComputer/linux-docs/main/usb-events/usbevents.sh -o powersave.sh && clear && sudo bash usbevents.sh
```

Running the script in the future
After the install, you can run going forward with the following in the HOME directory. So merely opening a terminal and running this will work if the original script has not been moved.

```
sudo bash usbevents.sh
```

### Log file

Log file is provioded as usb_events.txt in your home directory.


![USB Event Logger script](https://raw.githubusercontent.com/FrameworkComputer/linux-docs/main/usb-events/images/stitched_image.png)
