
## Framework Log Helper aka "combined.sh"

This script collects and analyzes system logs from your computer, helping Framework support to identify potential issues or errors. 
It can also gather logs from specific time ranges or filter existing logs for keywords, providing summaries of potential problems related to graphics, networking, and critical sytem errors.


### How it works

 Main Features:
  - Gathers logs from two main sources: dmesg (kernel messages) and journalctl (system and service logs)
  - Provides a time range for log collection
  - Can filter existing log files for specific keywords or phrases
  - Provides summaries of potential issues, focusing on graphics, networking, and critical errors

• How it's used:
  1. Choose from four options:
     - Collect logs from the last X minutes
     - Collect logs from the last 24 hours
     - Collect logs for a specific time range
     - Filter a previously created log file

  2. For new log collection (options 1-3):
     - The script gathers system information (kernel version, desktop environment, etc.)
     - It then collects and processes logs from dmesg and journalctl for the specified time range
     - As it processes logs, it identifies potential issues and adds them to a summary
     - The collected logs and summaries are saved to a file named "combined_log.txt" in the user's home directory

  3. For filtering an existing log file (option 4):
     - The script looks for a file named "combined_log.txt" in the user's home directory
     - If found, it allows the user to search for a specific keyword or phrase within the log
     - The filtered results are saved to a new file named "filtered_log.txt"

  4. The script provides progress bars during log collection and processing

  5. At the end, it displays a summary of potential issues, categorized into:
     - Focused issues (related to graphics, networking, and critical errors)
     - General issues (excluding less critical errors like those from GNOME shell)

• Key Benefits:
  - Simplifies the process of collecting and analyzing system logs
  - Helps users quickly identify potential system issues
  - Provides flexibility in choosing time ranges and filtering options
  - Offers a user-friendly interface with clear prompts and progress indicators
  
  Sections provided and clearly isolated:
  
  ===== System Information =====
  ===== dmesg output starts =====
  ===== journalctl output starts =====
  ===== Focused Summary of Potential Issues =====
  ===== General Summary of Potential Issues (excluding gnome-shell errors) =====


Curl should already be installed.
But just in case:

#### Fedora
```
sudo dnf install curl -y
```

or

#### Ubuntu
```
sudo apt install curl -y
```

**Then run:**

```
curl https://raw.githubusercontent.com/FrameworkComputer/linux-docs/main/log-helper/combined.sh && clear && sh combined.sh
```

<br />

#### Running the script in the future

>After the install, you can run going forward with the following in the HOME directory. So merely opening a terminal and running this will work if the original script has not been moved.<br />

```
sh combined.sh
```
<br /><br />

#### Last X Minutes (How many minutes ago do you wish to gather logs from)
![Last X Minutes](https://raw.githubusercontent.com/FrameworkComputer/linux-docs/main/log-helper/images/1.gif "Last X Minutes")


#### Specific Time Range (YYYY-MM-DD HH:MM)
![Specific Time Range](https://raw.githubusercontent.com/FrameworkComputer/linux-docs/main/log-helper/images/2.gif "Specific Time Range")


#### Filter Previously Created Log File (Used by support to dig into a log file deeper looking for keywords or patterns)
![Filter Previously Created Log File](https://raw.githubusercontent.com/FrameworkComputer/linux-docs/main/log-helper/images/3.gif "Filter Previously Created Log File")
