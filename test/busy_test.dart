import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:towerdeck/data/providers.dart';

void main() {
  test('a busy key cannot start twice until it finishes', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final busy = container.read(busyProvider.notifier);

    expect(busy.tryStart(containerBusyKey('a')), isTrue);
    expect(busy.tryStart(containerBusyKey('a')), isFalse);
    expect(busy.tryStart(containerBusyKey('b')), isTrue);
    busy.finish(containerBusyKey('a'));
    expect(busy.tryStart(containerBusyKey('a')), isTrue);
  });

  test('update-all marks every container busy', () {
    expect(isContainerBusy({updateAllBusyKey}, 'x'), isTrue);
    expect(isContainerBusy({containerBusyKey('y')}, 'x'), isFalse);
  });
}
