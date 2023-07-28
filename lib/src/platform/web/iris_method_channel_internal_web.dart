import 'dart:async';
import 'package:flutter/foundation.dart' show VoidCallback;
import 'package:flutter/services.dart';
import 'package:iris_method_channel/iris_method_channel.dart';
import 'package:iris_method_channel/src/platform/web/iris_event_web.dart';

// ignore_for_file: public_member_api_docs

class InitilizationResultWeb implements InitilizationResult {
  InitilizationResultWeb();
}

class IrisMethodChannelInternalWeb implements IrisMethodChannelInternal {
  IrisMethodChannelInternalWeb(this._nativeBindingsProvider);

  final PlatformBindingsProvider _nativeBindingsProvider;
  IrisEventWeb? _irisEventWeb;
  IrisApiEngineHandle? _irisApiEngine;
  PlatformBindingsDelegateInterface? _platformBindingsDelegate;

  @override
  VoidCallback addHotRestartListener(HotRestartListener listener) {
    return () {};
  }

  @override
  Future<void> dispose() async {
    assert(_irisApiEngine != null);

    _irisEventWeb?.dispose();
    _irisEventWeb = null;

    _platformBindingsDelegate?.destroyNativeApiEngine(_irisApiEngine!);
    _platformBindingsDelegate = null;
    _irisApiEngine = null;
  }

  @override
  Future<CallApiResult> execute(Request request) async {
    if (request is CreateNativeEventHandlerRequest) {
      print('CreateNativeEventHandlerRequest not implement yet.');
      return CallApiResult(irisReturnCode: 0, data: {'observerIntPtr': 0});
    } else if (request is ApiCallRequest) {
      final IrisMethodCall methodCall = request.methodCall;
      return _executeMethodCall(methodCall);
    } else {
      print('${request} not implement yet.');
      return CallApiResult(irisReturnCode: 0, data: {'result': 0});
    }
  }

  Future<CallApiResult> _executeMethodCall(IrisMethodCall methodCall) async {
    // On web, we do not create a `IrisApiParamHandle` directly, but pass the `methodCall`
    // to the `callApiAsync` implementation to create their platform specific parameters
    // instead.
    final ret = await _platformBindingsDelegate!
        .callApiAsync(methodCall, _irisApiEngine!, const IrisApiParamHandle(0));

    print('_executeMethodCall web ${ret.irisReturnCode}, ${ret.data}');

    return ret;
  }

  @override
  int getApiEngineHandle() {
    return 0;
  }

  @override
  Future<InitilizationResult?> initilize(List<int> args) async {
    _platformBindingsDelegate =
        _nativeBindingsProvider.provideNativeBindingDelegate();
    final createApiEngineResult =
        _platformBindingsDelegate!.createApiEngine(args);
    _irisApiEngine = createApiEngineResult.apiEnginePtr;

    final irisEvent = _nativeBindingsProvider.provideIrisEvent() ??
        IrisEventWeb(_irisApiEngine!);
    _irisEventWeb = irisEvent as IrisEventWeb;
    _irisEventWeb!.initialize();

    return InitilizationResultWeb();
  }

  @override
  Future<List<CallApiResult>> listExecute(Request request) async {
    final results = <CallApiResult>[];
    if (request is ApiCallListRequest) {
      final methodCalls = request.methodCalls;
      for (final methodCall in methodCalls) {
        final result = await _executeMethodCall(methodCall);
        results.add(result);
      }
    } else if (request is DestroyNativeEventHandlerListRequest) {
      print('[listExecute] Not implemented request: $request');
    }

    return results;
  }

  @override
  void removeHotRestartListener(HotRestartListener listener) {}

  @override
  void setIrisEventMessageListener(IrisEventMessageListener listener) {
    _irisEventWeb!.setIrisEventMessageListener(listener);
  }
}
