# iTIWI Administrator Manual

**System:** iTIWI Admin Dashboard  
**Audience:** Authorized administrators and super administrators  
**Document status:** Based on the current dashboard implementation  
**Date:** 21 August 2026

## 1. Purpose and Responsibilities

The iTIWI Admin Dashboard is the web console for maintaining municipal content, reviewing citizen submissions, processing online services, managing users, and managing administrator access.

Administrators are responsible for:

- Publishing accurate and current information
- Reviewing submissions fairly and consistently
- Protecting personal data and uploaded documents
- Recording clear status updates and reasons
- Avoiding duplicate, premature, or unsupported approvals
- Signing out after every session on a shared computer

## 2. Access Requirements

You need:

1. An administrator account created or assigned by an authorized administrator.
2. The admin dashboard URL supplied by the system owner.
3. The account email and password.
4. A supported web browser and a reliable internet connection.

Admin account creation is not available on the login page. Contact an authorized administrator when an account is needed.

## 3. Sign In and Password Recovery

1. Open the admin dashboard login page.
2. Enter **Email Address**.
3. Enter **Password**.
4. Use the password visibility control if needed.
5. Select **Remember me** only on a private, trusted device.
6. Select **Sign In**.

To recover a password, select **Forgot password?**, enter the account email, and follow the reset link sent to your inbox. Do not ask another person to send you a password.

After authentication, the dashboard checks the Supabase session and loads the administrator's role and permissions. An invalid or expired session returns to the login page.

## 4. Dashboard Layout

The sidebar contains:

- Dashboard
- Manage Barangay
- Manage News
- Reports
- Transparency
- Tourist Guide
- Online Services
- Manage Hotline
- Manage Hotline
- Manage Users
- Manage Admin

The header contains the theme toggle, notifications, and the administrator profile. On smaller screens, use the menu button to open the sidebar.

### Dashboard statistics

The dashboard summarizes **Total Barangay**, **Total News**, **Total Reports**, **Users**, **Pending Reports**, and **Pending Services**. It also provides recent report/request tables, report status breakdown, service request status, and performance trend information.

Treat dashboard counts as an operational summary. Open the relevant module before making a decision.

## 5. Permissions and Roles

### Super Administrator

A super administrator has access to all dashboard features, including **Manage Users** and **Manage Admin**.

### Feature administrator

A non-super administrator is assigned a role name and one configured feature. Available feature permissions are:

- Manage Barangay
- Manage News
- Reports
- Transparency
- Tourist Guide
- Online Services

Navigation is hidden or restricted when the session lacks permission. Manage Users and Manage Admin are reserved for super administrators.

### Operational caution

The current role assignment and page-visibility behavior is resolved largely in browser local storage after Supabase authentication. This is not a replacement for server-side authorization. Keep the dashboard URL, Supabase credentials, service-role credentials, and administrator accounts restricted, and verify that production database policies also enforce permissions.

## 6. General Record Management

Most content modules follow the same pattern:

1. Open the module from the sidebar.
2. Use search, filters, and pagination to locate a record.
3. Select **Add**, **Edit**, or the row action for the required operation.
4. Complete required fields and validate links, dates, and files.
5. Save the record.
6. Confirm that the record appears with the expected published/status value.

For deletion:

1. Select the row delete action.
2. Read the confirmation message.
3. Select **Delete** only after confirming that the record is obsolete and not referenced by an active workflow.

Do not delete a record merely to correct a spelling mistake; edit it when the module supports editing.

## 7. Manage Barangay

Use this module to maintain barangay records displayed in the mobile app.

### Add or edit a barangay

1. Open **Manage Barangay**.
2. Select **Add Barangay** or edit an existing row.
3. Enter the barangay name and description.
4. Add geographic data and latitude/longitude when available.
5. Enter the officials, including the configured kagawad fields.
6. Upload the **Barangay Seal / Logo** and **Barangay Cover Image** when available.
7. Review spelling, coordinates, and image orientation.
8. Save the record.

Search the list after saving to confirm that the final record is present. Delete only duplicate or retired records after confirming the impact on public pages.

## 8. Manage News

Use News for announcements, updates, events, alerts, and other publishable posts.

### Create or schedule news

1. Open **Manage News**.
2. Select **Add News**.
3. Enter the **Title** and **Description**.
4. Select a category: **Announcement**, **Update**, **Event**, **Alert**, or **Other**.
5. Upload an image when appropriate.
6. Set **Publish Date** and **Publish Time**.
7. Review the wording, date, and image.
8. Save the post.

Scheduled posts are automatically published at the configured date and time. Check the **Published** value in the list after saving. Edit or delete posts when information changes, and avoid publishing duplicate announcements.

## 9. Reports

Reports are citizen-submitted concerns or incident notices. Handle them as potentially sensitive records.

### Review a report

1. Open **Reports**.
2. Search or filter by status and date.
3. Open the report details.
4. Read the reporter's message and inspect attachments.
5. Confirm that the report is not a duplicate before changing its status.

### Report statuses

- **Pending:** Newly submitted and awaiting review.
- **Under Review:** Being investigated or assessed.
- **Resolved:** Action has been completed or the report has been addressed.
- **Rejected:** The report cannot be accepted or acted upon.

### Update a report

1. Select the report status action.
2. Choose the new status.
3. If rejecting, enter a clear rejection reason.
4. If resolving, enter the **Message to Reporter** describing the outcome.
5. Attach **Proof/Evidence (Files or Images)** when appropriate and permitted.
6. Save the update.

The mobile app presents administrator `reviewing` as **Under Review** and `resolved` as **Approved**. Use the dashboard's labels when operating the admin console and the user's labels when explaining the result to a reporter.

## 10. Online Services

The Online Services module aggregates requests from:

- Birth certificate appointments
- Marriage certificate appointments
- Death certificate appointments
- CENODEATH appointments
- CENOMAR appointments
- Facility borrow requests

The current mobile catalog visibly exposes Birth Certificate, Marriage Certificate, Death Certificate, and CENODEATH. CENOMAR and facility requests may still exist in backend tables or older/other flows, so use the category and record details to identify the source.

### Review a request

1. Open **Online Services**.
2. Search or filter by category, status, and date.
3. Open the request details.
4. Confirm the applicant's contact details, requested service, appointment information, and notes.
5. Verify that the requested date and service information are complete.

### Service statuses

- **Pending:** Received and waiting for staff action.
- **Processing:** Being handled or checked.
- **Completed:** Finished or approved for completion.
- **Rejected:** Cannot be fulfilled; provide a reason or note.

### Update a request

1. Select **Edit** or the status action.
2. Set the appropriate status.
3. Add the status-change reason or approval note where applicable.
4. Save the request.
5. Confirm that it appears in the correct filtered status list.

Use **Completed** only when the responsible office has actually finished its action. Use **Rejected** with a concise, factual reason that the requester can understand.

## 11. Transparency Records

Use **Transparency** to publish public records.

### Add or edit a record

1. Open **Transparency**.
2. Select **Add Record** or edit an existing record.
3. Select the record type, such as **Annual Budget**, **Bids**, **Executive Orders**, **Financial Reports**, **Legislative Ordinances**, or **Programs**.
4. Enter the **Title** and **Description**.
5. Upload the PDF document.
6. Set the **Display Order** if needed.
7. Select **Publish Record** when the document is ready for public viewing.
8. Save and verify the published entry.

Confirm that the PDF opens and contains the intended final document before publishing.

## 12. Tourist Guide

Use **Tourist Guide** to maintain public destination records.

### Add or edit a destination

1. Open **Tourist Guide**.
2. Select **Add Destination** or edit an existing destination.
3. Enter the destination name, category, location, description, and coordinates.
4. Add contact number and website when applicable.
5. Upload the destination image.
6. Select **Featured Destination** when it should appear as featured.
7. Select **Publish Destination** when the record is ready.
8. Save and verify the mobile-facing details.

Use search and filters to locate destinations and manage reviews where the module provides them. Check coordinates and website links before publishing.

## 13. Manage Hotline

1. Open **Manage Hotline**.
2. Select **Add Hotline** or edit an existing entry.
3. Enter **Hotline Name**, **Category**, **Hotline Number(s)**, and **Description**.
4. Upload a logo when appropriate.
5. Save the entry.
6. Test the displayed number against the official source before publishing.

Remove obsolete numbers promptly. Emergency information should never be published without verification.

## 14. Manage Users

This module is available to super administrators.

### Find and edit a user

1. Open **Manage Users**.
2. Search by user details or filter by verification status.
3. Open the user record.
4. Edit **Full Name**, **Phone Number**, or **Address** when authorized and necessary.
5. Save the changes.

Available identity filters include **Verified**, **Pending**, **Rejected**, and **Not submitted**.

### Block or unblock a user

1. Open the user record.
2. Confirm the account and the reason for the action.
3. Select **Block** or **Unblock**.
4. Confirm the action.

A blocked user is prevented from using the mobile account and sees an account-blocked message at sign-in. Record the administrative reason in the approved internal process.

## 15. Review Identity Verification

Identity review is available from the user-management workflow.

1. Filter users by **Pending** or open the relevant user record.
2. Select the identity verification review action.
3. Confirm the applicant, email, submission date, full name, ID type, ID number, and date of birth.
4. Inspect the **Front**, **Back**, and **Selfie** images when present.
5. Compare the submitted information with the organization's verification requirements.
6. Select **Approve** when the submission meets requirements.
7. Select **Reject** when it does not meet requirements, and enter a specific **Rejection Reason**.
8. Confirm the update.

Approval sets the user's verification status to verified and unlocks protected mobile features. Rejection keeps those features locked and allows the user to correct and resubmit. Treat ID numbers, dates of birth, and images as confidential personal data; do not download, copy, or share them unnecessarily.

## 16. Manage Admin

This module is available to super administrators.

### Create an administrator role/account

1. Open **Manage Admin**.
2. Enter the administrator email and a temporary password according to local policy.
3. Enter the **Role Name**.
4. Select a **Feature Access** permission for a feature administrator, or select **Mark this role as Super Admin** for full access.
5. Use **Assign to Existing User** when the account already exists.
6. Review the access level carefully.
7. Save the role/account.
8. Tell the new administrator to sign in and change the temporary password immediately.

Grant the smallest access needed for the job. Do not assign super administrator access for routine content work.

## 17. Administrator Profile and Theme

Select the administrator name or avatar to open the profile modal. The profile supports:

- **Email Address** (read-only)
- **Full Name**
- **Role** (read-only)
- **Phone Number**
- **Address**
- **Bio**
- Password change fields

Save profile changes after checking the values. A new password must be at least eight characters, must match its confirmation, and must differ from the current password.

Use the moon/sun control to switch between light and dark mode. The preference is stored in the browser.

## 18. Notifications

Select the bell icon to open notifications. Opening the panel marks current notifications as read. Use the trash control to clear the local notification list. Notifications are operational prompts; verify the underlying record before taking action.

## 19. Logout and Session Safety

1. Select **Logout** in the sidebar.
2. Review the confirmation dialog.
3. Select the confirmation action.

The dashboard signs out through Supabase and returns to the login page. Always log out on shared or public computers. Do not leave the dashboard open with a super administrator session.

## 20. Recommended Daily Procedure

1. Sign in and review pending reports and services on the Dashboard.
2. Review pending identity submissions before protected-request processing when identity is relevant.
3. Process reports and online services using clear status notes.
4. Check newly published content for spelling, dates, images, and links.
5. Verify emergency hotline changes against official sources.
6. Review notifications and unusual activity.
7. Sign out when finished.

## 21. Troubleshooting

### The dashboard returns to login

The Supabase session may have expired or the browser may have blocked required storage. Sign in again and use a supported browser. Do not bypass authentication.

### A module is missing

The account may not have permission for that feature. Ask a super administrator to confirm the assigned role instead of changing browser storage manually.

### A saved record is not visible in the mobile app

Confirm that it is published, check the publish date/time, verify required files or links, and refresh the mobile app. Cached mobile content can remain visible until refreshed.

### A request status is confusing

Check the source category and the full request details. The admin console uses Pending, Processing, Completed, and Rejected, while the mobile app may display a simplified label.

### An upload fails

Check file type, file size, internet connection, and whether the storage service is available. Do not repeatedly submit a record if the database save succeeded; first search for the record.

## 22. Data Protection Checklist

- Use only authorized administrator accounts.
- Use strong, unique passwords and change temporary passwords immediately.
- Grant minimum required permissions.
- Do not share Supabase service credentials or keys.
- View identity documents only for a legitimate review.
- Do not export or store personal data locally unless policy requires it.
- Use clear, factual rejection reasons and resolution notes.
- Verify public information before publishing.
- Log out after each session.
