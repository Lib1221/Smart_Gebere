import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get_it/get_it.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import '../services/logger_service.dart';
import '../services/connectivity_service.dart';
import '../services/offline_storage.dart';
import '../network/network_info.dart';
import '../utils/input_validator.dart';

// Repositories
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/farmer/data/repositories/farmer_repository_impl.dart';
import '../../features/farmer/domain/repositories/farmer_repository.dart';

// Use Cases
import '../../features/auth/domain/usecases/login_usecase.dart';
import '../../features/auth/domain/usecases/logout_usecase.dart';
import '../../features/auth/domain/usecases/signup_usecase.dart';
import '../../features/farmer/domain/usecases/get_farmer_usecase.dart';
import '../../features/farmer/domain/usecases/get_crops_usecase.dart';
import '../../features/farmer/domain/usecases/save_crop_usecase.dart';

/// Global service locator instance
final sl = GetIt.instance;

/// Initialize all dependencies
Future<void> initDependencies() async {
  // ═══════════════════════════════════════════════════════════════════════════
  // External Services
  // ═══════════════════════════════════════════════════════════════════════════
  
  // Firebase
  sl.registerLazySingleton<FirebaseAuth>(() => FirebaseAuth.instance);
  sl.registerLazySingleton<FirebaseFirestore>(() => FirebaseFirestore.instance);
  
  // HTTP Client
  sl.registerLazySingleton<http.Client>(() => http.Client());
  
  // Generative AI Model
  sl.registerLazySingleton<GenerativeModel>(() {
    final apiKey = dotenv.env['API_KEY'] ?? '';
    final modelName = dotenv.env['GEMINI_MODEL'] ?? 'gemini-1.5-flash';
    return GenerativeModel(
      model: modelName,
      apiKey: apiKey,
      safetySettings: [
        SafetySetting(HarmCategory.harassment, HarmBlockThreshold.high),
        SafetySetting(HarmCategory.hateSpeech, HarmBlockThreshold.high),
      ],
    );
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // Core Services
  // ═══════════════════════════════════════════════════════════════════════════
  
  // Logger (initialized first for debugging)
  sl.registerLazySingleton<LoggerService>(() => LoggerService());
  
  // Network Info
  sl.registerLazySingleton<NetworkInfo>(() => NetworkInfoImpl(
    connectivityService: sl<ConnectivityService>(),
  ));
  
  // Connectivity Service (already initialized in main.dart, register existing instance)
  // This will be registered from main.dart using registerSingleton
  
  // Input Validator
  sl.registerLazySingleton<InputValidator>(() => InputValidator());

  // ═══════════════════════════════════════════════════════════════════════════
  // Repositories
  // ═══════════════════════════════════════════════════════════════════════════
  
  sl.registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl(
    firebaseAuth: sl<FirebaseAuth>(),
    firestore: sl<FirebaseFirestore>(),
    logger: sl<LoggerService>(),
  ));
  
  sl.registerLazySingleton<FarmerRepository>(() => FarmerRepositoryImpl(
    firestore: sl<FirebaseFirestore>(),
    auth: sl<FirebaseAuth>(),
    networkInfo: sl<NetworkInfo>(),
    logger: sl<LoggerService>(),
  ));

  // ═══════════════════════════════════════════════════════════════════════════
  // Use Cases - Auth
  // ═══════════════════════════════════════════════════════════════════════════
  
  sl.registerLazySingleton<LoginUseCase>(() => LoginUseCase(
    repository: sl<AuthRepository>(),
  ));
  
  sl.registerLazySingleton<LogoutUseCase>(() => LogoutUseCase(
    repository: sl<AuthRepository>(),
  ));
  
  sl.registerLazySingleton<SignupUseCase>(() => SignupUseCase(
    repository: sl<AuthRepository>(),
  ));

  // ═══════════════════════════════════════════════════════════════════════════
  // Use Cases - Farmer
  // ═══════════════════════════════════════════════════════════════════════════
  
  sl.registerLazySingleton<GetFarmerUseCase>(() => GetFarmerUseCase(
    repository: sl<FarmerRepository>(),
  ));
  
  sl.registerLazySingleton<GetCropsUseCase>(() => GetCropsUseCase(
    repository: sl<FarmerRepository>(),
  ));
  
  sl.registerLazySingleton<SaveCropUseCase>(() => SaveCropUseCase(
    repository: sl<FarmerRepository>(),
  ));
}

/// Register the connectivity service (called from main.dart after initialization)
void registerConnectivityService(ConnectivityService service) {
  if (!sl.isRegistered<ConnectivityService>()) {
    sl.registerSingleton<ConnectivityService>(service);
  }
}

/// Reset all dependencies (for testing)
Future<void> resetDependencies() async {
  await sl.reset();
}

