# Supabase Email Configuration

To disable email confirmation requirement for user signup, you need to update the following settings in your Supabase dashboard:

## Steps to Disable Email Confirmation:

1. **Go to Supabase Dashboard**
   - Navigate to your project dashboard
   - Go to Authentication → Settings

2. **Disable Email Confirmation**
   - Find "Enable email confirmations" setting
   - **Turn OFF** the email confirmation toggle
   - Save the changes

3. **Alternative: Update Email Templates (Optional)**
   - If you want to keep email confirmation but customize the flow
   - Go to Authentication → Email Templates
   - Modify the "Confirm signup" template as needed

## Current App Behavior:

- ✅ **With Email Confirmation DISABLED**: Users will be automatically signed in after registration
- ⚠️ **With Email Confirmation ENABLED**: Users will see a message to check their email

## Security Considerations:

- Disabling email confirmation makes signup faster but less secure
- Consider your use case and security requirements
- You can always re-enable email confirmation later if needed

## Testing:

After making the Supabase changes:
1. Try signing up with a new account
2. User should be automatically logged in and redirected to the home screen
3. No email verification should be required

