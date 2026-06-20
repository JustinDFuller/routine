# App Store Submission Checklist

Use this after the internal TestFlight pilot is stable enough to prepare a public release.

- Confirm the release candidate build passed [TESTFLIGHT_RUNBOOK.md](TESTFLIGHT_RUNBOOK.md) and the full [DOGFOODING_CHECKLIST.md](DOGFOODING_CHECKLIST.md).
- Finalize App Store listing copy: app name, subtitle, description, keywords, promotional text if used.
- Confirm the support URL is live and matches the release owner.
- Confirm the privacy-policy URL is live and matches the app’s local-only behavior.
- Decide whether `Docs/Screenshots` assets are sufficient for App Store screenshots; if not, produce final submission screenshots.
- Complete the App Store age-rating questionnaire.
- Review privacy nutrition answers and confirm they still state no tracking and no collected data.
- Review export-compliance answers and confirm `ITSAppUsesNonExemptEncryption = false` still matches the shipped app.
- Prepare App Review notes, including how the widget works and that the app is local-only.
- Confirm app and widget bundle IDs, App Group, and signing all match the archived build.
- Confirm the final `MARKETING_VERSION` and `CURRENT_PROJECT_VERSION`.
- Confirm any launch-day support/contact path is monitored.
