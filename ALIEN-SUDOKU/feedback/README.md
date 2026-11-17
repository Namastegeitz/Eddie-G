# Feedback and bug reports

Testers report bugs, ideas and how they played in the **Bugs & feedback** tab of Launch Control.
Reports are stored on that page (its database), so nobody needs a GitHub account.

- **Collecting:** share Launch Control from claude.ai. Give testers **Contributor** access so they can send reports; Viewers can only read.
- **Fixing:** ask Claude to "check the launch board for new bugs". Claude reads the reports, fixes what it can, and sets each report to Confirmed, Fixed or Won't fix.
- **Exporting:** Claude saves the reports here as `reports.json`, and `node ../checklist/build.mjs` lists the open ones in the main README.

Good reports say what happened, what you expected, the device, and the steps to make it happen again.
