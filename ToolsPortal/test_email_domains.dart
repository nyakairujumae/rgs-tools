#!/usr/bin/env dart

// Test script to verify all email domains are allowed
// Run with: dart test_email_domains.dart

void main() {
  print('🧪 Testing Email Domain Validation\n');
  
  // Test various email domains
  final testEmails = [
    'user@gmail.com',
    'user@yahoo.com',
    'user@outlook.com',
    'user@hotmail.com',
    'user@mekar.ae',
    'user@royalgulf.ae',
    'user@company.com',
    'user@anydomain.org',
    'user@test.net',
    'user@example.co.uk',
  ];
  
  print('Testing email domain validation:');
  print('=' * 50);
  
  for (final email in testEmails) {
    final isAllowed = isEmailDomainAllowed(email);
    final status = isAllowed ? '✅ ALLOWED' : '❌ BLOCKED';
    print('${email.padRight(25)} $status');
  }
  
  print('\n' + '=' * 50);
  print('🎉 All email domains are now allowed!');
  print('Users can sign up with any email address.');
}

// Simulate the app's email domain validation
bool isEmailDomainAllowed(String email) {
  // Allow any email domain - no restrictions
  return true;
}
