library component_state_system;

import 'dart:async';
import 'package:flutter/widgets.dart';

part 'component_state.dart';
part 'system.dart';
part 'utils.dart';

typedef Components = List<BaseComponentState>;

class ComponentStateSystem with QueueHandler<BaseSystem> {
  ComponentStateSystem();

  final Components components = [];
  final Map<int, BaseSystem> processingSystems = {};
  late final ValueNotifier<int> signature =
      ValueNotifier<int>(components.hashCodes);

  factory ComponentStateSystem.withInitial(Components initial) {
    final result = ComponentStateSystem();
    result.components.addAll(initial);
    result.signature.value = result.components.hashCodes;
    return result;
  }

  void runSystem(BaseSystem system) {
    if (system.shouldBeUnique) {
      purgeSystemOfType(system.runtimeType);
    }

    if (!system.shouldQueue) {
      handleQueue(system);
      return;
    }

    queue.add(system);
    startQueue();
  }

  /// finds all of the components that match the [type] and removes/cancel them from the [queue]/[processingSystems].
  void purgeSystemOfType(Type type) {
    for (final system in queue) {
      if (system.runtimeType == type) {
        queue.remove(system);
        return;
      }
    }

    for (final entry in processingSystems.entries) {
      final cancelable = entry.value;
      if (cancelable.runtimeType == type) {
        cancelable.cancel();
      }
    }
  }

  @override
  Future<void> handleQueue(BaseSystem entry) async {
    try {
      entry.controller.attach(this);
      final sysComponents =
          components.findAll(entry.props, strict: entry.strictQuery);
      processingSystems[entry.hashCode] = entry;
      // TODO: add a way to create a backup of the components before running the system
      await entry.process(sysComponents);
    } catch (e) {
      entry.onError(e);
      // TODO: add a way to restore the components from the backup
    } finally {
      entry.controller.commitChanges();
      entry.controller.detach();
      processingSystems.remove(entry.hashCode);
    }
  }
}

class AppStateProvider extends StatelessWidget {
  const AppStateProvider({
    super.key,
    required this.child,
    this.onInit,
    this.initial,
  });

  final Widget child;
  final void Function(ComponentStateSystem)? onInit;
  final Components? initial;

  @override
  Widget build(BuildContext context) {
    final ComponentStateSystem system =
        ComponentStateSystem.withInitial(initial ?? []);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      onInit?.call(system);
    });

    return ListenableBuilder(
      listenable: system.signature,
      builder: (context, builderChild) => AppStateScope(
        appState: system,
        signature: system.signature.value,
        child: builderChild!,
      ),
      child: child,
    );
  }
}

class AppStateScope extends InheritedWidget {
  const AppStateScope({
    required this.appState,
    required this.signature,
    required super.child,
    super.key,
  });

  final ComponentStateSystem appState;
  final int signature;

  /// Get all of the components in the AppState.
  static Components components(BuildContext context) {
    return of(context).appState.components;
  }

  /// Get the AppStateScope of the nearest ancestor [AppStateScope] widget.
  static AppStateScope of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<AppStateScope>()!;
  }

  /// Get the component of type [T] from the AppState.
  static T read<T extends BaseComponentState>(BuildContext context) {
    return of(context).appState.components.read<T>();
  }

  /// Get the component of type [T] from the AppState.
  ///
  /// If the component is not found, return null.
  static T? tryRead<T extends BaseComponentState>(BuildContext context) {
    return of(context).appState.components.tryRead<T>();
  }

  static void runSystem(BuildContext context, BaseSystem system) {
    of(context).appState.runSystem(system);
  }

  static void cancelSystem(BuildContext context, Type t) async {
    of(context).appState.purgeSystemOfType(t);
  }

  @override
  bool updateShouldNotify(AppStateScope oldWidget) {
    return signature != oldWidget.signature;
  }
}

extension AppStateScopeExtension on BuildContext {
  ComponentStateSystem get appState => AppStateScope.of(this).appState;

  Components get components => AppStateScope.components(this);

  T read<T extends BaseComponentState>() => AppStateScope.read<T>(this);

  T? tryRead<T extends BaseComponentState>() => AppStateScope.tryRead<T>(this);

  void runSystem(BaseSystem system) => AppStateScope.runSystem(this, system);

  void cancelSystem(Type t) => AppStateScope.cancelSystem(this, t);
}

typedef ConsumerBuilder = Widget Function(
    BuildContext context, Components components);
typedef ConsumerErrorBuilder = Widget Function(
    BuildContext context, dynamic error);

/// A widget that consumes [Components] from the [AppStateScope].
class ConsumeComponents extends StatefulWidget {
  const ConsumeComponents({
    super.key,
    required this.types,
    required this.builder,
    this.onError,
    this.strict = true,
  }) :
        // strict must be false if onError is null
        assert(onError != null || strict == false);

  /// The types of [BaseComponentState] to be consumed.
  final List<Type> types;

  /// The builder will be called to build the widget.
  final ConsumerBuilder builder;

  /// If an error occurs, this builder will be called.
  ///
  /// If [isStrict] is true, the error will be thrown.
  final ConsumerErrorBuilder? onError;

  /// If true, the builder will only be called if all types are found.
  ///
  /// If false, the builder will be called even if not all types are found.
  final bool strict;

  @override
  State<ConsumeComponents> createState() => _ConsumeComponentsState();
}

class _ConsumeComponentsState extends State<ConsumeComponents> {
  /// the cache of the built widget
  Widget child = Container();

  /// the hashCodes of the queried components
  int hashCodes = -1;

  @override
  Widget build(BuildContext context) {
    Components components = [];
    try {
      components = AppStateScope.components(context)
          .findAll(widget.types, strict: widget.strict);

      // rebuild only if components hashCodes changes
      if (hashCodes != components.hashCodes) {
        hashCodes = components.hashCodes;
        child = widget.builder(context, components);
      }
    } catch (e) {
      if (widget.onError != null) {
        child = widget.onError!(context, e);
      } else {
        rethrow;
      }
    }

    return child;
  }
}
