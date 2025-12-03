class AuthService {
  // In a real app, this would handle API calls
  Future<Map<String, dynamic>> login(
    String email,
    String password,
    String role,
  ) async {
    await Future.delayed(const Duration(seconds: 1));
    
    // Mock response
    return {
      'success': true,
      'token': 'mock_jwt_token',
      'user': {
        'id': '1',
        'name': 'User',
        'email': email,
        'role': role,
      },
    };
  }

  Future<void> logout() async {
    await Future.delayed(const Duration(milliseconds: 500));
  }
}