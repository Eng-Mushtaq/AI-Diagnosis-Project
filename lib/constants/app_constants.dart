// App constants for the healthcare consultation app

class AppConstants {
  // App name
  static const String appName = 'AI Diagnosist';
  
  // API endpoints (mock)
  static const String baseUrl = 'https://api.aidiagnosist.com';
  static const String loginEndpoint = '/auth/login';
  static const String registerEndpoint = '/auth/register';
  static const String healthDataEndpoint = '/health-data';
  static const String symptomsEndpoint = '/symptoms';
  static const String diseasePredictionEndpoint = '/disease-prediction';
  static const String doctorsEndpoint = '/doctors';
  static const String appointmentsEndpoint = '/appointments';
  static const String labResultsEndpoint = '/lab-results';
  
  // Shared preferences keys
  static const String tokenKey = 'token';
  static const String userIdKey = 'userId';
  static const String userNameKey = 'userName';
  
  // Validation constants
  static const int minPasswordLength = 8;
  static const int maxSymptomLength = 500;
  
  // Health data ranges
  static const double minTemperature = 35.0;
  static const double maxTemperature = 42.0;
  static const int minHeartRate = 40;
  static const int maxHeartRate = 200;
  static const int minSystolicBP = 70;
  static const int maxSystolicBP = 200;
  static const int minDiastolicBP = 40;
  static const int maxDiastolicBP = 120;
  
  // Mock data delay (milliseconds)
  static const int mockDataDelay = 1000;
}
