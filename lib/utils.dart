part of 'component_state_system.dart';

extension ReadComponents on Components {
  /// a helper method to query a component of type [T] from the [Components].
  ///
  /// (same as [tryRead] but throws an exception if the component is not found.)
  ///
  /// NOTE: use this method if you need type inference.
  T read<T extends BaseComponentState>() {
    final result = tryRead<T>();
    if (result == null) {
      throw ComponentNotFoundException(T);
    }
    return result;
  }

  /// a helper method to query a component of type [T] from the [Components].
  ///
  /// if the component is not found, return null.
  ///
  /// NOTE: use this method if you need type inference.
  T? tryRead<T extends BaseComponentState>() {
    final index = indexWhere((component) => component is T);
    if (index == -1) {
      return null;
    }
    return this[index] as T;
  }

  /// a helper method to check if the [Components] has a component of type [T].
  bool has<T extends BaseComponentState>() {
    return indexWhere((component) => component is T) >= 0;
  }

  /// a helper method to query the given [baseComponentStateType] parameter from the [Components].
  ///
  /// NOTE: this does not provide type inference, but ideal to use when the type is unknown.
  BaseComponentState? find(Type baseComponentStateType) {
    final index = lastIndexWhere(
      (component) => component.runtimeType == baseComponentStateType,
    );
    if (index == -1) {
      return null;
    }
    return this[index];
  }

  /// a helper method to add a component to the [Components].
  ///
  /// if the component already exists, it will be replaced.
  ///
  /// if [repalce] is set to false, an exception will be thrown if the component already exists.
  void addComponent(BaseComponentState component, {bool repalce = false}) {
    final index = indexWhere((c) => c.runtimeType == component.runtimeType);
    if (index != -1 && !repalce) {
      throw DuplicateComponentAddException(component.runtimeType);
    }

    if (index != -1) {
      this[index] = component;
    } else {
      add(component);
    }
  }

  /// a helper method tha finds all Component of given [Type] list
  ///
  /// if strict is set to false, the method will continue even if not all components are found.
  ///
  /// if strict is set to true, an [MissingComponentsQueryException] will be thrown if not all components are found.
  ///
  /// [strict] defaults to [true]
  ///
  /// returns an unmodifiable list of the result
  Components findAll(List<Type> types, {bool strict = true}) {
    final result = <BaseComponentState>[];

    for (final entry in types) {
      final component = find(entry);
      if (component != null) {
        result.addComponent(component, repalce: true);
      }
    }

    if (strict && result.length != types.length) {
      final missing = <Type>[];
      for (final type in types) {
        final checkIndex = result.indexWhere((c) => c.runtimeType == type);

        if (checkIndex == -1) {
          missing.add(type);
        }
      }
      throw MissingComponentsQueryException(missing);
    }

    return Components.unmodifiable(result);
  }

  int get hashCodes => Object.hashAll(this);
}

/// Exception thrown when adding a component that already exists.
class DuplicateComponentAddException implements Exception {
  DuplicateComponentAddException(this.duplicate);

  final Type duplicate;

  @override
  String toString() {
    return 'Component already exists: $duplicate';
  }
}

/// Exception thrown when a component is not found.
class ComponentNotFoundException implements Exception {
  ComponentNotFoundException(this.missing);

  final Type missing;

  @override
  String toString() {
    return 'Component not found: $missing';
  }
}

/// Exception thrown when a certain list of components are not found.
class MissingComponentsQueryException implements Exception {
  MissingComponentsQueryException(this.missing);

  final List<Type> missing;

  @override
  String toString() {
    return 'Missing components: $missing';
  }
}

abstract mixin class QueueHandler<T> {
  @protected
  final List<T> queue = [];

  @protected
  bool isRunning = false;

  @protected
  Future<void> startQueue() async {
    if (isRunning) return;

    isRunning = true;
    while (queue.isNotEmpty) {
      final system = queue.removeAt(0);
      await handleQueue(system);
    }
    isRunning = false;
  }

  Future<void> handleQueue(T entry);

  void removeTypeOnQueue<U>() {
    queue.removeWhere((element) => element is U);
  }
}
