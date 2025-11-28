import 'package:void_signals/void_signals.dart';

void main() async {
  final counter = signal(1);
  var computeCount = 0;

  final doubled = asyncComputed(() async {
    final value = counter(); // Read signal BEFORE await
    computeCount++;
    print('Computing with counter=$value, computeCount=$computeCount');
    await Future.delayed(const Duration(milliseconds: 10));
    return value * 2;
  });

  print('Initial state: ${doubled()}');
  print('Waiting for initial computation...');

  final result1 = await doubled.future;
  print('Result 1: $result1, computeCount=$computeCount');
  print('State after first await: ${doubled()}');

  // Change dependency
  print('Changing counter to 5...');
  counter.value = 5;

  // Give time for effect to retrigger
  await Future.delayed(const Duration(milliseconds: 50));

  print('State after delay: ${doubled()}');
  print('computeCount after delay: $computeCount');

  // Try to get the future
  try {
    final result2 = await doubled.future;
    print('Result 2: $result2');
  } catch (e) {
    print('Error: $e');
  }

  doubled.dispose();
}
