## How it works

**[BACK TO MAIN PAGE](https://github.com/FrameworkComputer/linux-docs/tree/main/log-helper#framework-log-helper-aka-combinedsh)**

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

  ---------------------------------------
  <br /><br /><br /><br /><br /><br /><br /><br />

  ## Troubleshooting

 - If you find the script is not working right or taking over 10 minutes, you can run this to trim down your journal a bit to make it easier to manage for the script.**

```
sudo journalctl --vacuum-time=30d --vacuum-size=500M
```
(Then reboot, run the script again)

- Your log file keeps getting overwritten.
  >This is by design. So if you wish to prevent this and keep this from happening, copy your combined_log.txt file to another location so it will not be overwritten.

**[BACK TO MAIN PAGE](https://github.com/FrameworkComputer/linux-docs/tree/main/log-helper#framework-log-helper-aka-combinedsh)**
  
  <br /><br /><br /><br /><br /><br /><br /><br />

