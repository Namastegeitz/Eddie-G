# **COSMIC SAUCER DRIFT** · Microsoft Store (Windows)

**Cost:** free for individual developers since September 2025 (ID + selfie check).
**Certification:** up to 3 business days. **Games:** 12% fee if paid.

## The catch: packaging
- **MSIX** (recommended): the Store signs it for you, so you need no certificate. The packaging
  tools run on Windows, so this needs a Windows PC or VM.
- **.exe / .msi**: you host a full offline installer at an HTTPS link, signed with a
  certificate from a Microsoft-trusted authority, and it must install silently.

## Windows code signing (for itch.io / website downloads)
Unsigned .exe files show "Windows protected your PC". Options: Azure Artifact Signing
($9.99/month; individuals US/Canada only, validation 1–20 business days) or an OV certificate
(~$65–440/year, hardware token). Store installs don't need this.

## Steps
1. storedeveloper.microsoft.com → free individual account.
2. Package the Windows build as MSIX on a Windows PC.
3. IARC questionnaire (required on the first submission).
4. Listing (reuse the Steam/Play text and screenshots) → submit → certification.

Sources: https://learn.microsoft.com/en-us/windows/apps/publish/whats-new-individual-developer ·
https://learn.microsoft.com/en-us/windows/apps/publish/publish-your-app/msi/app-package-requirements ·
https://learn.microsoft.com/en-us/windows/apps/package-and-deploy/smartscreen-reputation ·
https://azure.microsoft.com/en-us/pricing/details/artifact-signing/
