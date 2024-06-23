part of 'component_state_system.dart';

abstract class BaseComponentState {
  void dispose() {}
}

/// a mixin that provides a [ValueNotifier] for error handling
mixin class FailingComponentState {
  final ValueNotifier<String?> error = ValueNotifier<String?>(null);
}

/// a mixin that provides a [ValueNotifier] for loading state
mixin class LoadingComponentState {
  final ValueNotifier<bool?> isLoading = ValueNotifier<bool>(false);
}
