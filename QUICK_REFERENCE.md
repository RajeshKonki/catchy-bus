# Quick Reference Guide

## Common Commands

### Development
```bash
# Get dependencies
flutter pub get

# Run code generation
dart run build_runner build --delete-conflicting-outputs

# Watch mode (auto-regenerate)
dart run build_runner watch --delete-conflicting-outputs

# Run the app
flutter run

# Run on specific device
flutter run -d chrome
flutter run -d macos
flutter run -d ios

# Hot reload: Press 'r' in terminal
# Hot restart: Press 'R' in terminal
```

### Code Quality
```bash
# Analyze code
flutter analyze

# Format code
dart format lib/

# Run tests
flutter test

# Run tests with coverage
flutter test --coverage

# Check outdated packages
flutter pub outdated
```

### Build
```bash
# Build APK (Android)
flutter build apk

# Build App Bundle (Android)
flutter build appbundle

# Build iOS
flutter build ios

# Build Web
flutter build web

# Build macOS
flutter build macos
```

## Code Snippets

### Creating a New Use Case

```dart
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/your_entity.dart';
import '../repositories/your_repository.dart';

class YourUseCase implements UseCase<YourEntity, YourParams> {
  final YourRepository repository;

  YourUseCase(this.repository);

  @override
  Future<Either<Failure, YourEntity>> call(YourParams params) async {
    return await repository.yourMethod(
      param1: params.param1,
      param2: params.param2,
    );
  }
}

class YourParams extends Equatable {
  final String param1;
  final String param2;

  const YourParams({
    required this.param1,
    required this.param2,
  });

  @override
  List<Object?> get props => [param1, param2];
}
```

### Creating a Riverpod Provider

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/di/injection.dart';
import '../../domain/entities/your_entity.dart';
import '../../domain/usecases/your_usecase.dart';

class YourState {
  final bool isLoading;
  final YourEntity? data;
  final String? error;

  YourState({
    this.isLoading = false,
    this.data,
    this.error,
  });

  YourState copyWith({
    bool? isLoading,
    YourEntity? data,
    String? error,
  }) {
    return YourState(
      isLoading: isLoading ?? this.isLoading,
      data: data ?? this.data,
      error: error,
    );
  }
}

class YourNotifier extends StateNotifier<YourState> {
  final YourUseCase yourUseCase;

  YourNotifier(this.yourUseCase) : super(YourState());

  Future<void> performAction(String param1, String param2) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await yourUseCase(
      YourParams(param1: param1, param2: param2),
    );

    result.fold(
      (failure) {
        state = state.copyWith(
          isLoading: false,
          error: failure.message,
        );
      },
      (data) {
        state = state.copyWith(
          isLoading: false,
          data: data,
          error: null,
        );
      },
    );
  }
}

final yourProvider = StateNotifierProvider<YourNotifier, YourState>((ref) {
  return YourNotifier(getIt<YourUseCase>());
});
```

### Creating a Model with JSON Serialization

```dart
import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/your_entity.dart';

part 'your_model.g.dart';

@JsonSerializable()
class YourModel extends YourEntity {
  const YourModel({
    required super.id,
    required super.name,
    super.description,
  });

  factory YourModel.fromJson(Map<String, dynamic> json) =>
      _$YourModelFromJson(json);

  Map<String, dynamic> toJson() => _$YourModelToJson(this);

  YourEntity toEntity() {
    return YourEntity(
      id: id,
      name: name,
      description: description,
    );
  }

  factory YourModel.fromEntity(YourEntity entity) {
    return YourModel(
      id: entity.id,
      name: entity.name,
      description: entity.description,
    );
  }
}
```

### Consuming Provider in Widget

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/your_provider.dart';

class YourPage extends ConsumerWidget {
  const YourPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(yourProvider);

    // Listen to state changes
    ref.listen<YourState>(yourProvider, (previous, next) {
      if (next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.error!)),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Your Page')),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.data != null
              ? YourDataWidget(data: state.data!)
              : const Center(child: Text('No data')),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ref.read(yourProvider.notifier).performAction('param1', 'param2');
        },
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
```

## Dependency Injection Setup

### Register in injection.dart

```dart
// Data sources
getIt.registerLazySingleton<YourRemoteDataSource>(
  () => YourRemoteDataSourceImpl(getIt<DioClient>()),
);

// Repositories
getIt.registerLazySingleton<YourRepository>(
  () => YourRepositoryImpl(
    remoteDataSource: getIt<YourRemoteDataSource>(),
    networkInfo: getIt<NetworkInfo>(),
  ),
);

// Use cases
getIt.registerLazySingleton(() => YourUseCase(getIt<YourRepository>()));
```

## Using CatchyBus Brand Colors

```dart
import 'package:flutter/material.dart';
import '../../config/theme/app_theme.dart';

// In your widget
Container(
  color: AppColors.primaryYellow,  // #F9C300
  child: Text(
    'CatchyBus',
    style: TextStyle(color: AppColors.deepBlue),  // #1E4FA3
  ),
)

// Using theme colors
Container(
  color: Theme.of(context).colorScheme.primary,  // Primary Yellow
  child: Text(
    'Button',
    style: TextStyle(
      color: Theme.of(context).colorScheme.onPrimary,  // Dark Charcoal
    ),
  ),
)

// Buttons automatically use Bright Orange (#F57C00)
ElevatedButton(
  onPressed: () {},
  child: const Text('Click Me'),
)

// Error/Alert color (Location Red #E53935)
Icon(Icons.error, color: Theme.of(context).colorScheme.error)
```

## Error Handling Pattern

```dart
// In Repository
try {
  final result = await remoteDataSource.getData();
  return Right(result.toEntity());
} on ServerException catch (e) {
  return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
} on NetworkException catch (e) {
  return Left(NetworkFailure(message: e.message));
} catch (e) {
  return Left(UnknownFailure(message: e.toString()));
}

// In Presentation
result.fold(
  (failure) {
    // Handle error
    showSnackBar(failure.message);
  },
  (data) {
    // Handle success
    updateUI(data);
  },
);
```

## Routing

```dart
// Navigate to a route
context.go('/home');
context.push('/details');

// Navigate with parameters
context.go('/user/123');

// Go back
context.pop();

// Replace current route
context.replace('/login');
```

## Form Validation Example

```dart
TextFormField(
  controller: _controller,
  decoration: const InputDecoration(
    labelText: 'Email',
    prefixIcon: Icon(Icons.email),
  ),
  validator: (value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your email';
    }
    if (!value.contains('@')) {
      return 'Please enter a valid email';
    }
    return null;
  },
)
```

## Useful VS Code Snippets

Add to `.vscode/snippets.code-snippets`:

```json
{
  "Flutter UseCase": {
    "prefix": "fusecase",
    "body": [
      "class ${1:Name}UseCase implements UseCase<${2:ReturnType}, ${3:Params}> {",
      "  final ${4:Repository} repository;",
      "",
      "  ${1:Name}UseCase(this.repository);",
      "",
      "  @override",
      "  Future<Either<Failure, ${2:ReturnType}>> call(${3:Params} params) async {",
      "    return await repository.${5:method}();",
      "  }",
      "}"
    ]
  }
}
```

## Troubleshooting

### Build Runner Issues
```bash
# Clean and rebuild
flutter clean
flutter pub get
dart run build_runner clean
dart run build_runner build --delete-conflicting-outputs
```

### Import Issues
```bash
# Organize imports
dart fix --apply
```

### Platform-Specific Issues
```bash
# iOS
cd ios && pod install && cd ..

# Android
flutter clean
cd android && ./gradlew clean && cd ..
```

## Resources

- [Flutter Documentation](https://docs.flutter.dev/)
- [Riverpod Documentation](https://riverpod.dev/)
- [Clean Architecture](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)
- [Dartz Package](https://pub.dev/packages/dartz)
- [GetIt Package](https://pub.dev/packages/get_it)
