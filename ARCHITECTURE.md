# Flutter Clean Architecture - Project Structure

## Complete Folder Structure

```
catchybus/
├── lib/
│   ├── main.dart                          # App entry point
│   │
│   ├── config/                            # App Configuration
│   │   ├── routes/
│   │   │   └── app_router.dart           # GoRouter configuration
│   │   └── theme/
│   │       └── app_theme.dart            # Theme & CatchyBus brand colors
│   │
│   ├── core/                              # Core Utilities
│   │   ├── constants/
│   │   │   ├── api_constants.dart        # API endpoints & timeouts
│   │   │   └── app_constants.dart        # App-wide constants
│   │   ├── di/
│   │   │   └── injection.dart            # Dependency injection setup
│   │   ├── error/
│   │   │   ├── exceptions.dart           # Data layer exceptions
│   │   │   └── failures.dart             # Domain layer failures
│   │   ├── network/
│   │   │   ├── dio_client.dart           # HTTP client wrapper
│   │   │   └── network_info.dart         # Network connectivity check
│   │   └── usecases/
│   │       └── usecase.dart              # Base UseCase interface
│   │
│   └── features/                          # Feature Modules
│       └── auth/                          # Authentication Feature
│           ├── data/                      # Data Layer
│           │   ├── datasources/
│           │   │   └── auth_remote_datasource.dart
│           │   ├── models/
│           │   │   ├── auth_response_model.dart
│           │   │   ├── auth_response_model.g.dart (generated)
│           │   │   ├── user_model.dart
│           │   │   └── user_model.g.dart (generated)
│           │   └── repositories/
│           │       └── auth_repository_impl.dart
│           │
│           ├── domain/                    # Domain Layer
│           │   ├── entities/
│           │   │   └── user_entity.dart
│           │   ├── repositories/
│           │   │   └── auth_repository.dart
│           │   └── usecases/
│           │       ├── login_usecase.dart
│           │       └── register_usecase.dart
│           │
│           └── presentation/              # Presentation Layer
│               ├── pages/
│               │   ├── home_page.dart
│               │   └── login_page.dart
│               ├── providers/
│               │   └── auth_provider.dart
│               └── widgets/
│                   └── (custom widgets)
│
├── test/                                  # Tests
│   └── widget_test.dart
│
├── android/                               # Android platform files
├── ios/                                   # iOS platform files
├── web/                                   # Web platform files
├── linux/                                 # Linux platform files
├── macos/                                 # macOS platform files
├── windows/                               # Windows platform files
│
├── pubspec.yaml                           # Dependencies
├── build.yaml                             # Build configuration
├── analysis_options.yaml                  # Linter rules
└── README.md                              # Documentation
```

## Layer Dependencies Flow

```
┌─────────────────────────────────────────────────────────┐
│                   PRESENTATION LAYER                     │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  │
│  │    Pages     │  │   Providers  │  │   Widgets    │  │
│  └──────────────┘  └──────────────┘  └──────────────┘  │
└─────────────────────────────────────────────────────────┘
                          ↓ uses
┌─────────────────────────────────────────────────────────┐
│                     DOMAIN LAYER                         │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  │
│  │  Use Cases   │  │ Repositories │  │   Entities   │  │
│  │              │  │ (Interfaces) │  │              │  │
│  └──────────────┘  └──────────────┘  └──────────────┘  │
└─────────────────────────────────────────────────────────┘
                          ↑ implements
┌─────────────────────────────────────────────────────────┐
│                      DATA LAYER                          │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  │
│  │ Data Sources │  │    Models    │  │ Repositories │  │
│  │              │  │    (DTOs)    │  │    (Impl)    │  │
│  └──────────────┘  └──────────────┘  └──────────────┘  │
└─────────────────────────────────────────────────────────┘
```

## CatchyBus Brand Colors

| Color Name      | Hex Code  | Usage                    |
|----------------|-----------|--------------------------|
| Primary Yellow | #F9C300   | Bus body, brand identity |
| Deep Blue      | #1E4FA3   | Primary text, headers    |
| Bright Orange  | #F57C00   | Buttons, highlights      |
| Location Red   | #E53935   | GPS pin, alerts          |
| Dark Charcoal  | #212121   | Body text, icons         |
| White          | #FFFFFF   | Backgrounds              |

## Key Files Explained

### Entry Point
- **main.dart**: Initializes dependencies, wraps app with ProviderScope, configures routing

### Core Layer
- **usecase.dart**: Base interface for all use cases with `Either<Failure, T>` return type
- **failures.dart**: Domain layer error types (ServerFailure, NetworkFailure, etc.)
- **exceptions.dart**: Data layer exception types
- **dio_client.dart**: HTTP client with interceptors for logging and auth
- **injection.dart**: GetIt service locator setup

### Feature: Authentication

#### Domain Layer (Business Logic)
- **user_entity.dart**: Pure business model
- **auth_repository.dart**: Repository interface (contract)
- **login_usecase.dart**: Login business logic
- **register_usecase.dart**: Registration business logic

#### Data Layer (Data Management)
- **user_model.dart**: DTO with JSON serialization
- **auth_response_model.dart**: API response model
- **auth_remote_datasource.dart**: API calls implementation
- **auth_repository_impl.dart**: Repository implementation with error handling

#### Presentation Layer (UI)
- **auth_provider.dart**: Riverpod StateNotifier for auth state
- **login_page.dart**: Login UI with form validation
- **home_page.dart**: Home screen after login

## Data Flow Example: Login

```
1. User taps Login button
   ↓
2. LoginPage calls ref.read(authProvider.notifier).login()
   ↓
3. AuthNotifier calls LoginUseCase
   ↓
4. LoginUseCase calls AuthRepository.login()
   ↓
5. AuthRepositoryImpl checks network
   ↓
6. AuthRemoteDataSource makes API call via DioClient
   ↓
7. Response converted: Model → Entity
   ↓
8. Either<Failure, UserEntity> returned up the chain
   ↓
9. AuthNotifier updates state
   ↓
10. LoginPage rebuilds with new state
```

## Code Generation Files

Generated files (*.g.dart, *.freezed.dart):
- `user_model.g.dart` - JSON serialization for UserModel
- `auth_response_model.g.dart` - JSON serialization for AuthResponseModel

Run generation:
```bash
dart run build_runner build --delete-conflicting-outputs
```

## Testing Strategy

### Unit Tests (Domain Layer)
- Test use cases with mock repositories
- No external dependencies needed

### Integration Tests (Data Layer)
- Test repository implementations
- Mock data sources

### Widget Tests (Presentation Layer)
- Test UI components
- Mock providers with Riverpod overrides

## Adding a New Feature

1. Create folder structure:
   ```
   features/
   └── new_feature/
       ├── data/
       │   ├── datasources/
       │   ├── models/
       │   └── repositories/
       ├── domain/
       │   ├── entities/
       │   ├── repositories/
       │   └── usecases/
       └── presentation/
           ├── pages/
           ├── providers/
           └── widgets/
   ```

2. Follow the same pattern as auth feature
3. Register dependencies in `injection.dart`
4. Add routes in `app_router.dart`

## Best Practices Checklist

- ✅ Domain layer has no external dependencies
- ✅ Use Either<Failure, Success> for error handling
- ✅ Repository pattern for data abstraction
- ✅ Use cases for single-responsibility business logic
- ✅ Riverpod for reactive state management
- ✅ Dependency injection with GetIt
- ✅ Code generation for boilerplate reduction
- ✅ Consistent naming conventions
- ✅ Proper error handling at each layer
- ✅ Theme-based UI with brand colors
