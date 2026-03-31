import 'dart:convert';
import 'package:catchybus/features/auth/data/models/user_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import '../../../../firebase_options.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/constants/app_constants.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../../../core/services/notification_service.dart';
import '../../domain/repositories/auth_repository.dart';

/// Auth state
class AuthState {
  final bool isLoading;
  final UserEntity? user;
  final String? error;
  final bool isAuthenticated;
  final String? verificationId;
  final String? lastIdToken;
  final String? lastPhone;
  final String? lastRole;

  AuthState({
    this.isLoading = false,
    this.user,
    this.error,
    this.isAuthenticated = false,
    this.verificationId,
    this.lastIdToken,
    this.lastPhone,
    this.lastRole,
  });

  AuthState copyWith({
    bool? isLoading,
    UserEntity? user,
    String? error,
    bool? isAuthenticated,
    String? verificationId,
    String? lastIdToken,
    String? lastPhone,
    String? lastRole,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      user: user ?? this.user,
      error: error,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      verificationId: verificationId ?? this.verificationId,
      lastIdToken: lastIdToken ?? this.lastIdToken,
      lastPhone: lastPhone ?? this.lastPhone,
      lastRole: lastRole ?? this.lastRole,
    );
  }
}

/// Auth provider using Riverpod
class AuthNotifier extends StateNotifier<AuthState> {
  final LoginUseCase loginUseCase;
  final AuthRepository authRepository;
  final SharedPreferences _prefs;
  final PushNotificationService _notificationService;

  AuthNotifier(
    this.loginUseCase,
    this.authRepository,
    this._prefs,
    this._notificationService,
  ) : super(AuthState()) {
    checkAuthStatus();
  }

  /// Check if user is already logged in
  void checkAuthStatus() {
    final userData = _prefs.getString(AppConstants.keyUserData);
    final isLoggedIn = _prefs.getBool(AppConstants.keyIsLoggedIn) ?? false;

    if (isLoggedIn && userData != null) {
      try {
        final userModel = UserModel.fromJson(jsonDecode(userData));
        final phone = _prefs.getString(AppConstants.keyUserPhone);
        final role = _prefs.getString(AppConstants.keyUserRole);
        final idToken = _prefs.getString(AppConstants.keyIdToken);

        state = state.copyWith(
          user: userModel.toEntity(),
          isAuthenticated: true,
          lastPhone: phone,
          lastRole: role,
          lastIdToken: idToken,
        );

        // Always refresh FCM token on startup — server may restart and lose token
        _notificationService.updateToken();
      } catch (e) {
        // If parsing fails, clear state
        logout();
      }
    }
  }

  /// Login method
  Future<void> login(
    String emailOrPhone, {
    String? password,
    String? idToken,
    required String role,
    String? selectedUserId,
  }) async {
    state = state.copyWith(
      isLoading: true,
      error: null,
      lastIdToken: idToken,
      lastPhone: emailOrPhone,
      lastRole: role,
    );

    final result = await loginUseCase(
      LoginParams(
        emailOrPhone: emailOrPhone,
        password: password,
        idToken: idToken,
        role: role,
        selectedUserId: selectedUserId,
      ),
    );

    result.fold(
      (failure) {
        state = state.copyWith(
          isLoading: false,
          error: failure.message,
          isAuthenticated: false,
        );
      },
      (user) async {
        // Save to SharedPreferences
        await _prefs.setBool(AppConstants.keyIsLoggedIn, true);
        await _prefs.setString(
          AppConstants.keyUserData,
          jsonEncode(UserModel.fromEntity(user).toJson()),
        );
        if (emailOrPhone.isNotEmpty)
          await _prefs.setString(AppConstants.keyUserPhone, emailOrPhone);
        if (role.isNotEmpty)
          await _prefs.setString(AppConstants.keyUserRole, role);
        if (idToken != null)
          await _prefs.setString(AppConstants.keyIdToken, idToken);

        state = state.copyWith(
          isLoading: false,
          user: user,
          isAuthenticated: true,
          error: null,
          lastPhone: emailOrPhone,
          lastRole: role,
          lastIdToken: idToken,
        );

        // Update FCM token on server
        await _notificationService.updateToken();
      },
    );
  }

  /// Select one of the multiple accounts
  Future<void> selectAccount(String userId) async {
    // Attempt recovery from existing state/firebase if metadata is missing
    final phone = state.lastPhone ?? state.user?.phone;
    final role = state.lastRole ?? state.user?.type;
    // Force refresh idToken from Firebase to ensure it's not expired
    final freshToken = await FirebaseAuth.instance.currentUser?.getIdToken(
      true,
    );
    final idToken = freshToken ?? state.lastIdToken;

    if (idToken == null || phone == null || role == null) {
      state = state.copyWith(
        error: "Session data missing. Please logout and login again.",
      );
      return;
    }

    await login(phone, idToken: idToken, role: role, selectedUserId: userId);
  }

  /// Send OTP using Firebase
  Future<void> sendOtp(String phoneNumber, String role) async {
    state = state.copyWith(isLoading: true, error: null, lastRole: role, lastPhone: phoneNumber);
    try {
      // Check if phone number is registered in the system before sending OTP
      final isInSystem = await authRepository.checkPhoneInSystem(phoneNumber, role);
      if (!isInSystem) {
        state = state.copyWith(
          isLoading: false,
          error: 'This number is not registered in the system. Please contact your college transport office.',
        );
        return;
      }

      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: phoneNumber.startsWith('+')
            ? phoneNumber
            : '+91$phoneNumber',
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Auto-verify on certain Android devices
          final userCredential = await FirebaseAuth.instance
              .signInWithCredential(credential);
          final idToken = await userCredential.user?.getIdToken();
          if (idToken != null) {
            await login(
              phoneNumber,
              idToken: idToken,
              role: role,
            );
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          state = state.copyWith(
            isLoading: false,
            error: e.code == 'invalid-app-credential'
                ? 'App verification failed. Please check your SHA-1 configuration.'
                : e.message,
          );
        },
        codeSent: (String verificationId, int? resendToken) {
          state = state.copyWith(
            isLoading: false,
            verificationId: verificationId,
          );
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          state = state.copyWith(verificationId: verificationId);
        },
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Verify OTP and then call our backend login
  Future<void> verifyOtp(String smsCode, String role, String phone) async {
    if (state.verificationId == null) {
      state = state.copyWith(
        error: "Verification ID is missing. Please request OTP again.",
      );
      return;
    }
    state = state.copyWith(isLoading: true, error: null);
    try {
      // Defensive check for Firebase initialization state
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
      }

      final credential = PhoneAuthProvider.credential(
        verificationId: state.verificationId!,
        smsCode: smsCode,
      );

      final userCredential = await FirebaseAuth.instance.signInWithCredential(
        credential,
      );
      final idToken = await userCredential.user?.getIdToken();

      if (idToken != null) {
        await login(phone, idToken: idToken, role: role);
      } else {
        state = state.copyWith(
          isLoading: false,
          error: "Failed to get Firebase token",
        );
      }
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Update notification settings
  Future<void> updateNotificationSettings(Map<String, bool> settings) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await authRepository.updateNotificationSettings(settings);

    result.fold(
      (failure) {
        state = state.copyWith(isLoading: false, error: failure.message);
      },
      (_) {
        state = state.copyWith(isLoading: false);
      },
    );
  }

  /// Logout method
  Future<void> logout() async {
    await _prefs.remove(AppConstants.keyIsLoggedIn);
    await _prefs.remove(AppConstants.keyUserData);
    await _prefs.remove(AppConstants.keyAccessToken);
    await _prefs.remove(AppConstants.keyRefreshToken);
    await _prefs.remove(AppConstants.keyUserId);
    await _prefs.remove(AppConstants.keyUserPhone);
    await _prefs.remove(AppConstants.keyUserRole);
    await _prefs.remove(AppConstants.keyIdToken);
    await FirebaseAuth.instance.signOut();
    state = AuthState();
  }
}

/// Provider for AuthNotifier
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final notificationService = ref.watch(notificationServiceProvider);
  final loginUseCase = getIt<LoginUseCase>();
  return AuthNotifier(
    loginUseCase,
    loginUseCase.repository, // AuthRepository
    getIt<SharedPreferences>(),
    notificationService,
  );
});
