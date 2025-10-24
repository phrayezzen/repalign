# TestFlight Setup Guide for RepAlign

This guide will help you distribute RepAlign to beta testers via Apple's TestFlight.

## Current App Information

- **App Name**: RepAlign
- **Bundle ID**: `Octahedron-Labs.RepAlign`
- **Version**: 1.0
- **Build**: 1

---

## Prerequisites

### 1. Apple Developer Account
- [ ] Active Apple Developer Program membership ($99/year)
- [ ] Access to [App Store Connect](https://appstoreconnect.apple.com)
- [ ] Access to [Apple Developer Portal](https://developer.apple.com)

### 2. Backend Deployment
⚠️ **IMPORTANT**: Before distributing the app, ensure your backend is deployed and accessible:
- [ ] Fix Railway database connection issue (currently failing with `postgres.railway.internal` DNS error)
- [ ] Get public DATABASE_URL and update Railway variables
- [ ] Verify backend health check passes: `https://repalign-production.up.railway.app/api/v1/health`
- [ ] Update `AppConfig.swift` with production backend URL

---

## Step 1: App Store Connect Setup

### Create App Record

1. Go to [App Store Connect](https://appstoreconnect.apple.com)
2. Click **My Apps** → **+ (Plus icon)** → **New App**
3. Fill in the details:
   - **Platform**: iOS
   - **Name**: RepAlign
   - **Primary Language**: English (U.S.)
   - **Bundle ID**: Select `Octahedron-Labs.RepAlign` (or create new if doesn't exist)
   - **SKU**: `repalign-ios` (any unique identifier for your records)
   - **User Access**: Full Access

4. Click **Create**

### Configure App Information

1. In your new app, go to **App Information**
2. Fill in required fields:
   - **Subtitle** (optional): "Connect with Your Representatives"
   - **Category**: Primary: News, Secondary: Social Networking
   - **Content Rights**: Check if app contains third-party content

---

## Step 2: Xcode Configuration & Archive

### A. Open Project in Xcode

```bash
cd /Users/xilinliu/Projects/RepAlign/frontend
open RepAlign.xcodeproj
```

### B. Configure Backend URL for Production

1. Open `RepAlign/Config/AppConfig.swift`
2. Update `backendBaseURL` to your Railway production URL:
   ```swift
   static let backendBaseURL = "https://repalign-production.up.railway.app/api/v1"
   ```
3. Ensure `dataSource` is set to `.customBackend`

### C. Signing & Capabilities

1. In Xcode, select **RepAlign** project in navigator
2. Select **RepAlign** target
3. Go to **Signing & Capabilities** tab
4. Settings:
   - **Automatically manage signing**: ✅ (recommended)
   - **Team**: Select your Apple Developer Team
   - **Bundle Identifier**: `Octahedron-Labs.RepAlign` (should already be set)
   - **Signing Certificate**: Apple Development / Apple Distribution (auto-managed)

### D. Update Version & Build Number

1. In **General** tab:
   - **Version**: `1.0` (Marketing Version)
   - **Build**: Increment to `2` for subsequent builds (currently `1`)

### E. Select Archive Scheme

1. In Xcode toolbar, select scheme: **RepAlign**
2. Select destination: **Any iOS Device (arm64)**

### F. Archive the App

1. Menu: **Product** → **Archive**
2. Wait for build to complete (may take 2-5 minutes)
3. Organizer window will open automatically

---

## Step 3: Upload to App Store Connect

### In Xcode Organizer

1. Select your archive (should be at the top)
2. Click **Distribute App**
3. Select **App Store Connect** → **Next**
4. Select **Upload** → **Next**
5. Distribution options:
   - **Include bitcode**: No (not required for iOS anymore)
   - **Upload symbols**: Yes (for crash reports)
   - **Manage Version and Build Number**: Yes (Xcode will auto-increment)
6. Click **Next**
7. Review signing certificates (should auto-select)
8. Click **Upload**
9. Wait for upload to complete (1-5 minutes depending on connection)

### Wait for Processing

1. Go to [App Store Connect](https://appstoreconnect.apple.com)
2. Navigate to **My Apps** → **RepAlign** → **TestFlight** tab
3. You'll see build processing status
4. Processing typically takes **10-30 minutes**
5. You'll receive an email when processing is complete

---

## Step 4: TestFlight Setup

### A. Configure Test Information

Once build is processed:

1. In TestFlight tab, click on your build version (e.g., `1.0 (1)`)
2. Fill in **Test Details**:
   - **What to Test**:
     ```
     Welcome to RepAlign Beta!

     This version includes:
     - Browse legislators and their voting records
     - View congressional bills and activity
     - Track upcoming civic events
     - Create and sign petitions
     - Social feed for civic engagement

     Please test:
     1. Login/Registration flow
     2. Browse legislators by state
     3. View bill details and voting history
     4. Event creation and participation
     5. Social features (posts, comments, likes)

     Known issues:
     - [List any known bugs]

     Feedback: Please report bugs via the TestFlight app or email [your-email]
     ```
   - **Test Details**: Fill as needed

3. Click **Save**

### B. Choose Testing Type

#### Internal Testing (Instant, up to 100 testers)

**Best for**: Team members, trusted testers, quick iteration

1. Go to **TestFlight** → **Internal Testing**
2. Click **+ (Plus)** next to Internal Group
3. Name your group: "RepAlign Internal Testers"
4. Click **Create**
5. Click **+** to add testers by email
6. Add Apple IDs (emails) of your team members
7. Click **Add**
8. Builds are **instantly available** to internal testers

#### External Testing (Requires Review, unlimited testers)

**Best for**: Public beta, larger testing groups

1. Go to **TestFlight** → **External Testing**
2. Click **+ (Plus)** next to External Groups
3. Name your group: "RepAlign Beta Testers"
4. Click **Create**
5. Add tester emails (can add up to 10,000)
6. **Select build** to test
7. Fill in **Beta App Review Information**:
   - **Contact Information**: Your email/phone
   - **Sign-In Required**: Yes
   - **Demo Account**: Provide test credentials
     ```
     Username: testuser@example.com
     Password: [create test account password]
     ```
   - **Notes**: Any special instructions for reviewers
8. Click **Submit for Review**
9. Wait **1-2 business days** for Apple's review
10. Once approved, testers receive invitations

---

## Step 5: Distribute to Beta Testers

### What Testers Need to Do

1. **Install TestFlight App**:
   - Download [TestFlight from App Store](https://apps.apple.com/us/app/testflight/id899247664)

2. **Accept Invitation**:
   - Check email for TestFlight invitation
   - Click **View in TestFlight** or **Redeem Code**
   - Opens TestFlight app

3. **Install RepAlign Beta**:
   - In TestFlight, tap **Install** next to RepAlign
   - App appears on home screen with orange dot (indicates beta)

4. **Provide Feedback**:
   - In TestFlight app, tap RepAlign → **Send Beta Feedback**
   - Attach screenshots, crash logs automatically included

### Managing Testers

**Add More Testers**:
- TestFlight → [Group Name] → **+ Add Testers**

**Remove Testers**:
- TestFlight → [Group Name] → Click on tester → **Remove Tester**

**Resend Invitations**:
- TestFlight → [Group Name] → Click on tester → **Resend Invitation**

---

## Step 6: Updating Beta Builds

When you have a new version:

1. **Increment Build Number** in Xcode:
   - General tab → Build: `2`, `3`, `4`, etc.
   - (Keep Version `1.0` until major release)

2. **Archive & Upload** (repeat Step 3)

3. **Wait for Processing**

4. **Update Test Details** with changes in this build

5. **Enable for Testers**:
   - Internal: Automatically available
   - External: Submit for review again (faster subsequent reviews)

6. **Notify Testers**:
   - TestFlight automatically sends notifications
   - Or manually send update notes

---

## Quick Reference Commands

### Check Current Version/Build
```bash
cd /Users/xilinliu/Projects/RepAlign/frontend
xcodebuild -project RepAlign.xcodeproj -showBuildSettings | grep -E "(MARKETING_VERSION|CURRENT_PROJECT_VERSION)"
```

### Archive from Command Line (Advanced)
```bash
cd /Users/xilinliu/Projects/RepAlign/frontend
xcodebuild archive \
  -project RepAlign.xcodeproj \
  -scheme RepAlign \
  -archivePath ./build/RepAlign.xcarchive \
  -configuration Release
```

### Open Organizer
```bash
open ~/Library/Developer/Xcode/Archives
```

---

## Troubleshooting

### "Failed to create provisioning profile"
- Ensure bundle ID is registered in Apple Developer Portal
- Check Team membership is active
- Try unchecking/rechecking "Automatically manage signing"

### "Archive is invalid"
- Ensure you selected "Any iOS Device" (not Simulator)
- Clean build folder: Product → Clean Build Folder
- Try archiving again

### "Build processing failed"
- Check email for specific error
- Common issues: Missing compliance info, invalid entitlements
- Fix and upload new build

### "Testers not receiving invitations"
- Check spam/junk folders
- Verify email addresses are correct
- Resend invitation from App Store Connect
- Ensure TestFlight app is installed

### "App crashes on launch for testers"
- Check backend URL is correct and accessible
- Review crash logs in App Store Connect → TestFlight → Build → Crashes
- Ensure test account credentials work

---

## Important Notes

### TestFlight Limitations

- **Build Expiration**: Builds expire after **90 days**
- **Tester Limits**:
  - Internal: 100 testers (must be in your App Store Connect team)
  - External: 10,000 testers
- **Installation Limits**: Testers can have up to **30 apps** in TestFlight
- **Testing Period**: External testers can test for 90 days per build

### Beta App Review Guidelines

Apple reviews external TestFlight builds for:
- Crashes or major bugs
- Inappropriate content
- Compliance with App Store guidelines
- **They DO NOT review** for App Store readiness

### Privacy & Data

- TestFlight collects crash logs and usage data
- Inform testers in "What to Test" section
- Ensure compliance with privacy policies
- No App Tracking Transparency required for TestFlight

---

## Next Steps After Beta Testing

1. **Collect Feedback**: Use TestFlight feedback, email, surveys
2. **Fix Bugs**: Prioritize critical issues
3. **Iterate**: Upload new builds with fixes
4. **Prepare for Release**:
   - Update version to next major: `1.1`, `2.0`, etc.
   - Create App Store screenshots
   - Write App Store description
   - Submit for App Store review

---

## Resources

- [TestFlight Documentation](https://developer.apple.com/testflight/)
- [App Store Connect Help](https://developer.apple.com/help/app-store-connect/)
- [Beta Testing Best Practices](https://developer.apple.com/testflight/testers/)

---

## Support

If you encounter issues:
1. Check Apple Developer Forums
2. Review Xcode/App Store Connect error messages
3. Check crash logs in App Store Connect
4. Contact Apple Developer Support (if urgent)

---

**Good luck with your beta test!** 🚀
