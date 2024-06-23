import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:component_state_system/component_state_system.dart';

void main() {
  test('state system loaded', () async {
    final system = ComponentStateSystem();
    expect(system, isNotNull);

    system.runSystem(TestInitAppStateSystem());

    await Future.delayed(const Duration(seconds: 3));

    final testComponent = system.components.read<TestLoadingData>();
    expect(testComponent, isNotNull);
    expect(testComponent.isLoading.value, false);
    expect(testComponent.storeValue.value, 1);
  });
}

class TestInitAppStateSystem extends BaseSystem {
  @override
  List<Type> get props => [];

  @override
  Future<void> run(Components components) async {
    controller.addComponent(TestLoadingData());

    controller.modify((component) {
      controller.components.read<TestLoadingData>().isLoading.value = true;
    });

    await Future.delayed(const Duration(seconds: 1));

    controller.modify((component) {
      final target = controller.components.read<TestLoadingData>();
      target.isLoading.value = false;
      target.storeValue.value = 1;
    });
  }
}

class TestLoadingData extends BaseComponentState with LoadingComponentState {
  final ValueNotifier<int?> storeValue = ValueNotifier<int?>(null);
}
