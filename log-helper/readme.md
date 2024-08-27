
## Framework Log Helper aka "combined.sh"

This script collects and analyzes system logs from your computer, helping Framework support to identify potential issues or errors. 
It can also gather logs from specific time ranges or filter existing logs for keywords, providing summaries of potential problems related to graphics, networking, and critical sytem errors.

### Which distros does this work on?

**This is tested to work with the following Linux distros.**

- Ubuntu
- Fedora
- Bazzite/Project Bluefin (curl is installed already)
- (This "should work" on anything using curl with sane paths to dmesg and journalctl)

### How to use this tool?

####
- [Deep dive into how it works](https://github.com/FrameworkComputer/linux-docs/blob/main/log-helper/how-it-works.md#how-it-works).
- [Troubleshooting common issues](https://github.com/FrameworkComputer/linux-docs/blob/main/log-helper/how-it-works.md#troubleshooting).

**For customer self-support, this is useful in that you can grab your logs from any of the three options:**

### Install Curl

Curl should already be installed, but just in case:

#### Fedora
```
sudo dnf install curl -y
```

or

#### Ubuntu
```
sudo apt install curl -y
```

#### (Either distro) Then run:

```
curl -s https://raw.githubusercontent.com/FrameworkComputer/linux-docs/main/log-helper/combined.sh -o combined.sh && clear && bash combined.sh
```

<br />

#### Running the script in the future

>After the install, you can run going forward with the following in the HOME directory. So merely opening a terminal and running this will work if the original script has not been moved.<br />

```
bash combined.sh
```
<br /><br />

----------------------------------------------------------

#### Last X Minutes (How many minutes ago do you wish to gather logs from)

- Paste in the code mentioned previously, press enter, type in option 1.

- Type in the Enter the number of minutes you wish to gather logs from. 
>For example, if the issue happened about 15 minutes ago, you might choose to type in 25 to gather logs from 25 minutes ago. This gives you a buffer of time in case you're not sure.

- Once the minutes are typed into the terminal as shown below (using your number keys), press enter. Enter your sudo password when prompted.

- First progress bar will run, then the second one. Once completed, the log file combined_log.txt will appear in your home directory.
<br />

 ![Last X Minutes](https://raw.githubusercontent.com/FrameworkComputer/linux-docs/main/log-helper/images/1.gif "Last X Minutes")

<br /><br />

----------------------------------------------------------

#### Last 24 hours (As it says, 24 hours from this moment of logs)

- Paste in the code mentioned previously, press enter, type in option 2.
>This will run a bit slower, depending on your log(s) size.

- First progress bar will run, then the second one. Once completed, the log file combined_log.txt will appear in your home directory.

<br /><br />
----------------------------------------------------------

#### Specific time range

- Paste in the code mentioned previously, press enter, type in option 3.

- You will be asked for a START TIME. This is the beginning period you wish to gather logs from. Enter in the date and time in this format: YYYY-MM-DD HH:MM and then press enter.
>You do not need to add minutes (MM) if you do not want to - this works fine with YYYY-MM-DD HH instead. Time must be military time. So for 2pm for example, that would be 14:00. 

**For all of the above examples, your log will be sent to combined_log.txt in your home directory.**


**Note, each time you collect logs, you will be overwriting the previous combined_log.txt file.**

![Specific Time Range](https://raw.githubusercontent.com/FrameworkComputer/linux-docs/main/log-helper/images/2.gif "Specific Time Range")

<br /><br />
----------------------------------------------------------

#### Filter previously created log file

>This is an option used by support and those who know what they're look for. Looking at your logs, you are going to see a ton of verbose messages. 99.9% of the "errors" or warnings you see are fine. This is normal. Even some of the items that appear in "Focused Summary of Potential Issues" and "General Summary of Potential Issues (excluding gnome-shell errors)" are fine. We simply want to gather everything that logs collect. And while the summaries are verbose, they are not an automatic indication that anything is wrong. For newer users, we recommend leaving option 4 to Framework Support staff.

- Collect logs using one of the methods indicated above. Note, each time you collect logs, you will be overwriting the previous combined_log.txt file. 

- Paste in the code mentioned previously, press enter, type in option 4.

- You will be asked two questions; do you wish to grep for a keyword or a key phrase.
> Make your selection if you are familiar with Linux. If you are not, this is an ideal time to stop, open a support ticket. When support replies, send them the combined_log.txt file in your home directory.

- If you selected Grep for a key phrase, type in the phrase without any quotes. Press enter.

- If you selected Grep for a keyword, type in the keyword without. Press enter.

- Your filtered_log.txt located in your home directory file will contain your query.
- 
![Filter Previously Created Log File](https://raw.githubusercontent.com/FrameworkComputer/linux-docs/main/log-helper/images/3.gif "Filter Previously Created Log File")

<br /><br />
