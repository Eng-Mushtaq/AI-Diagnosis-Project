# Doctor-User Data Integrity Fix Guide

This guide provides multiple approaches to fix the data integrity issues between the `doctors` and `users` tables in your Supabase database.

## The Problem

The application is encountering a data integrity issue where there are records in the `doctors` table but no corresponding records in the `users` table with the same IDs. This is causing the error:

```
DATA INTEGRITY ISSUE: No user records found for approved doctors
```

## Solution 1: Using the Supabase Dashboard SQL Editor (Recommended)

This is the most direct and reliable approach since it bypasses Row-Level Security (RLS) policies.

1. Log in to your Supabase dashboard
2. Go to the SQL Editor
3. Copy and paste the contents of `fix_doctor_integrity_admin.sql`
4. Run the SQL script
5. Verify the results

## Solution 2: Adding Admin Functions to Supabase

If you need to fix this issue programmatically from your application:

1. Log in to your Supabase dashboard
2. Go to the SQL Editor
3. Copy and paste the contents of `admin_functions.sql`
4. Run the SQL script to create the admin functions
5. Use the "Fix Data Integrity" button in your application

## Solution 3: Manual Fix Through Supabase Dashboard

If you prefer a more manual approach:

1. Log in to your Supabase dashboard
2. Go to the "Table Editor"
3. Open the `doctors` table and note the IDs of all doctors
4. Open the `users` table
5. For each doctor ID that doesn't have a corresponding user record:
   - Click "Insert row"
   - Set the `id` to match the doctor's ID
   - Set `user_type` to "doctor"
   - Set `email` to a unique email (e.g., `doctor_[first 8 chars of ID]@example.com`)
   - Set `name` to a default name (e.g., "Dr. Unknown")
   - Fill in any other required fields
   - Click "Save"

## Solution 4: Using the Auth API (For Developers)

If you're a developer and want to fix this programmatically:

1. Use the `DoctorIntegrityFixerAlternative` class provided in `lib/utils/doctor_integrity_fixer_alternative.dart`
2. This approach creates new auth users and tries to link them to existing doctor records
3. Note that this approach may require additional admin privileges to fully link the users

## Troubleshooting

### RLS Policy Errors

If you see errors like:

```
PostgrestException(message: new row violates row-level security policy for table "users", code: 42501, details: Forbidden, hint: null)
```

This means you're trying to insert or update records in a table that has Row-Level Security (RLS) policies that prevent the operation. Use Solution 1 or 2 to bypass these policies.

### Auth API Errors

If you see errors related to the Auth API, such as:

```
Failed to create auth user
```

This could be due to:
- Email already in use
- Password requirements not met
- Rate limiting
- Network issues

Try using Solution 1 or 3 instead.

## Preventing Future Issues

To prevent these issues in the future:

1. Always create user records before or at the same time as doctor records
2. Use transactions to ensure both records are created or neither is
3. Add database triggers to maintain referential integrity
4. Add validation in your application code to check for data integrity issues

## Need Help?

If you continue to experience issues, please:

1. Check the application logs for specific error messages
2. Verify your Supabase configuration
3. Ensure your application has the necessary permissions
4. Contact Supabase support if you need help with database-level issues
