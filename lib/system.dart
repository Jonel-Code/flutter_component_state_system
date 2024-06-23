part of 'component_state_system.dart';

class SystemController {
  ComponentStateSystem? _stateComponentSystem;

  SystemController();

  void attach(ComponentStateSystem stateComponentSystem) {
    _stateComponentSystem = stateComponentSystem;
  }

  void detach() {
    _stateComponentSystem = null;
  }

  bool get isAttached => _stateComponentSystem != null;

  Components get components => _stateComponentSystem!.components;

  /// adds a component to the state. If the component already exists, it will be replaced.
  ///
  /// set [defer] to true if you want to delay the commit of the changes
  void addComponent(BaseComponentState component, {bool defer = false}) {
    _stateComponentSystem?.components.addComponent(component, repalce: true);
    if (!defer) {
      commitChanges();
    }
  }

  /// removes a component from the state. This also runs the [BaseComponentState.dispose] method of the component.
  void removeComponent(Type baseComponentStateType) {
    final target =
        _stateComponentSystem?.components.find(baseComponentStateType);
    if (target != null) {
      target.dispose();
      _stateComponentSystem!.components.remove(target);
    }
  }

  /// commits the changes of the components to the state by updating the signature
  void commitChanges() {
    if (!isAttached) return;

    final signature = _stateComponentSystem!.signature.value;
    final hashes = _stateComponentSystem!.components.hashCodes;
    if (signature != hashes) {
      _stateComponentSystem!.signature.value = hashes;
    }
  }

  /// A method that helps to modify a component in the state.
  /// This method is recomended to use when you want to modify a component in the state,
  /// since it ensures that the system is still attached to the state.
  ///
  /// Queries the state for a component of type [T] and runs the [modifier] function on it
  void modify<T extends BaseComponentState>(
    void Function(T component) modifier,
  ) {
    if (!isAttached) return;

    final target = _stateComponentSystem!.components.tryRead<T>();
    if (target != null) modifier(target);
  }
}

abstract class BaseSystem {
  /// List of [Types] to query from the [ComponentStateSystem.components]
  List<Type> get props;

  /// flag to identify if the system should be queued
  bool get shouldQueue => _shouldQueue;
  bool _shouldQueue = false;

  /// flag to identify if the system should be unique and all of the previous instances should be removed
  bool get shouldBeUnique => _shouldBeUnique;
  bool _shouldBeUnique = false;

  /// flag to identify if the system should not throw an error when [cancel] is called
  bool get isCancelQuiet => _isCancelQuiet;
  bool _isCancelQuiet = false;

  /// store the [StackTrace] of the system where it was instantiated for debugging purposes
  final StackTrace stackTrace = StackTrace.current;

  /// a completer to handle the system process
  Completer? _completer;

  /// flag to identify of the system should run if all [props] are found
  ///
  /// set to false if [run] method should be executed even if not all component types in [props] are found
  bool get strictQuery => false;

  /// the controller to modify the components used in the system
  @protected
  final SystemController controller = SystemController();

  /// the system method to run
  Future<void> run(Components components);

  /// will run when the system [run] method throws an error
  void onError(dynamic e) {}

  /// flag the system to be included in the QUEUE
  void queue() => _shouldQueue = true;

  /// flag the system to be UNIQUE
  void unique() => _shouldBeUnique = true;

  /// flag the system to avoid throwing an error when [cancel] is called
  void quiet() => _isCancelQuiet = true;

  @mustCallSuper
  void cancel() {
    controller.detach();
    if (_completer?.isCompleted == false) {
      /// use only the [Completer.complete] to avoid triggering the [onError] method
      if (isCancelQuiet) {
        _completer!.complete();
        return;
      }
      _completer!.completeError('Cancelled: $runtimeType', stackTrace);
    }
  }

  Future<void> process(Components components) async {
    _completer = Completer();
    run(components).then((_) {
      if (_completer?.isCompleted == false) {
        _completer!.complete();
      }
    }).catchError((e, stackTrace) {
      if (_completer?.isCompleted == false) {
        _completer!.completeError(e, stackTrace);
      }
    });
    return await _completer!.future;
  }
}
