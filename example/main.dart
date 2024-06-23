import 'package:flutter/material.dart';

import 'package:component_state_system/component_state_system.dart';

void main() {
  runApp(
    MaterialApp(
      builder: (context, child) => AppStateProvider(
        onInit: (app) {
          // run a system on initialization of the state
          app.runSystem(
            TestInitAppStateSystem(),
          );
        },
        child: ConsumeComponents(
          strict: false,
          // consume the that has been intialized by TestInitAppStateSystem
          types: const [TestLoadingData],
          builder: (context, components) {
            final data = components.tryRead<TestLoadingData>();
            // tryRead returns null if the component is not found
            if (data == null) return const CircularProgressIndicator();

            final listenable = data.storeValue;
            return ListenableBuilder(
              listenable: listenable,
              builder: (_, __) => Text(
                'data ${listenable.value}',
              ),
            );
          },
        ),
      ),
    ),
  );
}

class TestInitAppStateSystem extends BaseSystem {
  @override
  List<Type> get props => [];

  @override
  Future<void> run(Components components) async {
    controller.addComponent(TestLoadingData());

    // modify components by using modify method of the controller
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
