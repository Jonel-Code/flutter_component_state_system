# Component State System
A basic Flutter State Management inspired by Entity Component System (ECS) pattern. This Uses the App as the "Entity" containing "Components" that are being Mananged by running a "System".

## Features

A basic management that uses Flutter's InheritedWidget and ValueNotifier to manage state.

## Usage

AppStateProvider - Used to mount the `ComponentStateSystem` instance to the widget tree.
ConsumeComponents - Used to consume a list of `Component` instances available in the `ComponentStateSystem`.


```dart
AppStateProvider(
    onInit: (app) {
        // run a system on initialization of the state
        app.runSystem(
            TestInitAppStateSystem(),
        );
    },
    child: ConsumeComponents(
        strict: false,
        /// consume the that has been intialized by TestInitAppStateSystem
        types: const [TestLoadingData],
        builder: (context, components) {
            final data = components.tryRead<TestLoadingData>();
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
)

```

## Additional information

This package is still in Proof of Concept stage and is not recommended for production use.
Contributions are welcome.
