# CatchyBus - Flutter Clean Architecture Boilerplate

A production-ready Flutter application boilerplate with **Clean Architecture**, **Riverpod** state management, and **Use Cases** pattern.

## 🏗️ Architecture Overview

This project follows **Clean Architecture** principles with three main layers:

```
lib/
├── core/                      # Core functionality
│   ├── constants/            # App-wide constants
│   ├── di/                   # Dependency injection
│   ├── error/                # Error handling (failures & exceptions)
│   ├── network/              # Network utilities (Dio client)
│   └── usecases/             # Base use case interface
├── features/                 # Feature modules
│   └── auth/                # Authentication feature
│       ├── data/            # Data layer
│       │   ├── datasources/ # Remote/Local data sources
│       │   ├── models/      # Data models (DTOs)
│       │   └── repositories/# Repository implementations
│       ├── domain/          # Domain layer (Business logic)
│       │   ├── entities/    # Business entities
│       │   ├── repositories/# Repository interfaces
│       │   └── usecases/    # Use cases
│       └── presentation/    # Presentation layer (UI)
│           ├── pages/       # UI pages
│           ├── providers/   # Riverpod providers
│           └── widgets/     # Reusable widgets
└── config/                   # App configuration
    ├── routes/              # Routing configuration
    └── theme/               # Theme configuration
```

### Layer Responsibilities

#### 1. **Domain Layer** (Business Logic)
- **Entities**: Pure Dart classes representing business models
- **Repositories**: Abstract interfaces defining data operations
- **Use Cases**: Single-responsibility business logic operations
- **No dependencies** on other layers or external packages

#### 2. **Data Layer** (Data Management)
- **Models**: Data Transfer Objects (DTOs) with JSON serialization
- **Data Sources**: API calls, local storage operations
- **Repository Implementations**: Concrete implementations of domain repositories
- **Error handling**: Converts exceptions to failures

#### 3. **Presentation Layer** (UI)
- **Pages**: Screen widgets
- **Providers**: Riverpod state management
- **Widgets**: Reusable UI components
- **Consumes use cases** through dependency injection

## 📦 Key Packages

### State Management
- **flutter_riverpod**: Modern, reactive state management
- **riverpod_annotation**: Code generation for providers

### Networking
- **dio**: HTTP client for API calls
- **logger**: Logging utility

### Functional Programming
- **dartz**: Functional programming (Either, Option, etc.)

### Dependency Injection
- **get_it**: Service locator for dependency injection
- **injectable**: Code generation for DI

### Code Generation
- **build_runner**: Code generation runner
- **freezed**: Immutable data classes
- **json_serializable**: JSON serialization

### Utilities
- **equatable**: Value equality
- **shared_preferences**: Local storage
- **go_router**: Declarative routing
- **flutter_screenutil**: Responsive UI

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (3.38.3 or higher)
- Dart SDK (3.10.1 or higher)

### Installation

1. **Clone the repository**
```bash
cd catchybus
```

2. **Install dependencies**
```bash
flutter pub get
```

3. **Run code generation**
```bash
dart run build_runner build --delete-conflicting-outputs
```

4. **Run the app**
```bash
flutter run
```

## 🔧 Code Generation

This project uses code generation for:
- JSON serialization (`json_serializable`)
- Freezed data classes (`freezed`)
- Riverpod providers (`riverpod_generator`)

**Run code generation:**
```bash
# One-time build
dart run build_runner build --delete-conflicting-outputs

# Watch mode (auto-regenerate on file changes)
dart run build_runner watch --delete-conflicting-outputs
```

## 📝 Project Structure Explained

### Core Module

#### Error Handling
- **Failures** (`lib/core/error/failures.dart`): Domain layer errors
  - `ServerFailure`, `NetworkFailure`, `CacheFailure`, etc.
- **Exceptions** (`lib/core/error/exceptions.dart`): Data layer exceptions
  - `ServerException`, `NetworkException`, `CacheException`, etc.

#### Use Cases
- **Base UseCase** (`lib/core/usecases/usecase.dart`): 
  - Generic interface: `UseCase<Type, Params>`
  - Returns `Either<Failure, Type>` for functional error handling

#### Dependency Injection
- **Injection** (`lib/core/di/injection.dart`):
  - Centralized DI setup using GetIt
  - Registers all dependencies (data sources, repositories, use cases)

### Features Module

Each feature follows the same structure:

#### Example: Authentication Feature

**Domain Layer:**
```dart
// Entity
class UserEntity extends Equatable { ... }

// Repository Interface
abstract class AuthRepository {
  Future<Either<Failure, UserEntity>> login(...);
}

// Use Case
class LoginUseCase implements UseCase<UserEntity, LoginParams> {
  Future<Either<Failure, UserEntity>> call(LoginParams params) { ... }
}
```

**Data Layer:**
```dart
// Model (DTO)
@JsonSerializable()
class UserModel extends UserEntity { ... }

// Data Source
abstract class AuthRemoteDataSource {
  Future<AuthResponseModel> login(...);
}

// Repository Implementation
class AuthRepositoryImpl implements AuthRepository {
  // Implements domain repository
  // Handles network checks, error conversion
}
```

**Presentation Layer:**
```dart
// Provider
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(...);

// Page
class LoginPage extends ConsumerStatefulWidget { ... }
```

## 🎯 Best Practices

### 1. **Separation of Concerns**
- Each layer has a single responsibility
- Domain layer is independent of frameworks
- Data layer handles external dependencies

### 2. **Dependency Rule**
- Dependencies point inward (toward domain)
- Domain layer has no dependencies on outer layers
- Use dependency inversion (interfaces)

### 3. **Error Handling**
- Use `Either<Failure, Success>` for operations that can fail
- Convert exceptions to failures at repository level
- Handle errors at presentation layer

### 4. **State Management**
- Use Riverpod providers for state
- Keep business logic in use cases
- UI only handles presentation logic

### 5. **Testing**
- Domain layer: Unit tests (no mocking needed)
- Data layer: Mock data sources
- Presentation layer: Widget tests with mocked providers

## 📱 Features Included

### Authentication Feature
- ✅ Login functionality
- ✅ Register functionality (structure ready)
- ✅ Token management (SharedPreferences)
- ✅ Error handling with user feedback
- ✅ Form validation
- ✅ Loading states

## 🔐 API Configuration

Update API endpoints in `lib/core/constants/api_constants.dart`:

```dart
class ApiConstants {
  static const String baseUrl = 'https://your-api.com';
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  // Add more endpoints...
}
```

## 🎨 Theming

Customize themes in `lib/config/theme/app_theme.dart`:
- Light theme
- Dark theme
- Material 3 design

## 🛣️ Routing

Routes are configured in `lib/config/routes/app_router.dart` using **GoRouter**:

```dart
static final GoRouter router = GoRouter(
  initialLocation: login,
  routes: [
    GoRoute(path: login, builder: (context, state) => const LoginPage()),
    GoRoute(path: home, builder: (context, state) => const HomePage()),
  ],
);
```

## 📚 Adding New Features

### Step 1: Create Feature Structure
```bash
mkdir -p lib/features/your_feature/{data/{datasources,models,repositories},domain/{entities,repositories,usecases},presentation/{pages,providers,widgets}}
```

### Step 2: Domain Layer
1. Create entity in `domain/entities/`
2. Create repository interface in `domain/repositories/`
3. Create use cases in `domain/usecases/`

### Step 3: Data Layer
1. Create model in `data/models/` (extends entity)
2. Create data source in `data/datasources/`
3. Implement repository in `data/repositories/`

### Step 4: Presentation Layer
1. Create provider in `presentation/providers/`
2. Create page in `presentation/pages/`
3. Create widgets in `presentation/widgets/`

### Step 5: Register Dependencies
Add to `lib/core/di/injection.dart`:
```dart
// Data sources
getIt.registerLazySingleton<YourDataSource>(...);

// Repositories
getIt.registerLazySingleton<YourRepository>(...);

// Use cases
getIt.registerLazySingleton(() => YourUseCase(...));
```

## 🧪 Testing

```bash
# Run all tests
flutter test

# Run with coverage
flutter test --coverage
```

## 📄 License

This project is open source and available under the MIT License.

## 🤝 Contributing

Contributions are welcome! Please follow the existing architecture patterns.

## 📞 Support

For issues and questions, please create an issue in the repository.

---

**Built with ❤️ using Flutter Clean Architecture**
