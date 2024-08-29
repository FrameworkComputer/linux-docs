## Fingerprint Checker

Fingerprint Checker is merely a friendly terminal front end to [fprintd](https://fprint.freedesktop.org/)

### Desktop Environment Detection

- **Highlight:** The script automatically detects the current desktop environment and displays it at the top of the menu in yellow.
- **Desktop Environment Detection:** If the desktop environment is not GNOME, the script warns the user that fingerprint login might not work, but configuring sudo with fingerprint authentication is still possible.

### User-Friendly Menu:

- **Clear Interface:** The script presents a clear and simple menu that allows users to manage their fingerprint data through options like listing, enrolling, deleting, and verifying fingerprints.
- **Highlighted Output:** Important outputs, such as the desktop environment, fingerprint entries, and verification processes, are highlighted in yellow for easy visibility.

### Fingerprint Management

- **Listing Fingerprints:** Users can list all enrolled fingerprints for the current or a specified user.
- **Enrolling Fingerprints:** The script supports enrolling new fingerprints for the current or a specified user.
- **Deleting Fingerprints:** Users can delete all fingerprints for the current or a specified user.
- **Verifying Fingerprints:** The script allows users to verify an enrolled fingerprint for the current user, with the verification process highlighted in yellow.

### Guided fpintd Management

- **Restarting fprintd:** The script includes an option to restart the fprintd service, which is often necessary after making changes to fingerprint data.

### Error Handling and Feedback:

- **Input Validation:** The script handles invalid input gracefully, providing feedback and re-prompting the user when necessary.
Pausing for Review: After each operation, the script pauses and prompts the user to press Enter, ensuring they have time to review the output before returning to the menu.

![Fingerprint Checker](https://raw.githubusercontent.com/FrameworkComputer/linux-docs/main/Fingerprint-Checker/images/checker.png)
