# Doctor-User Data Integrity Prevention Guide

This guide provides a comprehensive approach to prevent data integrity issues between the `doctors` and `users` tables in your Supabase database.

## Understanding the Problem

The fundamental issue is that doctors are being created in the `doctors` table without corresponding records in the `users` table. This happens because:

1. The `doctors` table has a foreign key reference to the `users` table
2. When creating a doctor, the application should first create a user record, then create the doctor record with the same ID
3. The current implementation is missing this step or has a race condition

## Solution Overview

We've implemented a multi-layered approach to prevent these issues:

1. **Database Triggers**: Automatically ensure data integrity at the database level
2. **Stored Procedures**: Provide atomic operations for creating doctors with users
3. **Application Code Improvements**: Enhance the user creation process
4. **Verification Mechanisms**: Add checks to detect and fix issues early

## Implementation Steps

### 1. Database Triggers and Constraints

Apply the SQL script `doctor_user_integrity_prevention.sql` to your Supabase database:

1. Log in to your Supabase dashboard
2. Go to the SQL Editor
3. Copy and paste the contents of `doctor_user_integrity_prevention.sql`
4. Run the SQL script

This script adds:
- Triggers to ensure every doctor has a corresponding user record
- Functions to automatically create missing user records
- Constraints to ensure verification_status is always lowercase
- Validation to prevent data integrity issues

### 2. Stored Procedures

Apply the SQL script `create_doctor_stored_procedure.sql` to your Supabase database:

1. Log in to your Supabase dashboard
2. Go to the SQL Editor
3. Copy and paste the contents of `create_doctor_stored_procedure.sql`
4. Run the SQL script

This creates a stored procedure that:
- Creates a doctor record with a user in a single transaction
- Updates the user_type to 'doctor' if needed
- Handles both new and existing records

### 3. Application Code Improvements

We've enhanced the `createUserProfile` method in `SupabaseService` to:

1. Use the stored procedure when creating doctors
2. Fall back to a more robust direct insert method if the stored procedure is unavailable
3. Add verification steps to ensure data integrity
4. Include better error handling and logging

### 4. Testing the Solution

To verify that the solution works:

1. Register a new doctor user through the app
2. Check the database to ensure both user and doctor records are created
3. Try creating a doctor record directly and verify that a user record is automatically created
4. Update a doctor's verification status and verify it's always stored in lowercase

## Troubleshooting

### Common Issues

1. **RLS Policy Errors**: If you see errors related to Row-Level Security (RLS) policies, you may need to:
   - Run the SQL scripts from the Supabase dashboard
   - Modify the RLS policies to allow the necessary operations
   - Use the SECURITY DEFINER option for functions that need to bypass RLS

2. **Missing Stored Procedure**: If the application can't find the stored procedure:
   - Verify that the procedure was created successfully
   - Check for any SQL errors during creation
   - The application will fall back to direct inserts

3. **Transaction Errors**: If you see errors related to transactions:
   - Check that all tables involved in the transaction exist
   - Verify that the user has the necessary permissions
   - Ensure that the transaction isn't too complex

## Best Practices for Maintaining Data Integrity

1. **Always Use Transactions**: When creating related records, use transactions to ensure atomicity
2. **Validate Data**: Add validation at both the application and database levels
3. **Use Triggers Carefully**: Triggers are powerful but can have unexpected side effects
4. **Monitor Errors**: Set up logging and monitoring to detect issues early
5. **Regular Audits**: Periodically check for data integrity issues

## Future Improvements

Consider these additional improvements:

1. **Add More Constraints**: Add CHECK constraints to ensure data validity
2. **Improve Error Messages**: Make error messages more descriptive
3. **Add Audit Logging**: Track changes to critical tables
4. **Implement Data Validation**: Add more validation at the application level
5. **Create Admin Tools**: Build tools to help administrators fix data issues
