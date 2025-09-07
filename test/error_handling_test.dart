import 'package:flutter_test/flutter_test.dart';
import 'package:settle_up/models/app_error.dart';
import 'package:settle_up/utils/form_validators.dart';
import 'package:settle_up/utils/retry_mechanism.dart';
import 'package:settle_up/utils/loading_state.dart';

void main() {
  group('Error Handling Tests', () {
    group('AppError', () {
      test('should create network error correctly', () {
        final error = NetworkError.noConnection();

        expect(error.type, ErrorType.network);
        expect(error.isRetryable, true);
        expect(error.displayMessage, contains('internet connection'));
      });

      test('should create validation error correctly', () {
        final error = ValidationError.required('email');

        expect(error.type, ErrorType.validation);
        expect(error.severity, ErrorSeverity.low);
        expect(error.fieldErrors, isNotNull);
        expect(error.fieldErrors!['email'], contains('This field is required'));
      });

      test('should create authentication error correctly', () {
        final error = AuthenticationError.notSignedIn();

        expect(error.type, ErrorType.authentication);
        expect(error.severity, ErrorSeverity.high);
        expect(error.displayMessage, contains('sign in'));
      });
    });

    group('FormValidators', () {
      test('should validate required fields', () {
        expect(FormValidators.required(null, 'name'), isA<ValidationError>());
        expect(FormValidators.required('', 'name'), isA<ValidationError>());
        expect(FormValidators.required('  ', 'name'), isA<ValidationError>());
        expect(FormValidators.required('valid', 'name'), isNull);
      });

      test('should validate email format', () {
        expect(FormValidators.email('invalid'), isA<ValidationError>());
        expect(FormValidators.email('test@'), isA<ValidationError>());
        expect(FormValidators.email('test@example.com'), isNull);
        expect(FormValidators.email('user+tag@domain.co.uk'), isNull);
      });

      test('should validate positive numbers', () {
        expect(
          FormValidators.positiveNumber('-1', 'amount'),
          isA<ValidationError>(),
        );
        expect(
          FormValidators.positiveNumber('0', 'amount'),
          isA<ValidationError>(),
        );
        expect(
          FormValidators.positiveNumber('abc', 'amount'),
          isA<ValidationError>(),
        );
        expect(FormValidators.positiveNumber('10.50', 'amount'), isNull);
      });

      test('should validate currency format', () {
        expect(
          FormValidators.currency('10.123', 'amount'),
          isA<ValidationError>(),
        );
        expect(
          FormValidators.currency('-5.00', 'amount'),
          isA<ValidationError>(),
        );
        expect(FormValidators.currency('10.50', 'amount'), isNull);
        expect(FormValidators.currency('100', 'amount'), isNull);
      });

      test('should validate percentage sum', () {
        final validPercentages = {'user1': 50.0, 'user2': 50.0};
        final invalidPercentages = {'user1': 60.0, 'user2': 50.0};

        expect(FormValidators.percentageSum(validPercentages, 'split'), isNull);
        expect(
          FormValidators.percentageSum(invalidPercentages, 'split'),
          isA<ValidationError>(),
        );
      });
    });

    group('LoadingState', () {
      test('should create different states correctly', () {
        const idle = LoadingState<String>.idle();
        const loading = LoadingState<String>.loading('Loading...');
        const success = LoadingState<String>.success('data');
        final error = LoadingState<String>.error(NetworkError.noConnection());

        expect(idle.isIdle, true);
        expect(loading.isLoading, true);
        expect(success.isSuccess, true);
        expect(success.data, 'data');
        expect(error.isError, true);
        expect(error.error, isA<NetworkError>());
      });

      test('should transform data correctly', () {
        const state = LoadingState<String>.success('hello');
        final transformed = state.map<int>((data) => data.length);

        expect(transformed.isSuccess, true);
        expect(transformed.data, 5);
      });

      test('should handle transformation errors', () {
        const state = LoadingState<String>.success('hello');
        final transformed = state.map<int>(
          (data) => throw Exception('Transform error'),
        );

        expect(transformed.isError, true);
        expect(transformed.error, isA<UnknownError>());
      });
    });

    group('RetryMechanism', () {
      test('should retry on retryable errors', () async {
        int attempts = 0;

        try {
          await RetryMechanism.execute(
            () async {
              attempts++;
              if (attempts < 3) {
                throw NetworkError.timeout();
              }
              return 'success';
            },
            config: const RetryConfig(
              maxAttempts: 3,
              initialDelay: Duration(milliseconds: 1),
            ),
          );
        } catch (e) {
          // Should not reach here
          fail('Should have succeeded after retries');
        }

        expect(attempts, 3);
      });

      test('should not retry on non-retryable errors', () async {
        int attempts = 0;

        try {
          await RetryMechanism.execute(
            () async {
              attempts++;
              throw ValidationError.required('field');
            },
            config: const RetryConfig(
              maxAttempts: 3,
              initialDelay: Duration(milliseconds: 1),
            ),
          );
          fail('Should have thrown error');
        } catch (e) {
          expect(e, isA<ValidationError>());
        }

        expect(attempts, 1); // Should not retry validation errors
      });

      test('should respect max attempts', () async {
        int attempts = 0;

        try {
          await RetryMechanism.execute(
            () async {
              attempts++;
              throw NetworkError.timeout();
            },
            config: const RetryConfig(
              maxAttempts: 2,
              initialDelay: Duration(milliseconds: 1),
            ),
          );
          fail('Should have thrown error');
        } catch (e) {
          expect(e, isA<NetworkError>());
        }

        expect(attempts, 2);
      });
    });

    group('CircuitBreaker', () {
      test('should open after failure threshold', () async {
        final circuitBreaker = CircuitBreaker(
          name: 'test',
          failureThreshold: 2,
          timeout: const Duration(milliseconds: 100),
        );

        // First failure
        try {
          await circuitBreaker.execute(() async {
            throw Exception('Test error');
          });
        } catch (e) {
          // Expected
        }

        expect(circuitBreaker.state, CircuitBreakerState.closed);

        // Second failure - should open circuit
        try {
          await circuitBreaker.execute(() async {
            throw Exception('Test error');
          });
        } catch (e) {
          // Expected
        }

        expect(circuitBreaker.state, CircuitBreakerState.open);

        // Third call should fail immediately
        try {
          await circuitBreaker.execute(() async {
            return 'success';
          });
          fail('Should have thrown circuit breaker error');
        } catch (e) {
          expect(e, isA<NetworkError>());
          expect(e.toString(), contains('Circuit breaker is open'));
        }
      });

      test('should reset after timeout', () async {
        final circuitBreaker = CircuitBreaker(
          name: 'test',
          failureThreshold: 1,
          timeout: const Duration(milliseconds: 1),
          resetTimeout: const Duration(milliseconds: 1),
        );

        // Cause failure to open circuit
        try {
          await circuitBreaker.execute(() async {
            throw Exception('Test error');
          });
        } catch (e) {
          // Expected
        }

        expect(circuitBreaker.state, CircuitBreakerState.open);

        // Wait for reset timeout
        await Future.delayed(const Duration(milliseconds: 2));

        // Should be able to execute again
        final result = await circuitBreaker.execute(() async {
          return 'success';
        });

        expect(result, 'success');
        expect(circuitBreaker.state, CircuitBreakerState.closed);
      });
    });
  });
}
