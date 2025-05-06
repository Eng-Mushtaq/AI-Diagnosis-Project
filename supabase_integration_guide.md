# Supabase Integration Guide for AI Diagnosist

This guide explains how to set up the Supabase backend for the AI Diagnosist application and integrate it with the Flutter frontend.

## Database Setup

### 1. Create a Supabase Project

1. Go to [Supabase](https://supabase.com/) and sign up or log in
2. Create a new project
3. Note your project URL and API keys (you'll need these later)

### 2. Run the SQL Script

1. Navigate to the SQL Editor in your Supabase dashboard
2. Copy the contents of `supabase_schema.sql` 
3. Paste it into the SQL Editor
4. Run the script to create all tables, relationships, policies, and indexes

### 3. Enable Authentication

1. Go to Authentication settings in your Supabase dashboard
2. Enable Email/Password authentication
3. Configure any additional authentication providers as needed (Google, Apple, etc.)
4. Set up email templates for verification, password reset, etc.

## Flutter Integration

### 1. Install Supabase Flutter Package

Add the following dependencies to your `pubspec.yaml`:

```yaml
dependencies:
  supabase_flutter: ^latest_version
  flutter_secure_storage: ^latest_version
```

Run `flutter pub get` to install the packages.

### 2. Initialize Supabase in Your App

Create a Supabase client in your app:

```dart
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> initializeSupabase() async {
  await Supabase.initialize(
    url: 'YOUR_SUPABASE_URL',
    anonKey: 'YOUR_SUPABASE_ANON_KEY',
  );
}

// Access the client
final supabase = Supabase.instance.client;
```

Add this initialization to your `main.dart` before running the app.

### 3. Update Auth Controller

Replace the mock authentication with Supabase authentication:

```dart
// Example authentication with Supabase
Future<bool> login(String email, String password) async {
  _isLoading.value = true;
  _errorMessage.value = '';

  try {
    // Validate inputs
    if (email.isEmpty || password.isEmpty) {
      _errorMessage.value = 'Email and password are required';
      return false;
    }

    // Sign in with Supabase
    final response = await supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );

    if (response.error != null) {
      _errorMessage.value = response.error!.message;
      return false;
    }

    // Get user data from the database
    final userData = await supabase
        .from('users')
        .select('*, patients(*), doctors(*), admins(*)')
        .eq('id', response.user!.id)
        .single();

    // Parse user type
    UserType userType = UserType.values.firstWhere(
      (e) => e.toString().split('.').last == userData['user_type'],
      orElse: () => UserType.patient,
    );

    // Create user model based on type
    _user.value = _createUserModelFromData(userData, userType);
    return true;
  } catch (e) {
    _errorMessage.value = 'Login failed: ${e.toString()}';
    return false;
  } finally {
    _isLoading.value = false;
  }
}
```

### 4. Update Data Services

Replace the mock data services with Supabase queries:

```dart
// Example: Get user health data
Future<List<HealthDataModel>> getUserHealthData(String userId) async {
  try {
    final data = await supabase
        .from('health_data')
        .select('*')
        .eq('user_id', userId)
        .order('timestamp', ascending: false);

    return data.map((item) => HealthDataModel.fromJson(item)).toList();
  } catch (e) {
    throw Exception('Failed to get health data: ${e.toString()}');
  }
}

// Example: Create a new symptom
Future<SymptomModel> addSymptom(SymptomModel symptom) async {
  try {
    // Insert the main symptom record
    final response = await supabase.from('symptoms').insert({
      'user_id': symptom.userId,
      'description': symptom.description,
      'severity': symptom.severity,
      'duration': symptom.duration,
      'notes': symptom.notes,
    }).select().single();

    final symptomId = response['id'];

    // Insert body parts if available
    if (symptom.bodyParts != null && symptom.bodyParts!.isNotEmpty) {
      await supabase.from('symptom_body_parts').insert(
        symptom.bodyParts!.map((part) => {
          'symptom_id': symptomId,
          'body_part': part,
        }).toList(),
      );
    }

    // Insert associated factors if available
    if (symptom.associatedFactors != null && symptom.associatedFactors!.isNotEmpty) {
      await supabase.from('symptom_associated_factors').insert(
        symptom.associatedFactors!.map((factor) => {
          'symptom_id': symptomId,
          'factor': factor,
        }).toList(),
      );
    }

    // Get the complete symptom with all related data
    return getSymptomById(symptomId);
  } catch (e) {
    throw Exception('Failed to add symptom: ${e.toString()}');
  }
}
```

## Handling User Types

Since the application has three user types (patients, doctors, and admins), you'll need to handle them appropriately:

1. During registration, create records in both the `users` table and the corresponding type-specific table
2. When fetching user data, join the tables to get all relevant information
3. Use the user type to determine which screens to show and what actions are allowed

## Security Considerations

1. The SQL script includes Row Level Security (RLS) policies to protect data
2. Always use the authenticated Supabase client for database operations
3. Validate inputs on both client and server sides
4. Use Supabase Storage for secure file uploads (lab results, symptom images, etc.)

## Next Steps

1. Implement real-time features using Supabase Realtime (for chat messages, appointment updates, etc.)
2. Set up Supabase Edge Functions for server-side logic (AI diagnosis processing, etc.)
3. Configure Supabase Storage for file uploads
4. Implement proper error handling and offline capabilities
